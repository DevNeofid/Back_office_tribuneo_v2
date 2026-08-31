import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/core/notifiers/maintenance_notifier.dart';
import 'package:back_office_tribuneo_v2/env/env.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_model.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';

/// Résultat d'une tentative de refresh :
/// - [success] : nouveau token obtenu
/// - [expired] : le backend a explicitement rejeté le refresh token (401/403),
///   la session est réellement morte
/// - [transient] : erreur passagère (réseau, timeout, 429, 5xx) — la session
///   locale ne doit PAS être détruite
enum _RefreshResult { success, expired, transient }

class ApiClient {
  static ApiClient? _instance;
  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// Aucun timeout = attente infinie. Sur le web, une requête qui reste pendue
  /// (onglet en arrière-plan, sortie de veille, proxy qui coupe sans FIN) gèle
  /// alors définitivement le client : si c'est le refresh qui est pendu, le
  /// verrou [_isRefreshing] n'est jamais relâché et TOUTES les requêtes
  /// suivantes attendent un Completer qui ne se complètera jamais.
  static const Duration _kConnectTimeout = Duration(seconds: 20);
  static const Duration _kReceiveTimeout = Duration(seconds: 120);
  static const Duration _kRefreshConnectTimeout = Duration(seconds: 15);
  static const Duration _kRefreshReceiveTimeout = Duration(seconds: 20);

  /// Filet de sécurité au-dessus des timeouts Dio : garantit que le verrou de
  /// refresh est relâché même si l'adapter navigateur n'honore pas un timeout.
  static const Duration _kRefreshHardTimeout = Duration(seconds: 25);

  final String _baseUrl = Env.kUrl;
  String? _kDbName;
  final Dio dio;
  late final Dio _refreshDio;
  final StorageService _storage = StorageService();
  int? _currentIdNetwork;

  bool _isRefreshing = false;
  Completer<_RefreshResult>? _refreshCompleter;
  bool _isHandlingExpiry = false;
  DateTime? _lastRefreshTime;

  ApiClient._internal() : dio = Dio() {
    _setupRefreshDio();
    _setupMainDio();
  }

  void _setupRefreshDio() {
    _refreshDio = Dio();
    _refreshDio.options.baseUrl = _baseUrl;
    _refreshDio.options.validateStatus = (status) => status != null && status < 504;
    _refreshDio.options.connectTimeout = _kRefreshConnectTimeout;
    _refreshDio.options.receiveTimeout = _kRefreshReceiveTimeout;
    _refreshDio.options.extra['withCredentials'] = true;
    _refreshDio.options.headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Auth-Mode': 'cookie',
    };
  }

  void _setupMainDio() {
    dio.options.validateStatus = (status) => status != null && status < 504;
    dio.options.connectTimeout = _kConnectTimeout;
    dio.options.receiveTimeout = _kReceiveTimeout;
    dio.options.extra['withCredentials'] = true;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: (DioException e, handler) {
        if (kDebugMode) {
          print('Erreur réseau [${e.response?.statusCode}]: ${e.response?.data}');
        }
        return handler.next(e);
      },
    ));
  }

  /// L'API encapsule toute réponse dans `{"data": {...}}` (ActionPayload), donc
  /// `access_exp` se lit à `body['data']['access_exp']`. La forme à plat est
  /// tolérée pour rester robuste à un changement de contrat.
  int? _extractAccessExp(dynamic body) {
    if (body is! Map) return null;
    final flat = body['access_exp'];
    if (flat is num) return flat.toInt();
    final nested = body['data'];
    if (nested is Map && nested['access_exp'] is num) {
      return (nested['access_exp'] as num).toInt();
    }
    return null;
  }

  // Vérifie si jwt_exp est stocké et proche de l'expiration (< 60s) → refresh proactif
  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isAuthPath(options.path) || options.extra['_isRetry'] == true) {
      return handler.next(options);
    }

    final jwtExpStr = await _storage.readSecureData('jwt_exp');
    if (jwtExpStr != null) {
      final jwtExp = int.tryParse(jwtExpStr);
      if (jwtExp != null) {
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final remaining = jwtExp - nowSeconds;
        // Garde-fou : pas de refresh proactif si un refresh a réussi il y a
        // moins d'une minute (évite une tempête de refresh si jwt_exp est périmé).
        final recentlyRefreshed = _lastRefreshTime != null &&
            DateTime.now().difference(_lastRefreshTime!) <
                const Duration(minutes: 1);
        if (remaining < 60 && !recentlyRefreshed) {
          if (kDebugMode) print('[Auth] Token expire dans ${remaining}s — refresh proactif');
          final result = await _refreshToken();
          if (result == _RefreshResult.expired) {
            await _handleSessionExpired();
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message: 'Session expirée',
            ));
          }
          // transient : on laisse partir la requête ; si le token est vraiment
          // mort, le 401 sera géré par _onResponse.
        }
      }
    }

    // Horodate le départ réel de la requête : c'est ce qui permet, sur un 401,
    // de distinguer « partie avec un cookie devenu périmé » (→ refresh + retry)
    // de « partie après un refresh réussi et refusée quand même » (→ 401 légitime).
    options.extra['_issuedAt'] = DateTime.now();

    return handler.next(options);
  }

  /// Intercepte **uniquement** les 401 → refresh + retry.
  ///
  /// Tous les autres statuts (404 de `bto/pending`, 403, 5xx…) traversent
  /// l'intercepteur sans aucun traitement et restent à la charge des
  /// repositories : ne rien ajouter ici pour un statut autre que 401.
  ///
  /// Traque aussi les réponses réussies de auth/token pour mettre à jour
  /// _lastRefreshTime.
  Future<void> _onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (_isAuthPath(response.requestOptions.path) && response.statusCode == 200) {
      _lastRefreshTime = DateTime.now();
    }

    if (response.statusCode != 401 ||
        _isAuthPath(response.requestOptions.path) ||
        response.requestOptions.extra['_isRetry'] == true) {
      return handler.next(response);
    }

    // Un 401 du serveur fait autorité : on ne le conditionne PAS à une
    // heuristique d'horloge côté client (jwt_exp / dernier refresh). C'est ce
    // garde-fou qui faisait perdre silencieusement toutes les requêtes déjà en
    // vol au moment où un refresh concurrent aboutissait → panneaux vides.
    final issuedAt = response.requestOptions.extra['_issuedAt'];
    final refreshedSinceRequest = _lastRefreshTime != null &&
        issuedAt is DateTime &&
        _lastRefreshTime!.isAfter(issuedAt);

    var result = _RefreshResult.success;
    if (!refreshedSinceRequest) {
      // Les appels concurrents sont dédoublonnés par le Completer : une seule
      // rotation de refresh token, même sur une rafale de 401.
      if (kDebugMode) {
        print('[Auth] 401 sur ${response.requestOptions.path} — refresh + retry');
      }
      result = await _refreshToken();
    } else if (kDebugMode) {
      print('[Auth] 401 sur ${response.requestOptions.path} — cookie déjà '
          'renouvelé depuis, retry direct');
    }

    if (result == _RefreshResult.success) {
      final retryOptions = response.requestOptions;
      retryOptions.extra['_isRetry'] = true;
      // Un FormData a déjà été consommé par le premier envoi : sans clone, le
      // rejeu échoue systématiquement (uploads de fichiers).
      final body = retryOptions.data;
      if (body is FormData) {
        retryOptions.data = body.clone();
      }
      try {
        final newResponse = await dio.fetch(retryOptions);
        return handler.resolve(newResponse);
      } catch (_) {
        // Le refresh a réussi, la session est valide : une erreur sur le
        // retry (réseau...) ne doit pas déconnecter. On transmet le 401
        // d'origine à l'appelant.
        return handler.next(response);
      }
    }

    if (result == _RefreshResult.expired) {
      await _handleSessionExpired();
    }
    // transient : on transmet le 401 à l'appelant sans détruire la session.
    return handler.next(response);
  }

  bool _isAuthPath(String path) =>
      path.contains('auth/token') || path.contains('auth/login') || path.contains('auth/logout');

  Future<_RefreshResult> _refreshToken() async {
    if (_isRefreshing) {
      final pending = _refreshCompleter;
      if (pending == null) return _RefreshResult.transient;
      try {
        return await pending.future.timeout(_kRefreshHardTimeout);
      } on TimeoutException {
        // On n'attend pas indéfiniment un refresh bloqué : la requête repart
        // en « transitoire », sans détruire la session locale.
        return _RefreshResult.transient;
      }
    }

    _isRefreshing = true;
    final completer = Completer<_RefreshResult>();
    _refreshCompleter = completer;

    var result = _RefreshResult.transient;
    try {
      final response = await _refreshDio
          .post('auth/token', data: null)
          .timeout(_kRefreshHardTimeout);
      if (response.statusCode == 200) {
        result = _RefreshResult.success;
        _lastRefreshTime = DateTime.now();
        // La session est de nouveau vivante : on relâche le verrou d'expiration.
        _isHandlingExpiry = false;
        final accessExp = _extractAccessExp(response.data);
        if (accessExp != null) {
          await _storage.writeSecureData(
            StorageItem('jwt_exp', accessExp.toString()),
          );
        } else if (kDebugMode) {
          // On ne supprime surtout PAS jwt_exp : sans lui le refresh proactif
          // est désactivé et le client ne peut plus que subir les 401. Le
          // garde-fou `recentlyRefreshed` de _onRequest suffit à éviter une
          // tempête de refresh si jwt_exp devenait périmé.
          print('[Auth] access_exp absent de la réponse auth/token');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Seul un rejet explicite du backend prouve que la session est morte.
        result = _RefreshResult.expired;
      } else {
        // 429, 5xx, maintenance... : erreur passagère, on garde la session.
        if (kDebugMode) {
          print('[Auth] Refresh échoué (HTTP ${response.statusCode}) — transitoire');
        }
        result = _RefreshResult.transient;
      }
    } catch (e) {
      // Erreur réseau/timeout : transitoire, la session locale reste valide.
      if (kDebugMode) print('[Auth] Erreur refresh token: $e');
      result = _RefreshResult.transient;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
      completer.complete(result);
    }

    return result;
  }

  /// Réarme la détection d'expiration après une reconnexion réussie.
  void resetAuthState() {
    _isHandlingExpiry = false;
    _lastRefreshTime = null;
  }

  Future<void> _handleSessionExpired() async {
    // Verrou volontairement latché : sur une rafale de 401, une seule
    // redirection et un seul snackbar. Il est relâché par un refresh réussi
    // ou par resetAuthState() après une reconnexion.
    if (_isHandlingExpiry) return;
    _isHandlingExpiry = true;

    await StorageFunction().clearUser();
    await _storage.deleteSecureDataFromKey('jwt_exp');

    snackbarKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Votre session a expiré, veuillez vous reconnecter'),
        backgroundColor: Color(0xFFE57373),
        duration: Duration(seconds: 5),
      ),
    );

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<Response> checkForMaintenance(Response response) async {
    if (response.statusCode == 503) {
      MaintenanceNotifier.enterMaintenanceMode();
    }
    return response;
  }

  Future<void> _ensureInitialized() async {
    String? tmpIdNetwork = await _storage.readSecureData('user_id_network');
    int? savedIdNetwork = int.tryParse(tmpIdNetwork ?? '');

    if (_kDbName != null && _currentIdNetwork == savedIdNetwork) {
      return;
    }
    await load(savedIdNetwork);
  }

  Future<void> load([int? forcedIdNetwork]) async {
    dio.options.baseUrl = _baseUrl;
    _kDbName = null;
    int? idNetwork = forcedIdNetwork;

    if (idNetwork == null) {
      String? tmpIdNetwork = await _storage.readSecureData('user_id_network');
      idNetwork = int.tryParse(tmpIdNetwork ?? '');
    }

    _currentIdNetwork = idNetwork;

    try {
      String? savedNetworksJson = await _storage.readSecureData('networks');

      if (savedNetworksJson != null && savedNetworksJson.isNotEmpty) {
        List<dynamic> networksList = jsonDecode(savedNetworksJson);

        for (var network in networksList) {
          if (network['id'] == idNetwork) {
            _kDbName = network['db_name']?.toString();
            break;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la lecture dynamique des réseaux : $e');
      }
    }

    Map<String, dynamic> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Auth-Mode': 'cookie',
    };

    if (_kDbName != null) {
      headers['X-Tenant'] = _kDbName;
    }

    dio.options.headers = headers;
  }

  /// Méthode POST standard (envoi de JSON)
  Future<Response> post(
    String suffixeUrl,
    dynamic data, {
    Map<String, dynamic>? queryParams,
    bool? bytesType,
    String? overrideTenant,
  }) async {
    await _ensureInitialized();

    Map<String, dynamic> customHeaders = {};
    if (overrideTenant != null) customHeaders['X-Tenant'] = overrideTenant;

    try {
      final response = await dio.post(
        suffixeUrl,
        data: data,
        queryParameters: queryParams,
        options: Options(
          headers: customHeaders.isNotEmpty ? customHeaders : null,
          responseType:
              bytesType == true ? ResponseType.bytes : ResponseType.json,
        ),
      );
      return checkForMaintenance(response);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la requête POST: $e');
      rethrow;
    }
  }

  /// Méthode POST pour l'envoi de fichiers (multipart/form-data)
  Future<Response> postWithFile(String suffixeUrl, Map<String, dynamic> data,
      {String? overrideTenant}) async {
    Map<String, dynamic> customHeaders = {
      'Content-Type': 'multipart/form-data',
    };
    if (overrideTenant != null) customHeaders['X-Tenant'] = overrideTenant;
    try {
      FormData formData = FormData.fromMap(data);
      Response response = await dio.post(
        suffixeUrl.toString(),
        data: formData,
        options: Options(
          headers: customHeaders,
        ),
      );
      return response;
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Méthode GET
  Future<Response> get(
    String suffixeUrl, {
    Map<String, dynamic>? queryParams,
    int? id,
    bool? bytesType,
    String? overrideTenant,
  }) async {
    await _ensureInitialized();

    String path = id != null ? '$suffixeUrl/$id' : suffixeUrl;

    Map<String, dynamic> customHeaders = {};
    if (overrideTenant != null) customHeaders['X-Tenant'] = overrideTenant;

    try {
      final response = await dio.get(
        path,
        queryParameters: queryParams,
        options: Options(
          headers: customHeaders.isNotEmpty ? customHeaders : null,
          responseType:
              bytesType == true ? ResponseType.bytes : ResponseType.json,
        ),
      );
      return checkForMaintenance(response);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la requête GET: $e');
      rethrow;
    }
  }

  /// Méthode PUT standard (envoi de JSON)
  Future<Response> put(
    String suffixeUrl,
    dynamic data, {
    int? id,
    String? overrideTenant,
  }) async {
    await _ensureInitialized();

    String path = id != null ? '$suffixeUrl/$id' : suffixeUrl;

    Map<String, dynamic> customHeaders = {};
    if (overrideTenant != null) customHeaders['X-Tenant'] = overrideTenant;

    try {
      final response = await dio.put(
        path,
        data: data,
        options: Options(
          headers: customHeaders.isNotEmpty ? customHeaders : null,
        ),
      );
      return checkForMaintenance(response);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la requête PUT: $e');
      rethrow;
    }
  }

  /// Méthode softDelete (PUT)
  Future<Response> softDelete(String suffixeUrl,
      {int? id, String? data}) async {
    await _ensureInitialized();
    final response = await dio.put(
      suffixeUrl,
      data: data,
    );
    return checkForMaintenance(response);
  }

  /// Méthode DELETE
  Future<Response> delete(String suffixeUrl, int? id,
      {String? overrideTenant}) async {
    await _ensureInitialized();

    String path = id != null ? '$suffixeUrl/$id' : suffixeUrl;

    Map<String, dynamic> customHeaders = {};
    if (overrideTenant != null) customHeaders['X-Tenant'] = overrideTenant;

    try {
      final response = await dio.delete(path,
          options: Options(
              headers: customHeaders.isNotEmpty ? customHeaders : null));
      return checkForMaintenance(response);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la requête DELETE: $e');
      rethrow;
    }
  }

  /// Gestion des erreurs Dio
  Exception _handleDioError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.sendTimeout) {
        return Exception('Send Timeout with API Server');
      } else if (error.type == DioExceptionType.receiveTimeout) {
        return Exception('Receive Timeout with API Server');
      } else if (error.type == DioExceptionType.cancel) {
        return Exception('Request to API server was cancelled');
      } else {
        return Exception('Unexpected error occurred');
      }
    } else {
      return Exception('Unexpected error occurred');
    }
  }
}
