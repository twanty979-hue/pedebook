import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catalog_model.dart';
import '../services/catalog_service.dart';
import '../widgets/catalog_card.dart';
import '../widgets/pedebook_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CatalogItem> _allCatalogs = [];
  List<CatalogItem> _filteredCatalogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    setState(() => _isLoading = true);
    final list = await CatalogService.getUserCatalogs();
    if (mounted) {
      setState(() {
        _allCatalogs = list;
        _filterCatalogs();
        _isLoading = false;
      });
    }
  }

  void _filterCatalogs() {
    if (_searchQuery.trim().isEmpty) {
      _filteredCatalogs = List.from(_allCatalogs);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredCatalogs = _allCatalogs.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.fileName.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _openUploadWeb() async {
    final uri = Uri.parse('https://www.pedebook.com/dashboard');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth >= 900
        ? 4
        : (screenWidth >= 600 ? 3 : 2);

    final totalSizeBytes = _allCatalogs.fold<int>(0, (sum, c) => sum + c.fileSizeBytes);
    final totalSizeMB = (totalSizeBytes / (1024 * 1024)).toStringAsFixed(1);

    // Grid item count: filtered catalogs + Add Book card (if not searching)
    final showAddCard = _searchQuery.trim().isEmpty;
    final totalItems = _filteredCatalogs.length + (showAddCard ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      // ── Floating Action Button (สร้างสมุดใหม่ / อัปโหลด PDF) ──
      floatingActionButton: FloatingActionButton(
        onPressed: _openUploadWeb,
        backgroundColor: const Color(0xFF243129),
        foregroundColor: const Color(0xFFF7F5F0),
        elevation: 6,
        shape: const CircleBorder(),
        tooltip: 'สร้างสมุดใหม่ / อัปโหลด PDF',
        child: const Icon(CupertinoIcons.plus, size: 28),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF243129),
          onRefresh: _loadCatalogs,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── 1. Top Bar: Official Pedebook Logo + Cloud Sync Badge (Matching Web) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      // Retina Pedebook Icon
                      const PedebookLogo(size: 34, borderRadius: 10),
                      const SizedBox(width: 10),
                      // Pedebook Typography
                      Text(
                        'Pedebook',
                        style: GoogleFonts.prompt(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: const Color(0xFF17221C),
                        ),
                      ),
                      const Spacer(),
                      // Cloud Sync Pill Badge (Exact style from screenshot)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Cloud Sync',
                              style: GoogleFonts.prompt(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Refresh Button
                      IconButton(
                        onPressed: _loadCatalogs,
                        icon: const Icon(CupertinoIcons.arrow_clockwise, size: 19),
                        color: const Color(0xFF243129),
                        tooltip: 'รีเฟรชข้อมูลล่าสุด',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Compact iOS Search Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E2D9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _filterCatalogs();
                        });
                      },
                      style: GoogleFonts.prompt(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาสมุดแค็ตตาล็อก...',
                        hintStyle: GoogleFonts.prompt(fontSize: 12.5, color: Colors.grey.shade400),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 16, color: Color(0xFF9E9D97)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 15, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _filterCatalogs();
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. Section Title with Book Count & Storage Pills (Exact Web Dashboard Style) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'แค็ตตาล็อกของฉัน',
                            style: GoogleFonts.prompt(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF17221C),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFECE6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_allCatalogs.length} เล่ม',
                              style: GoogleFonts.prompt(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Size badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFECE6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$totalSizeMB MB',
                              style: GoogleFonts.prompt(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'จัดการและเผยแพร่สมุดดิจิทัล 3D Flipbook ของคุณ',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: const Color(0xFF6E746F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 4. Responsive Grid: Book Cards + Dashed Add Book Card ──
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 14),
                    ),
                  ),
                )
              else if (_filteredCatalogs.isEmpty && !showAddCard)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(CupertinoIcons.book, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'ไม่พบสมุดที่ค้นหา',
                            style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _filteredCatalogs.length) {
                          return CatalogCard(
                            catalog: _filteredCatalogs[index],
                            onDeleted: _loadCatalogs,
                          );
                        } else {
                          // Dashed Add Book Card
                          return _buildAddCatalogCard();
                        }
                      },
                      childCount: totalItems,
                    ),
                  ),
                ),

              // Bottom Spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ── Exact Dashed "+ เพิ่มสมุดใหม่" Card from Web Dashboard ──
  Widget _buildAddCatalogCard() {
    return InkWell(
      onTap: _openUploadWeb,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD9D7CD),
            width: 1.5,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(CupertinoIcons.plus, color: Color(0xFF10B981), size: 28),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '+ เพิ่มสมุดใหม่',
              style: GoogleFonts.prompt(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF17221C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'คลิกเพื่อเลือกไฟล์ หรือลากไฟล์ PDF มาวางตรงนี้',
              style: GoogleFonts.prompt(
                fontSize: 10.5,
                color: const Color(0xFF6E746F),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF065F46)),
                  const SizedBox(width: 3),
                  Text(
                    'ไม่จำกัดขนาดไฟล์',
                    style: GoogleFonts.prompt(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
