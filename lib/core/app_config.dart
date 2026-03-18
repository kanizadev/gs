class AppConfig {
  /// Base URL for your backend API, e.g. `https://api.example.com`.
  /// Replace this with your real backend.
  static const String apiBaseUrl = 'https://example.com';

  /// Set to true while you are integrating backend incrementally.
  /// When enabled, repositories can return demo data if API fails.
  static const bool allowDemoFallback = true;
}

