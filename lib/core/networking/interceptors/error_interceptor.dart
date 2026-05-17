import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        throw NetworkException(message: 'انتهت مهلة الاتصال');
      case DioExceptionType.connectionError:
        throw const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = _extractMessage(err.response?.data);
        if (statusCode == 401) {
          throw AuthException(message: message ?? 'جلستك انتهت، يرجى تسجيل الدخول مجدداً', statusCode: statusCode);
        }
        throw ServerException(message: message ?? 'حدث خطأ في الخادم', statusCode: statusCode);
      default:
        throw ServerException(message: err.message ?? 'حدث خطأ غير متوقع');
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail'] as String? ?? data['message'] as String?;
    }
    return null;
  }
}
