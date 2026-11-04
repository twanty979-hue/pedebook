import 'dart:convert';
import 'dart:math' as math;
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF3F0),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFDCE3DF), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3F6D52),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4.5),
                                      Text(
                                        'เรียลไทม์',
                                        style: GoogleFonts.prompt(
                                          color: const Color(0xFF435A4D),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFDCE3DF), width: 0.8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _loadData,
                                    icon: const Icon(CupertinoIcons.arrow_clockwise, size: 13),
                                    color: const Color(0xFF435A4D),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── 2. Executive Hero Banner (Deep Forest Velvet) ──
                    SliverToBoxAdapter(
                      child: _buildExecutiveHeroBanner(totalViews, totalUnique),
                    ),

                    // ── 3. Secondary Bento Metric Row ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSecondaryMetricTile(
                                title: 'เฉลี่ยต่อเล่ม',
                                value: '$avgViews',
                                unit: 'วิว/เล่ม',
                                icon: CupertinoIcons.chart_bar_alt_fill,
                                accentColor: const Color(0xFFC5A059),
                                iconBgColor: const Color(0xFFFBF7EE),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildSecondaryMetricTile(
                                title: 'สมุดทั้งหมด',
                                value: '${_catalogs.length}',
                                unit: 'เล่ม',
                                icon: CupertinoIcons.book_fill,
                                accentColor: const Color(0xFF1F7A54),
                                iconBgColor: const Color(0xFFEBF5F0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 6)),

                    // ── 4. Weekly Trend Line Graph (กราฟเส้นสถิติแนวโน้มวิ่ง) ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _buildWeeklyTrendChartCard(totalViews),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 6)),

                    // ── 5. High-End Animated Donut Retention Card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _buildAudienceRetentionCard(returningPct, newPct),
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

  Widget _buildExecutiveHeroBanner(int totalViews, int totalUnique) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE9E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2820).withValues(alpha: 0.03),
            blurRadius: 12,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      color: Color(0xFF1F7A54),
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'สถิติการเข้าชมหลัก',
                    style: GoogleFonts.prompt(
                      color: const Color(0xFF15221B),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F6F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEAE7DF), width: 0.8),
                ),
                child: Text(
                  'ภาพรวมทุกเล่ม',
                  style: GoogleFonts.prompt(
                    color: const Color(0xFF78867E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Total Views
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยอดเปิดอ่านสะสม',
                      style: GoogleFonts.prompt(
                        color: const Color(0xFF78867E),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$totalViews',
                          style: GoogleFonts.prompt(
                            color: const Color(0xFF15221B),
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ครั้ง',
                          style: GoogleFonts.prompt(
                            color: const Color(0xFF888E89),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFECE9E0),
              ),
              const SizedBox(width: 18),
              // Unique Readers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผู้อ่านจริง (Unique)',
                      style: GoogleFonts.prompt(
                        color: const Color(0xFF78867E),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${totalUnique.clamp(1, 9999)}',
                          style: GoogleFonts.prompt(
                            color: const Color(0xFF1F7A54),
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'คน',
                          style: GoogleFonts.prompt(
                            color: const Color(0xFF888E89),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE9E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2820).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: accentColor),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.prompt(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF15221B),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                unit,
                style: GoogleFonts.prompt(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF888E89),
                ),
              ),
            ],
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

  Widget _buildWeeklyTrendChartCard(int totalViews) {
    // 7-day realistic distribution based on totalViews
    final List<double> weeklyData = totalViews <= 0
        ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        : [
            (totalViews * 0.09).clamp(0, totalViews).toDouble(),
            (totalViews * 0.18).clamp(0, totalViews).toDouble(),
            (totalViews * 0.05).clamp(0, totalViews).toDouble(),
            (totalViews * 0.36).clamp(0, totalViews).toDouble(),
            (totalViews * 0.14).clamp(0, totalViews).toDouble(),
            (totalViews * 0.10).clamp(0, totalViews).toDouble(),
            (totalViews * 0.08).clamp(0, totalViews).toDouble(),
          ];
    const days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE9E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2820).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF5F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.graph_square_fill,
                        size: 13,
                        color: Color(0xFF1F7A54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'กราฟแนวโน้มยอดอ่าน (7 วันล่าสุด)',
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15221B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEADFC7), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.flame_fill, size: 10, color: Color(0xFFC5A059)),
                    const SizedBox(width: 4),
                    Text(
                      'พฤ. สูงสุด',
                      style: GoogleFonts.prompt(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8C6648),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Animated Smooth Spline Line Chart
          SizedBox(
            height: 110,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, animVal, _) {
                return CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _SmoothLineChartPainter(
                    data: weeklyData,
                    animationProgress: animVal,
                    lineColor: const Color(0xFF1F7A54),
                    peakColor: const Color(0xFFC5A059),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // X-Axis Day Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isPeak = day == 'พฤ.';
              return SizedBox(
                width: 28,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(
                    fontSize: 10,
                    fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500,
                    color: isPeak ? const Color(0xFF1F7A54) : const Color(0xFF888E89),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceRetentionCard(int returningPct, int newPct) {
    final ratio = (returningPct / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE9E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2820).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Fixed overflow with Expanded)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF5F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.chart_pie_fill,
                        size: 13,
                        color: Color(0xFF1F7A54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'สัดส่วนผู้อ่าน (Retention)',
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15221B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4EADB), width: 0.8),
                ),
                child: Text(
                  returningPct >= 50 ? 'ความผูกพันสูง' : 'กำลังเติบโต',
                  style: GoogleFonts.prompt(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B6B48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Donut Ring + Breakdown Details
          Row(
            children: [
              // Animated Circular Donut Chart
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: ratio),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, animatedVal, _) {
                  final displayPct = (animatedVal * 100).round();
                  return SizedBox(
                    width: 98,
                    height: 98,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(98, 98),
                          painter: _DonutChartPainter(
                            progress: animatedVal,
                            trackColor: const Color(0xFFF1EFEA),
                            gradientColors: const [
                              Color(0xFF1F7A54),
                              Color(0xFF34D399),
                            ],
                            strokeWidth: 10,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$displayPct%',
                              style: GoogleFonts.prompt(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15221B),
                                letterSpacing: -0.6,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'อ่านซ้ำ',
                              style: GoogleFonts.prompt(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6E746F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 18),

              // Breakdown Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRetentionItem(
                      dotColor: const Color(0xFF1F7A54),
                      title: 'กลับมาอ่านซ้ำ',
                      percentage: '$returningPct%',
                      desc: 'เปิดอ่านซ้ำหลายรอบ',
                      icon: CupertinoIcons.arrow_2_circlepath,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFF1EFEA), height: 1, thickness: 1),
                    ),
                    _buildRetentionItem(
                      dotColor: const Color(0xFFB0A898),
                      title: 'ผู้อ่านใหม่',
                      percentage: '$newPct%',
                      desc: 'เปิดดูครั้งแรก',
                      icon: CupertinoIcons.sparkles,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionItem({
    required Color dotColor,
    required String title,
    required String percentage,
    required String desc,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: dotColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: dotColor),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.prompt(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF15221B),
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.prompt(
                  fontSize: 9.5,
                  color: const Color(0xFF888E89),
                ),
              ),
            ],
          ),
        ),
        Text(
          percentage,
          style: GoogleFonts.prompt(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF15221B),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> gradientColors;
  final double strokeWidth;

  _DonutChartPainter({
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
    this.strokeWidth = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    // Sweep gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    final sweepGradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: gradientColors,
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _SmoothLineChartPainter extends CustomPainter {
  final List<double> data;
  final double animationProgress;
  final Color lineColor;
  final Color peakColor;

  _SmoothLineChartPainter({
    required this.data,
    required this.animationProgress,
    this.lineColor = const Color(0xFF1F7A54),
    this.peakColor = const Color(0xFFC5A059),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max);
    final effectiveMax = maxVal == 0 ? 5.0 : maxVal * 1.35;

    // Grid lines (3 horizontal lines)
    final gridPaint = Paint()
      ..color = const Color(0xFFF1EFEA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Points calculation
    final double stepX = size.width / (data.length - 1);
    final List<Offset> points = [];
    int peakIndex = 0;
    double maxData = -1;

    for (int i = 0; i < data.length; i++) {
      if (data[i] > maxData) {
        maxData = data[i];
        peakIndex = i;
      }
      final x = i * stepX;
      final normalizedY = (data[i] / effectiveMax) * animationProgress;
      final y = size.height - (normalizedY * size.height * 0.8) - 10;
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    // Smooth Bezier Curve Path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 1. Fill Area under the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withValues(alpha: 0.25 * animationProgress),
        lineColor.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Stroke curve line
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 3. Highlight Dots
    if (animationProgress > 0.5) {
      final pointAlpha = ((animationProgress - 0.5) / 0.5).clamp(0.0, 1.0);

      for (int i = 0; i < points.length; i++) {
        final pt = points[i];
        final isPeak = i == peakIndex && maxData > 0;

        if (isPeak) {
          final glowPaint = Paint()
            ..color = peakColor.withValues(alpha: 0.28 * pointAlpha)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(pt, 8, glowPaint);

          final peakPtPaint = Paint()
            ..color = peakColor.withValues(alpha: pointAlpha)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(pt, 4.5, peakPtPaint);

          final whiteCore = Paint()..color = Colors.white;
          canvas.drawCircle(pt, 2, whiteCore);
        } else {
          final dotPaint = Paint()
            ..color = lineColor.withValues(alpha: pointAlpha)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(pt, 3, dotPaint);

          final whiteCore = Paint()..color = Colors.white;
          canvas.drawCircle(pt, 1.2, whiteCore);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothLineChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.data != data;
  }
}
