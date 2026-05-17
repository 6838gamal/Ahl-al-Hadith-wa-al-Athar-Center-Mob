import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: err.error,
            message: 'انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.',
          ),
        );
        return;
      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: err.error,
            message: 'لا يوجد اتصال بالإنترنت أو تعذّر الوصول للخادم.',
          ),
        );
        return;
      default:
        handler.next(err);
    }
  }
}
