enum AppEnvironment { development, staging, production }

class AppEnv {
  static AppEnvironment _environment = AppEnvironment.development;
  static AppEnvironment get environment => _environment;
  static void setEnvironment(AppEnvironment env) { _environment = env; }
  static bool get isDevelopment => _environment == AppEnvironment.development;
  static bool get isProduction => _environment == AppEnvironment.production;
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    return envUrl.isEmpty ? '/api' : envUrl;
  }
  static bool get useMockData => false;
  static Duration get connectionTimeout => const Duration(seconds: 30);
  static Duration get receiveTimeout => const Duration(seconds: 30);
}
