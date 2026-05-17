import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/mock_data_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/models/user_model.dart';

abstract class AuthRepository {
  FutureResult<UserModel> login(String username, String password);
  FutureResult<UserModel> register({required String username, required String password, required String academicId, required String gender});
  FutureResult<UserModel> getCurrentUser();
  FutureResult<bool> logout();
  FutureResult<bool> isAuthenticated();
}

class AuthRepositoryImpl implements AuthRepository {
  final MockDataService _mockService;
  final SecureStorage _secureStorage;

  AuthRepositoryImpl({
    MockDataService? mockService,
    SecureStorage? secureStorage,
  })  : _mockService = mockService ?? MockDataService.instance,
        _secureStorage = secureStorage ?? SecureStorage.instance;

  @override
  FutureResult<UserModel> login(String username, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final user = _mockService.authenticate(username, password);
      if (user == null) {
        return const Left(AuthFailure(message: 'اسم المستخدم أو كلمة المرور غير صحيحة'));
      }
      if (user.status == 'pending') {
        return const Left(AuthFailure(message: 'حسابك قيد المراجعة، يرجى الانتظار حتى يتم الموافقة عليه'));
      }
      if (user.status == 'banned' || user.status == 'suspended') {
        return const Left(AuthFailure(message: 'تم تعليق حسابك، تواصل مع الإدارة'));
      }
      await _secureStorage.write(AppConstants.tokenKey, 'mock_token_${user.id}');
      await _secureStorage.write(AppConstants.userKey, jsonEncode(user.toJson()));
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  FutureResult<UserModel> register({required String username, required String password, required String academicId, required String gender}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final exists = _mockService.allUsers.any((u) => u.username == username || u.academicId == academicId);
      if (exists) return const Left(AuthFailure(message: 'اسم المستخدم أو الرقم الأكاديمي مستخدم مسبقاً'));
      final newUser = UserModel(id: 'new_u', username: username, displayName: null, academicId: academicId, role: gender == 'female' ? 'female_student' : 'male_student', status: 'pending', gender: gender, createdAt: DateTime.now());
      return Right(newUser);
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ: $e'));
    }
  }

  @override
  FutureResult<UserModel> getCurrentUser() async {
    try {
      final userJson = await _secureStorage.read(AppConstants.userKey);
      if (userJson == null) return const Left(AuthFailure(message: 'لم يتم تسجيل الدخول'));
      final user = UserModel.fromJson(jsonDecode(userJson));
      return Right(user);
    } catch (e) {
      return const Left(CacheFailure(message: 'فشل في جلب بيانات المستخدم'));
    }
  }

  @override
  FutureResult<bool> logout() async {
    await _secureStorage.deleteAll();
    return const Right(true);
  }

  @override
  FutureResult<bool> isAuthenticated() async {
    final token = await _secureStorage.read(AppConstants.tokenKey);
    return Right(token != null);
  }
}
