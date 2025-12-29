/// Configuration for Supabase connection.
///
/// These values can be set via compile-time environment variables:
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co
/// flutter run --dart-define=SUPABASE_ANON_KEY=your-anon-key
/// ```
///
/// For local development, the defaults point to a local Supabase instance.
abstract class SupabaseConfig {
  /// The Supabase project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );

  /// The Supabase anonymous key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Whether we're using local development mode.
  static bool get isLocalDevelopment =>
      supabaseUrl.contains('localhost') || supabaseUrl.contains('127.0.0.1');

  /// Validates that required configuration is present.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Throws an error if configuration is missing.
  static void validateOrThrow() {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. '
        'Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
      );
    }
  }
}
