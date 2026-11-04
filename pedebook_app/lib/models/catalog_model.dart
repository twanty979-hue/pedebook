class CatalogItem {
  final String id;
  final String slug;
  final String title;
  final String fileName;
  final String? coverImage;
  final int fileSizeBytes;
  final int totalViews;
  final int uniqueReaders;
  final int returningCount;
  final int newCount;
  final int returnRate;
  final int pageCount;
  final DateTime? createdAt;
  final bool isPublic;
  final String bgType;
  final String bgValue;
  final bool isFloating;

  CatalogItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.fileName,
    this.coverImage,
    required this.fileSizeBytes,
    required this.totalViews,
    this.uniqueReaders = 0,
    this.returningCount = 0,
    this.newCount = 0,
    this.returnRate = 0,
    this.pageCount = 0,
    this.createdAt,
    this.isPublic = true,
    this.bgType = 'gradient',
    this.bgValue = 'auto',
    this.isFloating = false,
  });

  String get publicUrl => 'https://www.pedebook.com/catalog/$slug';

  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 KB';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  CatalogItem copyWith({
    String? id,
    String? slug,
    String? title,
    String? fileName,
    String? coverImage,
    int? fileSizeBytes,
    int? totalViews,
    int? uniqueReaders,
    int? returningCount,
    int? newCount,
    int? returnRate,
    int? pageCount,
    DateTime? createdAt,
    bool? isPublic,
    String? bgType,
    String? bgValue,
    bool? isFloating,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      coverImage: coverImage ?? this.coverImage,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      totalViews: totalViews ?? this.totalViews,
      uniqueReaders: uniqueReaders ?? this.uniqueReaders,
      returningCount: returningCount ?? this.returningCount,
      newCount: newCount ?? this.newCount,
      returnRate: returnRate ?? this.returnRate,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      bgType: bgType ?? this.bgType,
      bgValue: bgValue ?? this.bgValue,
      isFloating: isFloating ?? this.isFloating,
    );
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['displayTitle']?.toString() ??
          json['fileName']?.toString() ??
          json['file_name']?.toString() ??
          'สมุดแค็ตตาล็อก',
      fileName: json['fileName']?.toString() ??
          json['file_name']?.toString() ??
          '',
      coverImage: json['coverImage']?.toString() ??
          json['cover_image']?.toString(),
      fileSizeBytes: (json['size'] as num?)?.toInt() ??
          (json['fileSizeBytes'] as num?)?.toInt() ??
          (json['file_size_bytes'] as num?)?.toInt() ??
          0,
      totalViews: (json['totalViews'] as num?)?.toInt() ??
          (json['total_views'] as num?)?.toInt() ??
          0,
      uniqueReaders: (json['uniqueReaders'] as num?)?.toInt() ??
          (json['unique_readers'] as num?)?.toInt() ??
          0,
      returningCount: (json['returningCount'] as num?)?.toInt() ??
          (json['returning_count'] as num?)?.toInt() ??
          0,
      newCount: (json['newCount'] as num?)?.toInt() ??
          (json['new_count'] as num?)?.toInt() ??
          0,
      returnRate: (json['returnRate'] as num?)?.toInt() ??
          (json['return_rate'] as num?)?.toInt() ??
          0,
      pageCount: (json['pageCount'] as num?)?.toInt() ??
          (json['page_count'] as num?)?.toInt() ??
          0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null),
      isPublic: json['is_public'] == null
          ? (json['isPublic'] as bool? ?? true)
          : (json['is_public'] as bool? ?? true),
      bgType: json['bg_type']?.toString() ??
          json['bgType']?.toString() ??
          'gradient',
      bgValue: json['bg_value']?.toString() ??
          json['bgValue']?.toString() ??
          'auto',
      isFloating: json['is_floating'] == null
          ? (json['isFloating'] as bool? ?? false)
          : (json['is_floating'] as bool? ?? false),
    );
  }
}

