import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../models/catalog_model.dart';
import '../services/catalog_service.dart';
import '../services/api_service.dart';
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

  Future<void> _pickAndUploadPdf() async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final rawName = file.name;
      final defaultTitle = rawName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      final sizeBytes = file.size;
      final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);

      if (!mounted) return;

      final titleCtrl = TextEditingController(text: defaultTitle);
      bool isUploading = false;
      double progress = 0.0;
      String statusText = 'พร้อมอัปโหลดเข้าสู่คลาวด์ 3D';

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFBF8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCD8CC),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'เพิ่มสมุดแค็ตตาล็อกใหม่',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF17221C),
                      ),
                    ),
                    if (!isUploading)
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFFC7C2B4), size: 24),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2DFD5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F7A54).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(CupertinoIcons.doc_fill, color: Color(0xFF1F7A54), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rawName,
                              style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ขนาดไฟล์: $sizeMb MB • ไฟล์ PDF แท้',
                              style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF6E746F)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'ชื่อสมุดที่ต้องการแสดง (แก้ไขได้):',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF17221C),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  enabled: !isUploading,
                  decoration: InputDecoration(
                    hintText: defaultTitle,
                    hintStyle: GoogleFonts.prompt(color: const Color(0xFF9E9B90), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2DFD5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2DFD5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1F7A54), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  style: GoogleFonts.prompt(fontSize: 13.5, color: const Color(0xFF17221C)),
                ),
                const SizedBox(height: 16),
                if (isUploading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8E4DB),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F7A54)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusText,
                    style: GoogleFonts.prompt(fontSize: 11.5, color: const Color(0xFF1F7A54), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            final chosenTitle = titleCtrl.text.trim().isNotEmpty
                                ? titleCtrl.text.trim()
                                : defaultTitle;
                            setModalState(() {
                              isUploading = true;
                              progress = 0.2;
                              statusText = 'กำลังส่งไฟล์เข้าสู่คลาวด์ Cloudflare R2...';
                            });

                            final uploadRes = await PedebookApiService.uploadPdfFile(
                              filePath: file.path,
                              fileBytes: file.bytes,
                              fileName: rawName,
                            );

                            if (uploadRes == null || uploadRes['url'] == null) {
                              setModalState(() {
                                isUploading = false;
                                statusText = 'อัปโหลดไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
                              });
                              return;
                            }

                            setModalState(() {
                              progress = 0.8;
                              statusText = 'กำลังสร้างสมุด 3D Flipbook...';
                            });

                            final newCatalog = await PedebookApiService.createCatalog(
                              title: chosenTitle,
                              fileName: rawName,
                              pdfUrl: uploadRes['url'] as String,
                              storageKey: uploadRes['key'] as String,
                              fileSizeBytes: sizeBytes,
                            );

                            setModalState(() {
                              progress = 1.0;
                              statusText = 'สำเร็จ!';
                            });

                            await Future.delayed(const Duration(milliseconds: 400));
                            if (ctx.mounted) Navigator.pop(ctx);

                            if (mounted) {
                              if (newCatalog != null) {
                                setState(() {
                                  _allCatalogs.insert(0, newCatalog);
                                  _filterCatalogs();
                                });
                              } else {
                                _loadCatalogs();
                              }

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'เพิ่ม "$chosenTitle" สำเร็จแล้ว พร้อมเปิดอ่าน 3D!',
                                          style: GoogleFonts.prompt(fontSize: 12.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF1B2820),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2820),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      isUploading ? 'กำลังประมวลผล 3D...' : 'ยืนยัน & เริ่มแปลงเป็น 3D Flipbook',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Pick file error: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกไฟล์ได้: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
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
      backgroundColor: const Color(0xFFFBFBF8),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF1B2820),
          onRefresh: _loadCatalogs,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── 1. Top Bar: Official Pedebook Logo + Refined Status Pill ──
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
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: const Color(0xFF15221B),
                        ),
                      ),
                      const Spacer(),
                      // Elegant Cloud Sync Status Pill (เล็ก กระชับ เขียวๆ เทาๆ)
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
                              'Cloud Sync',
                              style: GoogleFonts.prompt(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF435A4D),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Refresh Button (เล็ก กระชับ เข้าชุดกัน)
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
                          onPressed: _loadCatalogs,
                          icon: const Icon(CupertinoIcons.arrow_clockwise, size: 13),
                          color: const Color(0xFF435A4D),
                          tooltip: 'รีเฟรชข้อมูลล่าสุด',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Compact iOS Search Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1EC),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFE6E3DA), width: 0.8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _filterCatalogs();
                        });
                      },
                      style: GoogleFonts.prompt(fontSize: 13, color: const Color(0xFF15221B)),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาสมุดแค็ตตาล็อก...',
                        hintStyle: GoogleFonts.prompt(fontSize: 12.5, color: const Color(0xFFA0A5A0)),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 16, color: Color(0xFF8F958F)),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. Section Title with Book Count & Storage Pills ──
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
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15221B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unified Count & Size Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFECE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_allCatalogs.length} เล่ม • $totalSizeMB MB',
                              style: GoogleFonts.prompt(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5A635D),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Quick Header Action Button: [+ เพิ่มสมุด]
                          InkWell(
                            onTap: _pickAndUploadPdf,
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2820),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.plus, size: 11, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(
                                    'เพิ่มสมุด',
                                    style: GoogleFonts.prompt(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'จัดการและเผยแพร่สมุดดิจิทัล 3D Flipbook ของคุณ',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: const Color(0xFF757C76),
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

  /// ── Refined Studio "+ เพิ่มสมุดใหม่" Drop Card ──
  Widget _buildAddCatalogCard() {
    return InkWell(
      onTap: _pickAndUploadPdf,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFDDD9CF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2820).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF5F0),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.arrow_up_doc_fill,
                  color: Color(0xFF1F7A54),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '+ เพิ่มสมุดใหม่',
              style: GoogleFonts.prompt(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF15221B),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              'แตะเพื่อเลือกไฟล์ PDF\nหรือลากไฟล์มาวางตรงนี้',
              style: GoogleFonts.prompt(
                fontSize: 10.5,
                color: const Color(0xFF6E746F),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF5F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF1F7A54)),
                  const SizedBox(width: 3),
                  Text(
                    'ไม่จำกัดขนาดไฟล์',
                    style: GoogleFonts.prompt(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B6B48),
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
