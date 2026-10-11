class AppConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String virusTotalApiKey = String.fromEnvironment(
    'VIRUSTOTAL_API_KEY',
    defaultValue: '',
  );

  static const String oditVerifyApiKey = String.fromEnvironment(
    'ODIT_VERIFY_API_KEY',
    defaultValue: '',
  );

  static const String appVersion = '1.0.0+1';

  static const int apiTimeoutSeconds = 15;

  static const String appName = 'መከታ (Meketa)';

  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;
  static bool get isVirusTotalConfigured => virusTotalApiKey.isNotEmpty;
  static bool get isOditVerifyConfigured => oditVerifyApiKey.isNotEmpty;

  static bool get hasDemoKeys => false;

  static const Map<String, String> defaultHttpHeaders = {
    'User-Agent': 'Meketa-Scam-Shield/1.0 (+https://meketa.et)',
    'Accept': 'application/json',
  };
}
