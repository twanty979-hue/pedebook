import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://jyutywoahezpekryfndb.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5dXR5d29haGV6cGVrcnlmbmRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyNzkzNzIsImV4cCI6MjEwODg1NTM3Mn0.RpZSqYzw1VOD7fpWPNuZ_Zhd7WCZy8_Ca-Boi2BQ64M';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
}

