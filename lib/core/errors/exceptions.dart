class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'لا يوجد اتصال بالإنترنت'});
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  const AuthException({required this.message, this.statusCode});
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;
  const ValidationException({required this.message, this.fieldErrors});
}
