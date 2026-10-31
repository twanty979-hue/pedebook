class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String currentPlan;
  final int storageUsedBytes;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.currentPlan = 'free',
    this.storageUsedBytes = 0,
  });

  String get formattedStorage {
    if (storageUsedBytes <= 0) return '0 MB';
    return '${(storageUsedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory AppUser.fromSupabase(Map<String, dynamic> data) {
    return AppUser(
      id: data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      displayName: data['display_name']?.toString() ??
          data['raw_user_meta_data']?['full_name']?.toString() ??
          data['email']?.toString().split('@').first ??
          'ผู้ใช้งาน Pedebook',
      avatarUrl: data['avatar_url']?.toString(),
      currentPlan: data['current_plan']?.toString() ?? 'free',
      storageUsedBytes: (data['storage_used_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}

