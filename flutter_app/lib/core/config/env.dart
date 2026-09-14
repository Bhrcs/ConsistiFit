abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const legacyAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseKey =>
      supabasePublishableKey.isNotEmpty ? supabasePublishableKey : legacyAnonKey;

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
