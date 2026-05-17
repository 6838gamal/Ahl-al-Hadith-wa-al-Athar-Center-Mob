import 'package:hive/hive.dart';

part 'user_model.g.dart';

enum UserRole { admin, moderator, sheikh, male_student, female_student }
enum UserStatus { pending, active, suspended, banned }
enum UserGender { male, female }

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String? displayName;

  @HiveField(3)
  final String academicId;

  @HiveField(4)
  final String role;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final String gender;

  @HiveField(7)
  final String? avatarUrl;

  @HiveField(8)
  final String? email;

  @HiveField(9)
  final String? bio;

  @HiveField(10)
  final bool isOnline;

  @HiveField(11)
  final DateTime? lastSeen;

  @HiveField(12)
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    this.displayName,
    required this.academicId,
    required this.role,
    required this.status,
    required this.gender,
    this.avatarUrl,
    this.email,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
  });

  UserRole get userRole => UserRole.values.firstWhere(
        (r) => r.name == role,
        orElse: () => UserRole.male_student,
      );

  UserStatus get userStatus => UserStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => UserStatus.active,
      );

  UserGender get userGender => gender == 'female' ? UserGender.female : UserGender.male;

  bool get isAdmin => userRole == UserRole.admin;
  bool get isModerator => userRole == UserRole.moderator || isAdmin;
  bool get isSheikh => userRole == UserRole.sheikh;
  bool get isStudent => userRole == UserRole.male_student || userRole == UserRole.female_student;
  bool get isActive => userStatus == UserStatus.active;

  String get effectiveName => displayName ?? username;
  String get initials {
    final name = effectiveName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }

  String get roleLabel {
    switch (userRole) {
      case UserRole.admin: return 'مدير النظام';
      case UserRole.moderator: return 'مشرف';
      case UserRole.sheikh: return 'شيخ';
      case UserRole.male_student: return 'طالب';
      case UserRole.female_student: return 'طالبة';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String?,
        academicId: json['academic_id'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
        gender: json['gender'] as String,
        avatarUrl: json['avatar_url'] as String?,
        email: json['email'] as String?,
        bio: json['bio'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
        lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'academic_id': academicId,
        'role': role,
        'status': status,
        'gender': gender,
        'avatar_url': avatarUrl,
        'email': email,
        'bio': bio,
        'is_online': isOnline,
        'last_seen': lastSeen?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isOnline,
    String? status,
  }) =>
      UserModel(
        id: id,
        username: username,
        displayName: displayName ?? this.displayName,
        academicId: academicId,
        role: role,
        status: status ?? this.status,
        gender: gender,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        email: email,
        bio: bio ?? this.bio,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen,
        createdAt: createdAt,
      );
}
