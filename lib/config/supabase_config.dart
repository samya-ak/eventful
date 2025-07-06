import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  /// Load environment variables
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  /// Get Supabase URL from environment
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    return url;
  }

  /// Get Supabase Anon Key from environment
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    return key;
  }
}
