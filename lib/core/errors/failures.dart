abstract class Failure {
  final String message;
  final int? statusCode;
  const Failure({required this.message, this.statusCode});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'لا يوجد اتصال بالإنترنت'});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  const ValidationFailure({required super.message, this.fieldErrors});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'غير مصرح لك بهذا الإجراء'});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'العنصر غير موجود'});
}

class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'ليس لديك صلاحية للقيام بهذا الإجراء'});
}
