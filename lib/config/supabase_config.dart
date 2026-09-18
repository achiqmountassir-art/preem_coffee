/// Public Supabase connection values for the PREEM COFFEE customer app.
abstract final class SupabaseConfig {
  static const url = 'https://yyhfwztbsjugczwmwovh.supabase.co';

  /// IMPORTANT: Use the "anon" / "publishable" key from Supabase Dashboard.
  /// Never put the service_role / secret key in Flutter.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_FHhxVeIsbpI7l515lLBN3A_pw3iA8Dy',
  );

  static bool get hasPublishableKey {
    if (publishableKey.isEmpty) return false;
    // Reject secret/service keys without embedding any real secret value.
    final lower = publishableKey.toLowerCase();
    if (lower.startsWith('sb_secret_')) return false;
    if (lower.contains('service_role')) return false;
    return true;
  }
}
