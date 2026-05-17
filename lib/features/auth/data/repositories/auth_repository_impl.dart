import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/models/user_model.dart';

abstract class AuthRepository {
  FutureResult<UserModel> login(String username, String password);
  FutureResult<UserModel> adminLogin(String username, String password);
  FutureResult<String> register({
    required String username,
    required String displayName,
    required String password,
    required String academicId,
    required String role,
    String? email,
  });
  FutureResult<UserModel> getCurrentUser();
  FutureResult<bool> logout();
  FutureResult<bool> isAuthenticated();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthRepositoryImpl({ApiClient? api, SecureStorage? storage})
      : _api = api ?? ApiClient.instance,
        _storage = storage ?? SecureStorage.instance;

  @override
  FutureResult<UserModel> login(String username, String password) async {
    try {
      final res = await _api.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );
      return await _saveSession(res.data);
    } on DioException catch (e) {
      return Left(AuthFailure(message: _extractMessage(e, 'اسم المستخدم أو كلمة المرور غير صحيحة')));
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  FutureResult<UserModel> adminLogin(String username, String password) async {
    try {
      final res = await _api.post(
        ApiEndpoints.adminLogin,
        data: {'username': username, 'password': password},
      );
      return await _saveSession(res.data);
    } on DioException catch (e) {
      return Left(AuthFailure(message: _extractMessage(e, 'بيانات الدخول غير صحيحة')));
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  FutureResult<String> register({
    required String username,
    required String displayName,
    required String password,
    required String academicId,
    required String role,
    String? email,
  }) async {
    try {
      await _api.post(ApiEndpoints.register, data: {
        'username': username,
        'display_name': displayName,
        'password': password,
        'academic_id': academicId,
        'role': role,
        if (email != null) 'email': email,
      });
      return const Right('تم إرسال طلب التسجيل بنجاح وسيتم مراجعته من قِبل الإدارة');
    } on DioException catch (e) {
      if (e.response?.statusCode == 202) {
        return Right(e.response?.data['detail'] ?? 'تم إرسال طلب التسجيل');
      }
      return Left(AuthFailure(message: _extractMessage(e, 'فشل في إنشاء الحساب')));
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  FutureResult<UserModel> getCurrentUser() async {
    try {
      final token = await _storage.read(AppConstants.tokenKey);
      if (token == null) return const Left(AuthFailure(message: 'لم يتم تسجيل الدخول'));

      final res = await _api.get(ApiEndpoints.me);
      final user = UserModel.fromJson(res.data as Map<String, dynamic>);
      await _storage.write(AppConstants.userKey, jsonEncode(user.toJson()));
      return Right(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.deleteAll();
        return const Left(AuthFailure(message: 'انتهت الجلسة'));
      }
      final cached = await _storage.read(AppConstants.userKey);
      if (cached != null) {
        return Right(UserModel.fromJson(jsonDecode(cached)));
      }
      return Left(ServerFailure(message: _extractMessage(e, 'فشل في جلب بيانات المستخدم')));
    } catch (e) {
      return const Left(CacheFailure(message: 'فشل في جلب بيانات المستخدم'));
    }
  }

  @override
  FutureResult<bool> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {}
    await _storage.deleteAll();
    return const Right(true);
  }

  @override
  FutureResult<bool> isAuthenticated() async {
    final token = await _storage.read(AppConstants.tokenKey);
    return Right(token != null && token.isNotEmpty);
  }

  Future<Either<Failure, UserModel>> _saveSession(dynamic data) async {
    final token = data['access_token'] as String;
    final userMap = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userMap);
    await _storage.write(AppConstants.tokenKey, token);
    await _storage.write(AppConstants.userKey, jsonEncode(user.toJson()));
    return Right(user);
  }

  String _extractMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map) return data['detail']?.toString() ?? fallback;
    } catch (_) {}
    return fallback;
  }
}
