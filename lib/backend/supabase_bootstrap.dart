import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'supabase_tables.dart';

/// Initializes the shared [Supabase] client. Call once from `main()`.
Future<void> initializeSupabase() async {
  if (!SupabaseConfig.hasPublishableKey) {
    debugPrint(
      'Supabase publishable/anon key is missing. '
      'Set SUPABASE_PUBLISHABLE_KEY or paste it in supabase_config.dart.',
    );
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.hasPublishableKey
        ? SupabaseConfig.publishableKey
        : 'missing-anon-key',
  );

  if (kDebugMode && SupabaseConfig.hasPublishableKey) {
    await _logConnectionCheck();
  }
}

SupabaseClient get supabaseClient => Supabase.instance.client;

Future<void> _logConnectionCheck() async {
  try {
    // Attempt a simple ping to see if the table exists and RLS allows access
    await supabaseClient.from(SupabaseTables.products).select('id').limit(1);
    debugPrint('Supabase connection OK (${SupabaseConfig.url})');
  } catch (error) {
    debugPrint('Supabase initialized, but connection test failed: $error');
  }
}
