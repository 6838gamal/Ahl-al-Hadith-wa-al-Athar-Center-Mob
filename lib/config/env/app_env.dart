enum AppEnvironment { development, staging, production }

class AppEnv {
  static AppEnvironment _environment = AppEnvironment.development;

  static AppEnvironment get environment => _environment;

  static void setEnvironment(AppEnvironment env) {
    _environment = env;
  }

  static bool get isDevelopment => _environment == AppEnvironment.development;
  static bool get isProduction => _environment == AppEnvironment.production;

  static String get apiBaseUrl {
    switch (_environment) {
      case AppEnvironment.development:
        return 'http://localhost:8000/api/v1';
      case AppEnvironment.staging:
        return 'https://staging-api.ahlalhadith.com/api/v1';
      case AppEnvironment.production:
        return 'https://api.ahlalhadith.com/api/v1';
    }
  }

  static String get wsBaseUrl {
    switch (_environment) {
      case AppEnvironment.development:
        return 'ws://localhost:8000/ws';
      case AppEnvironment.staging:
        return 'wss://staging-api.ahlalhadith.com/ws';
      case AppEnvironment.production:
        return 'wss://api.ahlalhadith.com/ws';
    }
  }

  static bool get useMockData => isDevelopment;
  static Duration get connectionTimeout => const Duration(seconds: 30);
  static Duration get receiveTimeout => const Duration(seconds: 30);
}
