class AppConstants {
  AppConstants._();

  static const String appName = 'مركز أهل الحديث والأثر';
  static const String appNameEn = 'Ahl al-Hadith wa al-Athar Center';
  static const String appVersion = '1.0.0';

  static const int paginationLimit = 20;
  static const int messagePaginationLimit = 50;
  static const int searchDebounceMs = 400;

  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';

  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);

  static const int maxMessageLength = 2000;
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedAudioTypes = ['mp3', 'ogg', 'm4a', 'wav'];
  static const List<String> allowedDocTypes = ['pdf', 'doc', 'docx'];
}
