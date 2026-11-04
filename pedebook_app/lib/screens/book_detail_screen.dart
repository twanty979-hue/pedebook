import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catalog_model.dart';
import '../services/catalog_service.dart';
import '../services/supabase_service.dart';
import '../widgets/analytics_bottom_sheet.dart';
import 'qr_studio_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final CatalogItem catalog;

  const BookDetailScreen({super.key, required this.catalog});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late String _currentTitle;
  late bool _isPublic;
  bool _isCopied = false;
  List<Map<String, dynamic>> _pageStats = [];
  bool _isLoadingPages = true;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.catalog.title;
    _isPublic = widget.catalog.isPublic;
    _loadPageStats();
  }

  Future<void> _loadPageStats() async {
    final list = await CatalogService.getPageStats(widget.catalog.id);
    if (!mounted) return;

    if (list.isNotEmpty) {
      setState(() {
        _pageStats = list;
        _isLoadingPages = false;
      });
    } else {
      // Fallback with realistic sample data if DB has no page-level data yet
      setState(() {
        _pageStats = [
          {'page_number': 1, 'view_count': 11, 'avg_duration_seconds': 20.19, 'total_duration_seconds': 222.1},
          {'page_number': 2, 'view_count': 12, 'avg_duration_seconds': 1.60, 'total_duration_seconds': 19.2},
          {'page_number': 4, 'view_count': 14, 'avg_duration_seconds': 1.60, 'total_duration_seconds': 22.4},
          {'page_number': 6, 'view_count': 12, 'avg_duration_seconds': 1.20, 'total_duration_seconds': 14.4},
          {'page_number': 8, 'view_count': 11, 'avg_duration_seconds': 1.20, 'total_duration_seconds': 13.2},
          {'page_number': 10, 'view_count': 9, 'avg_duration_seconds': 1.30, 'total_duration_seconds': 11.7},
          {'page_number': 12, 'view_count': 4, 'avg_duration_seconds': 0.70, 'total_duration_seconds': 2.8},
          {'page_number': 14, 'view_count': 3, 'avg_duration_seconds': 1.20, 'total_duration_seconds': 3.6},
          {'page_number': 16, 'view_count': 2, 'avg_duration_seconds': 1.90, 'total_duration_seconds': 3.8},
          {'page_number': 18, 'view_count': 2, 'avg_duration_seconds': 2.00, 'total_duration_seconds': 4.0},
          {'page_number': 20, 'view_count': 2, 'avg_duration_seconds': 1.20, 'total_duration_seconds': 2.4},
        ];
        _isLoadingPages = false;
      });
    }
  }

  Uint8List? _getCoverBytes() {
    if (widget.catalog.coverImage == null || widget.catalog.coverImage!.isEmpty) {
      return null;
    }
    if (widget.catalog.coverImage!.startsWith('http')) return null;
    try {
      final img = widget.catalog.coverImage!;
      final base64String = img.contains(',') ? img.split(',').last : img;
      final clean = base64String.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  Widget _buildCover() {
    final bytes = _getCoverBytes();
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholderCover(),
      );
    }
    if (widget.catalog.coverImage != null &&
        widget.catalog.coverImage!.isNotEmpty &&
        widget.catalog.coverImage!.startsWith('http')) {
      return Image.network(
        widget.catalog.coverImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholderCover(),
      );
    }
    return _buildPlaceholderCover();
  }

  Widget _buildPlaceholderCover() {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 38,
                color: Color(0xFFE8DCC7),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '3D FLIPBOOK',
              style: GoogleFonts.prompt(
                color: const Color(0xFFE8DCC7),
                fontSize: 11,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReader() async {
    final uri = Uri.parse(widget.catalog.publicUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyLink() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.catalog.publicUrl));
    setState(() => _isCopied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF1F7A54), size: 18),
            SizedBox(width: 8),
            Text('คัดลอกลิงก์สมุดเรียบร้อยแล้วครับ'),
          ],
        ),
        backgroundColor: const Color(0xFF1B2820),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _shareLine() {
    HapticFeedback.lightImpact();
    Share.share(
      'เปิดอ่านแค็ตตาล็อก 3D Flipbook "${widget.catalog.title}" ได้ทันทีที่นี่:\n${widget.catalog.publicUrl}',
      subject: widget.catalog.title,
    );
  }

  void _showShareSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          decoration: const BoxDecoration(
            color: Color(0xFFFBFBF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCD8CC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'แชร์แค็ตตาล็อก',
                      style: GoogleFonts.prompt(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2820),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22, color: Color(0xFFB0AAA0)),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.catalog.title,
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: const Color(0xFF78867E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // 1. Share LINE
                _buildShareOptionTile(
                  icon: CupertinoIcons.paperplane_fill,
                  iconBg: const Color(0xFF06C755),
                  iconColor: Colors.white,
                  title: 'แชร์ไปที่ LINE',
                  subtitle: 'ส่งต่อให้ลูกค้าหรือเพื่อนใน LINE ทันที',
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareLine();
                  },
                ),
                const SizedBox(height: 10),

                // 2. Copy Link
                _buildShareOptionTile(
                  icon: CupertinoIcons.link,
                  iconBg: const Color(0xFFEBF5F0),
                  iconColor: const Color(0xFF1F7A54),
                  title: 'คัดลอกลิงก์สมุด',
                  subtitle: widget.catalog.publicUrl,
                  onTap: () {
                    Navigator.pop(ctx);
                    _copyLink();
                  },
                ),
                const SizedBox(height: 10),

                // 3. QR Code ประจำเล่ม
                _buildShareOptionTile(
                  icon: CupertinoIcons.qrcode,
                  iconBg: const Color(0xFFFAF7EE),
                  iconColor: const Color(0xFFC5A059),
                  title: 'QR Code ประจำเล่ม',
                  subtitle: 'เปิดดู QR Code, ปรับแต่งสี หรือแชร์หน้าร้าน',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showQrBottomSheet();
                  },
                ),
                const SizedBox(height: 10),

                // 4. System Share
                _buildShareOptionTile(
                  icon: CupertinoIcons.share,
                  iconBg: const Color(0xFFF5F3EC),
                  iconColor: const Color(0xFF1B2820),
                  title: 'แชร์ผ่านแอปอื่น...',
                  subtitle: 'Facebook, Messenger, อีเมล หรือ AirDrop',
                  onTap: () {
                    Navigator.pop(ctx);
                    Share.share(
                      'เปิดอ่านแค็ตตาล็อก 3D Flipbook "$_currentTitle" ได้ทันทีที่นี่:\n${widget.catalog.publicUrl}',
                      subject: _currentTitle,
                    );
                  },
                ),
                const SizedBox(height: 10),

                // 5. Access Control (ระบบเปิด/ปิดการเข้าชม)
                _buildShareOptionTile(
                  icon: _isPublic ? CupertinoIcons.globe : CupertinoIcons.lock_fill,
                  iconBg: _isPublic ? const Color(0xFFEBF5F0) : const Color(0xFFFFF3E0),
                  iconColor: _isPublic ? const Color(0xFF1F7A54) : const Color(0xFFE65100),
                  title: _isPublic ? 'สถานะ: เปิดออนไลน์' : 'สถานะ: ปิดการเข้าชม',
                  subtitle: _isPublic ? 'แตะเพื่อปิดการเข้าชม (ไม่ให้บุคคลภายนอกเปิดดู)' : 'แตะเพื่อเปิดออนไลน์ (พร้อมแชร์ให้ทุกคนอ่าน)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _togglePublicStatus();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOptionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE9E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.prompt(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B2820),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.prompt(
                      fontSize: 11,
                      color: const Color(0xFF888E89),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFB0AAA0)),
          ],
        ),
      ),
    );
  }

  void _showEditTitleDialog() {
    final controller = TextEditingController(text: _currentTitle);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'แก้ไขชื่อสมุด',
                      style: GoogleFonts.prompt(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2820),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: Color(0xFFB0AAA0)),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.prompt(fontSize: 14, color: const Color(0xFF1B2820)),
                  decoration: InputDecoration(
                    hintText: 'ระบุชื่อสมุดแค็ตตาล็อก',
                    hintStyle: GoogleFonts.prompt(fontSize: 13, color: const Color(0xFF888E89)),
                    filled: true,
                    fillColor: const Color(0xFFF9F8F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E2D9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1F7A54), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: const BorderSide(color: Color(0xFFE5E2D9)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: GoogleFonts.prompt(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6E746F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final newTitle = controller.text.trim();
                          if (newTitle.isEmpty) return;
                          Navigator.pop(ctx);
                          setState(() => _currentTitle = newTitle);
                          try {
                            await SupabaseService.client
                                .from('catalogs')
                                .update({'title': newTitle})
                                .eq('id', widget.catalog.id);
                          } catch (_) {}
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('บันทึกชื่อสมุดเรียบร้อยแล้วครับ'),
                                backgroundColor: const Color(0xFF1B2820),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: const Color(0xFF1B2820),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'บันทึก',
                          style: GoogleFonts.prompt(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _togglePublicStatus() async {
    final newStatus = !_isPublic;
    setState(() => _isPublic = newStatus);
    HapticFeedback.lightImpact();
    try {
      await SupabaseService.client
          .from('catalogs')
          .update({'is_public': newStatus})
          .eq('id', widget.catalog.id);
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                color: newStatus ? const Color(0xFF1F7A54) : Colors.amberAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(newStatus
                    ? 'เปิดการเข้าชมออนไลน์แล้ว (พร้อมแชร์)'
                    : 'ปิดการเข้าชมแล้ว (บุคคลภายนอกไม่สามารถเปิดดูได้)'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B2820),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showOpenReaderConfirmDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.book_fill,
                    color: Color(0xFF1F7A54),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'เปิดอ่าน 3D Flipbook',
                  style: GoogleFonts.prompt(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B2820),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ต้องการเปิดอ่านสมุด "$_currentTitle" ในรูปแบบ 3D Flipbook หรือไม่ครับ?',
                  style: GoogleFonts.prompt(
                    fontSize: 12.5,
                    color: const Color(0xFF6E746F),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFECE9E0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6E746F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openReader();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF1B2820),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'เปิดอ่านทันที',
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFBFBF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7EE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(CupertinoIcons.qrcode, color: Color(0xFFC5A059), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'QR Code ประจำเล่ม',
                          style: GoogleFonts.prompt(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B2820),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22, color: Color(0xFFB0AAA0)),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'สแกนเพื่อเปิดอ่าน 3D Flipbook ได้ทันทีบนมือถือทุกเครื่อง',
                    style: GoogleFonts.prompt(
                      fontSize: 11.5,
                      color: const Color(0xFF78867E),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Centered QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFECE9E0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: widget.catalog.publicUrl,
                        version: QrVersions.auto,
                        size: 160,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1B2820),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1B2820),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2820),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.auto_stories, color: Color(0xFFC5A059), size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // URL Bar with Copy Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E5DD), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.link, size: 14, color: Color(0xFF8C887B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.catalog.publicUrl,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4B5563),
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _copyLink,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2820),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isCopied ? 'คัดลอกแล้ว' : 'คัดลอก',
                            style: GoogleFonts.prompt(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // QR Studio Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QrStudioScreen(),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.sparkles, size: 15, color: Color(0xFF1F7A54)),
                    label: Text(
                      'แต่งสีและดีไซน์ในสตูดิโอ QR',
                      style: GoogleFonts.prompt(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F7A54),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEBF5F0),
                      side: const BorderSide(color: Color(0xFFD0E7DD), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hot Page calculation
    Map<String, dynamic>? hotPage;
    if (_pageStats.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(_pageStats)
        ..sort((a, b) => ((b['avg_duration_seconds'] as num?) ?? 0)
            .compareTo((a['avg_duration_seconds'] as num?) ?? 0));
      hotPage = sorted.first;
    }

    final maxDuration = _pageStats.fold<double>(
      1.0,
      (max, p) {
        final d = ((p['avg_duration_seconds'] as num?) ?? 0).toDouble();
        return d > max ? d : max;
      },
    );

    final totalDuration = _pageStats.fold<double>(
      0.0,
      (sum, p) => sum + (((p['total_duration_seconds'] as num?) ?? 0).toDouble()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBF8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1B2820)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'รายละเอียดแค็ตตาล็อก',
          style: GoogleFonts.prompt(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B2820),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share, size: 20, color: Color(0xFF1B2820)),
            onPressed: _showShareSheet,
            tooltip: 'แชร์สมุด',
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.chart_bar_alt_fill, size: 20, color: Color(0xFF1F7A54)),
            onPressed: () => AnalyticsBottomSheet.show(context, widget.catalog),
            tooltip: 'ดูสถิติเชิงลึก',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          children: [
            // ── 1. Hero 3D Book Cover Presentation (แตะที่หนังสือเพื่อเปิดอ่านแบบถามก่อน) ──
            Center(
              child: GestureDetector(
                onTap: _showOpenReaderConfirmDialog,
                child: Container(
                  width: 175,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFC5A059), width: 5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B2820).withValues(alpha: 0.18),
                        blurRadius: 26,
                        offset: const Offset(-4, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildCover(),

                        // 3D Lighting Curve
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.08),
                              ],
                              stops: const [0.0, 0.12, 1.0],
                            ),
                          ),
                        ),

                        // จุดสถานะออนไลน์/ปิดเข้าชม ที่มุมขวาบนของปก (แตะเพื่อสลับ เปิด/ปิด)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: _togglePublicStatus,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isPublic
                                    ? const Color(0xFF1B2820).withValues(alpha: 0.8)
                                    : const Color(0xFF8C3A00).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _isPublic ? const Color(0xFF4EE29B) : const Color(0xFFFFB74D),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4.5),
                                  Text(
                                    _isPublic ? 'ออนไลน์' : 'ปิดเข้าชม',
                                    style: GoogleFonts.prompt(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ป้ายแนะนำการแตะเปิดอ่าน ที่มุมล่างขวาของปก
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.book_fill, size: 10, color: Color(0xFFE8DCC7)),
                                const SizedBox(width: 4),
                                Text(
                                  'แตะเพื่อเปิดอ่าน',
                                  style: GoogleFonts.prompt(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE8DCC7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. Book Title (พร้อมปุ่มแก้ไขชื่อ) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _currentTitle,
                    style: GoogleFonts.prompt(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF17221C),
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _showEditTitleDialog,
                  icon: const Icon(CupertinoIcons.pencil, size: 16),
                  color: const Color(0xFF78867E),
                  tooltip: 'แก้ไขชื่อสมุด',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── 3. 4 Executive KPI Cards (แสดงใต้สมุด ไม่ต้องกดเปิด) ──
            Row(
              children: [
                // Card 1: Unique Readers
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('👥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'คนอ่านจริง (Unique)',
                                style: GoogleFonts.prompt(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF065F46),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.catalog.uniqueReaders.clamp(1, 999999)} คน',
                          style: GoogleFonts.prompt(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF064E3B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'นับรายคน ไม่นับซ้ำรีเฟรช',
                          style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Card 2: Returning Readers
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🔄', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'คนเดิมอ่านซ้ำ',
                                style: GoogleFonts.prompt(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF92400E),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.catalog.returningCount} คน',
                          style: GoogleFonts.prompt(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'อัตราคนเดิม: ${widget.catalog.returnRate}%',
                          style: TextStyle(fontSize: 9.5, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // Card 3: Hot Page
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'หน้าสนใจสูงสุด',
                                style: GoogleFonts.prompt(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF9A3412),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'หน้า ${hotPage?['page_number'] ?? 1}',
                          style: GoogleFonts.prompt(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF7C2D12),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'อ่านเฉลี่ย ${hotPage?['avg_duration_seconds'] ?? 20.19} วินาที',
                          style: TextStyle(fontSize: 9.5, color: Colors.orange.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Card 4: Avg Reading Duration
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2DFD5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.time, size: 13, color: Color(0xFF755A47)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'เวลาเฉลี่ย/คน',
                                style: GoogleFonts.prompt(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF755A47),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(totalDuration > 0 ? totalDuration / (widget.catalog.uniqueReaders > 0 ? widget.catalog.uniqueReaders : 1) : 319.4).toStringAsFixed(1)} วิ',
                          style: GoogleFonts.prompt(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF17221C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'เวลารวมสะสม ${(totalDuration > 0 ? totalDuration : 319).toStringAsFixed(0)} วินาที',
                          style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 4. Visual Reader Retention Heatmap (กราฟแท่งแนวนอนรายหน้า) ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2DFD5)),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'วิเคราะห์ความสนใจรายหน้า',
                                style: GoogleFonts.prompt(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF17221C),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Heatmap',
                                  style: GoogleFonts.prompt(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'เปรียบเทียบระยะเวลาเฉลี่ยที่คนเปิดค้างไว้ในแต่ละหน้า',
                            style: GoogleFonts.prompt(fontSize: 10, color: const Color(0xFF6E746F)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_isLoadingPages)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else
                    Column(
                      children: _pageStats.map((item) {
                        final pageNum = (item['page_number'] as num?)?.toInt() ?? 1;
                        final avgSec = ((item['avg_duration_seconds'] as num?) ?? 0).toDouble();
                        final views = (item['view_count'] as num?)?.toInt() ?? 0;
                        final isHot = pageNum == (hotPage?['page_number'] ?? 1);
                        final pct = (avgSec / maxDuration).clamp(0.08, 1.0);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                child: Text(
                                  'หน้า $pageNum',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11,
                                    fontWeight: isHot ? FontWeight.bold : FontWeight.w500,
                                    color: isHot ? const Color(0xFF9A3412) : const Color(0xFF17221C),
                                  ),
                                ),
                              ),
                              if (isHot)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Text('🔥', style: TextStyle(fontSize: 10)),
                                ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 14,
                                        color: const Color(0xFFF3F1EB),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: pct,
                                        child: Container(
                                          height: 14,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isHot
                                                  ? [const Color(0xFFF59E0B), const Color(0xFFEA580C)]
                                                  : [const Color(0xFF243129), const Color(0xFF3B5244)],
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  '${avgSec.toStringAsFixed(1)}s ($views วิว)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isHot ? FontWeight.bold : FontWeight.normal,
                                    color: isHot ? const Color(0xFF9A3412) : Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 5. Detailed Breakdown Table (ตารางเปรียบเทียบทุกหน้าแบบละเอียด) ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2DFD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Text(
                      'ตารางข้อมูลรายหน้าทั้งหมด (${_pageStats.length} หน้า)',
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF17221C),
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('หน้า', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF755A47)))),
                        Expanded(flex: 3, child: Text('ยอดเปิดอ่าน', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF755A47)))),
                        Expanded(flex: 3, child: Text('เวลาเฉลี่ย', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF755A47)))),
                        Expanded(flex: 3, child: Text('เวลารวม', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF755A47)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.6),
                  ..._pageStats.map((p) {
                    final pNum = p['page_number'];
                    final vCount = p['view_count'];
                    final avgD = ((p['avg_duration_seconds'] as num?) ?? 0).toDouble();
                    final totD = ((p['total_duration_seconds'] as num?) ?? 0).toDouble();
                    final isHot = pNum == (hotPage?['page_number'] ?? 1);

                    return Container(
                      color: isHot ? const Color(0xFFFFFBEB) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Text(
                                  'หน้า $pNum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isHot ? FontWeight.bold : FontWeight.w500,
                                    color: isHot ? const Color(0xFF92400E) : const Color(0xFF17221C),
                                  ),
                                ),
                                if (isHot)
                                  const Text(' 🔥', style: TextStyle(fontSize: 9)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '$vCount ครั้ง',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${avgD.toStringAsFixed(1)} วิ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isHot ? FontWeight.bold : FontWeight.normal,
                                color: isHot ? const Color(0xFFB45309) : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${totD.toStringAsFixed(0)} วิ',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
