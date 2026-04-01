import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tribuneo_backoffice/core/notifiers/maintenance_notifier.dart';
import 'package:tribuneo_backoffice/env/env.dart';

class RemoteDataSource {
  final String _apiKey = Env.kAPiKey;
  final String _baseUrl = Env.kUrl;
  final Dio _dio;

  RemoteDataSource() : _dio = Dio() {
    _dio.options.validateStatus = (status) {
      return status! < 504;
    };
    _dio.options.connectTimeout = Duration(minutes: 5);
    _dio.options.receiveTimeout = Duration(minutes: 5);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (request, handler) {
        return handler.next(request);
      },
      onResponse: (response, handler) {
        if (response.data is Uint8List) {
          try {
            if (kDebugMode) {
              print("La réponse est un fichier en bytes");
            }
          } catch (e) {
            print("Erreur lors du téléchargement du fichier: $e");
          }
        } else if (response.data is Map || response.data is List) {
          try {
            print("Conversion en JSON: ${response.data}");
            response.data = json.encode(response.data);
          } catch (e) {
            print("Erreur lors de la conversion en JSON: $e");
          }
        } else {
          print("Type de données inconnu: ${response.data.runtimeType}");
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('Error: ${e.response?.statusCode} ${e.response?.data}');
        return handler.next(e);
      },
    ));
    // dio.interceptors.add(LogInterceptor(
    //   request: true,
    //   responseBody: true,
    //   requestBody: true,
    //   error: true,
    // ));
  }

  Uri buildUri(String baseUrl, String path,
      {Map<String, dynamic>? queryParams}) {
    Uri baseUri = Uri.parse(baseUrl);
    Uri fullUri = baseUri.replace(
        path: baseUri.path + path, queryParameters: queryParams);
    return fullUri;
  }

  Future<Response> checkForMaintenance(Response response) async {
    if (response.statusCode == 503) {
      MaintenanceNotifier.enterMaintenanceMode();
      // Vous pouvez gérer la maintenance ici, par exemple, renvoyer une réponse personnalisée
    }
    return response;
  }

  /// Méthode POST standard (envoi de JSON)
  Future<Response> post(String suffixeUrl, String data,
      {String? token, bool? bytesType}) async {
    try {
      var url = buildUri(_baseUrl, suffixeUrl);
      final response = await _dio.post(url.toString(),
          data: data,
          options: Options(
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'X-API-KEY': _apiKey,
                if (token != null) 'Authorization': 'Bearer $token'
              },
              responseType:
                  bytesType == true ? ResponseType.bytes : ResponseType.json));
      return checkForMaintenance(response);
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Méthode POST pour l'envoi de fichiers (multipart/form-data)
  Future<Response> postWithFile(
      String suffixeUrl, Map<String, dynamic> data) async {
    try {
      var url = buildUri(_baseUrl, suffixeUrl);
      FormData formData = FormData.fromMap(data);
      Response response = await _dio.post(
        url.toString(),
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'X-API-KEY': _apiKey,
          },
        ),
      );
      return response;
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Méthode GET
  Future<Response> get(String suffixeUrl,
      {Map<String, dynamic>? queryParams,
      int? id,
      String? token,
      String? urlAdd,
      bool? bytesType}) async {
    String path = id != null ? '$suffixeUrl/$id' : suffixeUrl;
    if (urlAdd != null) {
      path = '$path/$urlAdd';
    }
    var url = buildUri(_baseUrl, path, queryParams: queryParams);
    final response = await _dio.get(url.toString(),
        options: Options(
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'X-API-KEY': _apiKey,
              if (token != null) 'Authorization': 'Bearer $token',
            },
            responseType:
                bytesType == true ? ResponseType.bytes : ResponseType.json));
    return checkForMaintenance(response);
  }

  /// Méthode PUT standard (envoi de JSON)
  Future<Response> put(String suffixeUrl, String data,
      {int? id, String? token}) async {
    String path = id != null ? '$suffixeUrl/$id' : suffixeUrl;
    var url = buildUri(_baseUrl, path);
    final response = await _dio.put(url.toString(),
        data: data,
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-API-KEY': _apiKey,
          if (token != null) 'Authorization': 'Bearer $token',
        }));
    return checkForMaintenance(response);
  }

  /// Méthode softDelete (PUT)
  Future<Response> softDelete(String suffixUrl, int id,
      {String? data, String? token}) async {
    var url = buildUri(_baseUrl, '$suffixUrl/$id');
    final response = await _dio.put(url.toString(),
        data: data,
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-API-KEY': _apiKey,
          if (token != null) ' Authorization ': ' Bearer $token ',
        }));
    return checkForMaintenance(response);
  }

  /// Méthode DELETE
  Future<Response> delete(String suffixeUrl, int? id, {String? token}) async {
    String path = id != null ? '$suffixeUrl/$id' : suffixeUrl;
    var url = buildUri(_baseUrl, path);
    final response = await _dio.delete(url.toString(),
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-API-KEY': _apiKey,
          if (token != null) 'Authorization': 'Bearer $token',
        }));
    return checkForMaintenance(response);
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
