import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:back_office_tribuneo_v2/core/notifiers/maintenance_notifier.dart';
import 'package:back_office_tribuneo_v2/env/env.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';

class ApiClient {
  final String _baseUrl = Env.kUrl;
  String? _kDbName;
  final Dio dio;
  final StorageService _storage = StorageService();
  int? _currentIdNetwork;

  ApiClient() : dio = Dio() {
    dio.options.validateStatus = (status) {
      return status != null && status < 504;
    };
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (request, handler) {
        return handler.next(request);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          print(
            'Erreur réseau [${e.response?.statusCode}]: ${e.response?.data}',
          );
        }
        return handler.next(e);
      },
    ));
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
  Future<Response> postWithFile(
      String suffixeUrl, Map<String, dynamic> data) async {
    try {
      FormData formData = FormData.fromMap(data);
      Response response = await dio.post(
        suffixeUrl.toString(),
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
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
  Future<Response> delete(String suffixeUrl, int? id) async {
    await _ensureInitialized();

    String path = id != null ? '$suffixeUrl/$id' : suffixeUrl;

    try {
      final response = await dio.delete(path);
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
