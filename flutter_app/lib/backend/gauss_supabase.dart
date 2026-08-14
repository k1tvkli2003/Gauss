import 'package:supabase_flutter/supabase_flutter.dart';

/// Public Android client configuration.
///
/// A Supabase publishable key is intentionally safe to ship in a client. It
/// grants no data access by itself: every Gauss table is protected by RLS and
/// the user's short-lived Auth session. Elevated keys never enter this app.
abstract final class GaussSupabase {
  static const projectRef = 'evyjrbwibwrdkjakooor';
  static const url = 'https://$projectRef.supabase.co';
  static const publishableKey =
      'sb_publishable_vBHY80YJpyDHsF4S2mkqkg_W00JuHIn';

  static Future<SupabaseClient> initialize() async {
    final instance = await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
        autoRefreshToken: true,
      ),
    );
    return instance.client;
  }
}
