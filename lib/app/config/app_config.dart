/// App-level configuration constants.
/// Provide GEMINI_API_KEY via --dart-define at build/run time.
class AppConfig {
  // Get your free key at: https://aistudio.google.com/apikey
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}