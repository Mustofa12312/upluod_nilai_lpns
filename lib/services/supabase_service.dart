import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Jalankan ini di main.dart sebelum runApp()
  static Future<void> init() async {
    await Supabase.initialize(
      url:
          'https://wcjuagsmmxyxmtwnnndr.supabase.co', // SAYA TIDAK MASUKAN UNTUK KEAMANAN DATA
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjanVhZ3NtbXh5eG10d25ubmRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyMTIyNDYsImV4cCI6MjA3OTc4ODI0Nn0.gUr5qFkmrLO4zrxvIFYHaELfSciWOPCULq0p0Ip1ZAE', //SAYA TIDAK MASUKAN UNTUK KEAMANAN DATA
    );
  }

  /// Supabase client yang bisa dipakai di mana saja
  static SupabaseClient get client => Supabase.instance.client;
}
