/// Application configuration
/// ⚠️ WARNING: This contains test credentials. Do NOT use in production!
class AppConfig {
  // Sarvam AI Configuration (for transcription)
  static const String sarvamApiKey = 'sk_x4m312tk_U7sn7nyNC8EbGWqGIcOmG9mv';
  static const String sarvamApiUrl = 'https://api.sarvam.ai';

  // Featherless AI Configuration (for report generation)
  static const String featherApiKey =
      'rc_c8c07b65b3f9a53f668009a803ff84475295f6dcde84ab22880fef9b8f49744b';
  static const String featherApiUrl = 'https://api.featherless.ai/v1';
  static const String featherModel = 'm42-health/Llama3-Med42-8B';

  // App Settings
  static const int maxAudioDurationMinutes = 30;
  static const int maxFileSizeMB = 50;
}
