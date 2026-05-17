import 'package:dio/dio.dart';
import '../../config/env/app_env.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.apiBaseUrl,
        connectTimeout: AppEnv.connectionTimeout,
        receiveTimeout: AppEnv.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      if (AppEnv.isDevelopment) LoggingInterceptor(),
    ]);
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.delete<T>(path, data: data, options: options);
}
