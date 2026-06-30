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

class ApiClient {
  static ApiClient? _instance;
  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  final String _baseUrl = Env.kUrl;
  String? _kDbName;
  final Dio dio;
  late final Dio _refreshDio;
  final StorageService _storage = StorageService();
  int? _currentIdNetwork;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;
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
    _refreshDio.options.extra['withCredentials'] = true;
    _refreshDio.options.headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Auth-Mode': 'cookie',
    };
  }

  void _setupMainDio() {
    dio.options.validateStatus = (status) => status != null && status < 504;
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
        if (remaining < 60) {
          if (kDebugMode) print('[Auth] Token expire dans ${remaining}s — refresh proactif');
          final refreshed = await _refreshToken();
          if (!refreshed) {
            await _handleSessionExpired();
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message: 'Session expirée',
            ));
          }
        }
      }
    }

    return handler.next(options);
  }

  // Intercepte les 401 → refresh + retry, seulement si le token est expiré ou inconnu.
  // Traque aussi les réponses réussies de auth/token pour mettre à jour _lastRefreshTime.
  Future<void> _onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (_isAuthPath(response.requestOptions.path) && response.statusCode == 200) {
      _lastRefreshTime = DateTime.now();
    }

    if (response.statusCode == 401 &&
        !_isAuthPath(response.requestOptions.path) &&
        response.requestOptions.extra['_isRetry'] != true &&
        await _isTokenExpiredOrUnknown()) {
      if (kDebugMode) print('[Auth] 401 reçu + token expiré/inconnu — tentative de refresh');
      final refreshed = await _refreshToken();
      if (refreshed) {
        response.requestOptions.extra['_isRetry'] = true;
        try {
          final newResponse = await dio.fetch(response.requestOptions);
          return handler.resolve(newResponse);
        } catch (_) {
          await _handleSessionExpired();
          return handler.next(response);
        }
      } else {
        await _handleSessionExpired();
      }
    }
    return handler.next(response);
  }

  // Token expiré = jwt_exp passé, ou inconnu ET aucun refresh récent (< 5 min)
  Future<bool> _isTokenExpiredOrUnknown() async {
    final jwtExpStr = await _storage.readSecureData('jwt_exp');
    if (jwtExpStr != null) {
      final jwtExp = int.tryParse(jwtExpStr);
      if (jwtExp != null) {
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return nowSeconds >= jwtExp;
      }
    }
    // jwt_exp non stocké : on se fie au dernier refresh connu
    if (_lastRefreshTime != null) {
      return DateTime.now().difference(_lastRefreshTime!) >= const Duration(minutes: 1);
    }
    return true;
  }

  bool _isAuthPath(String path) =>
      path.contains('auth/token') || path.contains('auth/login') || path.contains('auth/logout');

  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      return await (_refreshCompleter?.future ?? Future.value(false));
    }

    _isRefreshing = true;
    final completer = Completer<bool>();
    _refreshCompleter = completer;

    bool result = false;
    try {
      final response = await _refreshDio.post('auth/token', data: null);
      result = response.statusCode == 200;
      if (result) {
        _lastRefreshTime = DateTime.now();
        final data = response.data;
        // Sauvegarde jwt_exp si le backend le retourne (nécessite PHP: voir note)
        if (data is Map && data['access_exp'] != null) {
          await _storage.writeSecureData(
            StorageItem('jwt_exp', data['access_exp'].toString()),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('[Auth] Erreur refresh token: $e');
      result = false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
      completer.complete(result);
    }

    return result;
  }

  Future<void> _handleSessionExpired() async {
    if (_isHandlingExpiry) return;
    _isHandlingExpiry = true;

    try {
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
    } finally {
      _isHandlingExpiry = false;
    }
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
