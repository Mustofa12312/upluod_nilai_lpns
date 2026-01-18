import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Jalankan ini di main.dart sebelum runApp()
  static Future<void> init() async {
    await Supabase.initialize(
      url:
          'https://kmhinxzbhuxsgyhvexzs.supabase.co', // SAYA TIDAK MASUKAN UNTUK KEAMANAN DATA
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttaGlueHpiaHV4c2d5aHZleHpzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4OTcxMDYsImV4cCI6MjA4MzQ3MzEwNn0.GyRb-xwYDSkF4yN9JOmi5i_1RvRBGax65pis8ZT94GY', //SAYA TIDAK MASUKAN UNTUK KEAMANAN DATA
    );
  }

  /// Supabase client yang bisa dipakai di mana saja
  static SupabaseClient get client => Supabase.instance.client;
}
