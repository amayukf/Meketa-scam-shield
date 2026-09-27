class AppConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'demo-gemini-key',
  );

  static const String virusTotalApiKey = String.fromEnvironment(
    'VIRUSTOTAL_API_KEY',
    defaultValue: 'demo-key-replace-with-yours',
  );

  static const String oditVerifyApiKey = String.fromEnvironment(
    'ODIT_VERIFY_API_KEY',
    defaultValue: 'demo-odit-key',
  );

  static const String appVersion = '1.0.0+1';

  static const int apiTimeoutSeconds = 15;

  static const String appName = 'መከታ (Meketa)';

  static bool get hasDemoKeys {
    return geminiApiKey == 'demo-key-replace-with-yours' ||
        virusTotalApiKey == 'demo-key-replace-with-yours' ||
        oditVerifyApiKey == 'demo-key-replace-with-yours';
  }

  static const Map<String, String> defaultHttpHeaders = {
    'User-Agent': 'Meketa-Scam-Shield/1.0 (+https://meketa.et)',
    'Accept': 'application/json',
  };
}
