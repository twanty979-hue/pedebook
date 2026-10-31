import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/catalog_model.dart';
import '../services/catalog_service.dart';
import 'book_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<CatalogItem> _catalogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await CatalogService.getUserCatalogs();
    if (mounted) {
      setState(() {
        _catalogs = list;
        _isLoading = false;
      });
    }
  }

  Uint8List? _getCoverBytes(CatalogItem catalog) {
    if (catalog.coverImage == null || catalog.coverImage!.isEmpty) return null;
    if (catalog.coverImage!.startsWith('http')) return null;
    try {
      final img = catalog.coverImage!;
      final base64String = img.contains(',') ? img.split(',').last : img;
      final clean = base64String.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  Widget _buildFallbackCover(CatalogItem item) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF27382E),
            Color(0xFF1E2B23),
            Color(0xFF121C16),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_stories, color: Color(0xFFC5A059), size: 14),
              const SizedBox(height: 2),
              Text(
                item.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8DCC7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ── 3D Book Cover Thumbnail with Spine & Rank Badge ──
  Widget _buildCoverThumbnail(CatalogItem item, int rank) {
    final bytes = _getCoverBytes(item);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            border: const Border(
              left: BorderSide(color: Color(0xFF9A7257), width: 3.5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF243129).withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(-2, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            child: bytes != null
                ? Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildFallbackCover(item),
                  )
                : (item.coverImage != null && item.coverImage!.startsWith('http')
                    ? Image.network(
                        item.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildFallbackCover(item),
                      )
                    : _buildFallbackCover(item)),
          ),
        ),
        // Mini Rank Badge (#1) in top-left
        Positioned(
          top: -4,
          left: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              gradient: rank == 0
                  ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                  : const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)]),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '#${rank + 1}',
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalViews = _catalogs.fold<int>(0, (sum, c) => sum + c.totalViews);
    final totalUnique = _catalogs.fold<int>(0, (sum, c) => sum + c.uniqueReaders);
    final avgViews = _catalogs.isEmpty ? 0 : (totalViews / _catalogs.length).round();

    final safeTotal = totalViews > 0 ? totalViews : 1;
    final returningPct = totalViews > totalUnique
        ? (((totalViews - totalUnique) / safeTotal) * 100).clamp(5, 75).round()
        : 18;
    final newPct = 100 - returningPct;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF8),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : RefreshIndicator(
                color: const Color(0xFF1B2820),
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── 1. Top Bar: Header + Live Indicator + Circular Refresh ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'สถิติผู้อ่าน',
                              style: GoogleFonts.prompt(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15221B),
                                letterSpacing: -0.6,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBF5F0),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFD4EADB), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1F7A54),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'เรียลไทม์',
                                        style: GoogleFonts.prompt(
                                          color: const Color(0xFF1B6B48),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE8E5DC), width: 0.8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _loadData,
                                    icon: const Icon(CupertinoIcons.arrow_clockwise, size: 15),
                                    color: const Color(0xFF1B2820),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── 2. Executive 2x2 Metric Grid ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'ยอดเปิดอ่านสะสม',
                                    value: '$totalViews',
                                    unit: 'ครั้ง',
                                    icon: CupertinoIcons.eye_fill,
                                    iconColor: const Color(0xFF1B2820),
                                    bgColor: const Color(0xFFF5F3EC),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'ผู้อ่านจริง (Unique)',
                                    value: '${totalUnique.clamp(1, 9999)}',
                                    unit: 'คน',
                                    icon: CupertinoIcons.person_2_fill,
                                    iconColor: const Color(0xFF1F7A54),
                                    bgColor: const Color(0xFFEBF5F0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'เฉลี่ยต่อเล่ม',
                                    value: '$avgViews',
                                    unit: 'วิว/เล่ม',
                                    icon: CupertinoIcons.chart_bar_alt_fill,
                                    iconColor: const Color(0xFF8C6648),
                                    bgColor: const Color(0xFFF7F4EE),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'สมุดทั้งหมด',
                                    value: '${_catalogs.length}',
                                    unit: 'เล่ม',
                                    icon: CupertinoIcons.book_fill,
                                    iconColor: const Color(0xFF3E4D43),
                                    bgColor: const Color(0xFFF1F0EA),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // ── 3. Audience Retention Card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFECE9E0), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1B2820).withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'สัดส่วนผู้อ่าน (Audience Retention)',
                                    style: GoogleFonts.prompt(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF15221B),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF5F0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'กลับมาอ่าน $returningPct%',
                                      style: GoogleFonts.prompt(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1B6B48),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Multi-segment Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  height: 8,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: returningPct,
                                        child: Container(color: const Color(0xFF1F7A54)),
                                      ),
                                      Expanded(
                                        flex: newPct,
                                        child: Container(color: const Color(0xFF1B2820)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1F7A54),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'กลับมาอ่านซ้ำ: $returningPct%',
                                        style: GoogleFonts.prompt(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF4A554E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1B2820),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'ผู้อ่านใหม่: $newPct%',
                                        style: GoogleFonts.prompt(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF4A554E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── 4. Section Header: ประสิทธิภาพรายเล่ม ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ประสิทธิภาพรายเล่ม (เปิดอ่านมากที่สุด)',
                              style: GoogleFonts.prompt(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15221B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'จัดอันดับ',
                              style: GoogleFonts.prompt(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF888E89),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

                    // ── 5. Catalog Leaderboard with Real 3D Book Cover ──
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                            final item = _catalogs[idx];
                            final ratio = totalViews > 0 ? (item.totalViews / totalViews) : 0.0;
                            final percentStr = (ratio * 100).toStringAsFixed(0);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookDetailScreen(catalog: item),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFECE9E0), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1B2820).withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // 3D Mini Book Cover
                                      _buildCoverThumbnail(item, idx),
                                      const SizedBox(width: 14),

                                      // Book Title & Metadata
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: GoogleFonts.prompt(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF15221B),
                                                letterSpacing: -0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF3F1EC),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text(
                                                    item.formattedSize,
                                                    style: GoogleFonts.prompt(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF5A635D),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '•  $percentStr% ของยอดวิว',
                                                  style: GoogleFonts.prompt(
                                                    fontSize: 10,
                                                    color: const Color(0xFF888E89),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // View Count & Readers Column
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${item.totalViews} วิว',
                                            style: GoogleFonts.prompt(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF15221B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEBF5F0),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${item.uniqueReaders.clamp(1, 999999)} คนอ่าน',
                                              style: GoogleFonts.prompt(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1B6B48),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(CupertinoIcons.chevron_right, size: 13, color: Color(0xFFB0AAA0)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _catalogs.length,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE9E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2820).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Text(
                unit,
                style: GoogleFonts.prompt(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF888E89),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF15221B),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.prompt(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6E746F),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
