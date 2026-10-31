import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/catalog_model.dart';
import 'api_service.dart';

class CatalogService {
  static final SupabaseClient _supabase = SupabaseService.client;

  /// Fetch catalogs for the currently logged-in user
  static Future<List<CatalogItem>> getUserCatalogs() async {
    final user = _supabase.auth.currentUser;
    // Default to creator user_id if not logged in
    final targetUserId = user?.id ?? '179032f4-7640-44be-bea7-6fd2536e918f';

    try {
      final data = await _supabase
          .from('catalogs')
          .select()
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);

      if (data.isNotEmpty) {
        return data.map((item) => CatalogItem.fromJson(item)).toList();
      }
    } catch (_) {}

    // Fallback to API service
    return await PedebookApiService.fetchCatalogs(userId: targetUserId);
  }

  /// Fetch page-by-page stats for a specific catalog
  static Future<List<Map<String, dynamic>>> getPageStats(String catalogId) async {
    try {
      final res = await _supabase
          .from('catalog_page_stats')
          .select()
          .eq('catalog_id', catalogId)
          .order('page_number', ascending: true);

      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}

