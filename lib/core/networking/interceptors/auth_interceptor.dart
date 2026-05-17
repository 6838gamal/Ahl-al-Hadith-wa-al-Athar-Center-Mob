import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../../../core/constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.instance.read(AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await SecureStorage.instance.deleteAll();
    }
    handler.next(err);
  }
}
