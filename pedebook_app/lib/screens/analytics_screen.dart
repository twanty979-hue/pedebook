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
      backgroundColor: const Color(0xFFF8F7F3),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : RefreshIndicator(
                color: const Color(0xFF243129),
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── 1. Compact iOS Top Bar ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'สถิติผู้อ่าน',
                              style: GoogleFonts.prompt(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF17221C),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'เรียลไทม์',
                                        style: GoogleFonts.prompt(
                                          color: const Color(0xFF065F46),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _loadData,
                                  icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                                  color: const Color(0xFF243129),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── 2. Unified Compact Executive Card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E2D9), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 4 Stats in 1 Row
                              Row(
                                children: [
                                  _buildCompactStat(
                                    value: '$totalViews',
                                    label: 'ยอดเปิดอ่าน',
                                    color: const Color(0xFF243129),
                                  ),
                                  _buildVerticalDivider(),
                                  _buildCompactStat(
                                    value: '${totalUnique.clamp(1, 9999)}',
                                    label: 'คนอ่านจริง',
                                    color: const Color(0xFF10B981),
                                  ),
                                  _buildVerticalDivider(),
                                  _buildCompactStat(
                                    value: '$avgViews',
                                    label: 'เฉลี่ย/เล่ม',
                                    color: const Color(0xFF755A47),
                                  ),
                                  _buildVerticalDivider(),
                                  _buildCompactStat(
                                    value: '${_catalogs.length}',
                                    label: 'สมุดทั้งหมด',
                                    color: const Color(0xFF17221C),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, thickness: 0.8),
                              const SizedBox(height: 10),

                              // Returning Readers Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ผู้อ่านใหม่ vs ผู้อ่านเดิม (New vs Returning)',
                                    style: GoogleFonts.prompt(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF17221C),
                                    ),
                                  ),
                                  Text(
                                    'คนเดิม $returningPct%',
                                    style: GoogleFonts.prompt(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: newPct,
                                      child: Container(height: 6, color: const Color(0xFF10B981)),
                                    ),
                                    Expanded(
                                      flex: returningPct,
                                      child: Container(height: 6, color: const Color(0xFF243129)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '🌱 ผู้อ่านใหม่: $newPct%',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    '🔄 กลับมาอ่านซ้ำ: $returningPct%',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // ── 3. Section Header: ประสิทธิภาพรายเล่ม ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ประสิทธิภาพรายเล่ม (เปิดอ่านมากที่สุด)',
                          style: GoogleFonts.prompt(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF17221C),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // ── 4. Catalog Leaderboard with Real 3D Book Cover ──
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                            final item = _catalogs[idx];
                            final ratio = totalViews > 0 ? (item.totalViews / totalViews) : 0.0;

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
                                    border: Border.all(color: const Color(0xFFE5E2D9)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // ── ปกหนังสือ 3D สมจริงตามแบบหน้าแรก พร้อมป้ายอันดับ #1 ──
                                          _buildCoverThumbnail(item, idx),
                                          const SizedBox(width: 12),

                                          // ชื่อเรื่อง & ขนาดไฟล์
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: GoogleFonts.prompt(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF17221C),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'ขนาด: ${item.formattedSize}',
                                                  style: GoogleFonts.prompt(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // ยอดวิว & คนอ่าน
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${item.totalViews} วิว',
                                                style: GoogleFonts.prompt(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF17221C),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.uniqueReaders.clamp(1, 999999)} คนอ่าน',
                                                style: GoogleFonts.prompt(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // แถบ Progress แสดงสัดส่วนยอดเข้าชม
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: ratio.toDouble().clamp(0.04, 1.0),
                                          backgroundColor: const Color(0xFFF0EFE9),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            idx == 0 ? const Color(0xFF10B981) : const Color(0xFF243129),
                                          ),
                                          minHeight: 4,
                                        ),
                                      ),
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

  Widget _buildCompactStat({
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.grey.shade200,
    );
  }
}
