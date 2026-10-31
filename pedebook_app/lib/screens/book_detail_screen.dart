import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catalog_model.dart';
import '../widgets/analytics_bottom_sheet.dart';
import 'qr_studio_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final CatalogItem catalog;

  const BookDetailScreen({super.key, required this.catalog});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isCopied = false;

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
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Text('คัดลอกลิงก์สมุดเรียบร้อยแล้วครับ'),
          ],
        ),
        backgroundColor: const Color(0xFF17221C),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F4EE),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF17221C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'รายละเอียดแค็ตตาล็อก',
          style: GoogleFonts.prompt(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF17221C),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share, size: 20, color: Color(0xFF17221C)),
            onPressed: _shareLine,
            tooltip: 'แชร์สมุด',
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.chart_bar_alt_fill, size: 20, color: Color(0xFF10B981)),
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
            // ── 1. Hero 3D Book Cover Presentation (จุดเด่นสง่างามกลางจอ) ──
            Center(
              child: Container(
                width: 175,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF9A7257), width: 5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF243129).withValues(alpha: 0.28),
                      blurRadius: 26,
                      offset: const Offset(-6, 14),
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── 2. Book Title, Status & File Info ──
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.catalog.title,
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
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ออนไลน์ (พร้อมแชร์)',
                            style: GoogleFonts.prompt(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.catalog.fileName,
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 3. Primary CTA: [ 📖 เปิดอ่านแบบ 3D Flipbook ทันที ] ──
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _openReader,
                icon: const Icon(CupertinoIcons.book_fill, size: 18, color: Color(0xFF10B981)),
                label: Text(
                  'เปิดอ่านแบบ 3D Flipbook ทันที',
                  style: GoogleFonts.prompt(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17221C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyLink,
                    icon: Icon(
                      _isCopied ? CupertinoIcons.checkmark_alt : CupertinoIcons.link,
                      size: 14,
                      color: _isCopied ? const Color(0xFF10B981) : const Color(0xFF17221C),
                    ),
                    label: Text(
                      _isCopied ? 'คัดลอกแล้ว' : 'คัดลอกลิงก์',
                      style: GoogleFonts.prompt(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF17221C),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD9D7CD), width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareLine,
                    icon: const Icon(CupertinoIcons.paperplane_fill, size: 14, color: Color(0xFF06C755)),
                    label: Text(
                      'แชร์ LINE',
                      style: GoogleFonts.prompt(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF17221C),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD9D7CD), width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AnalyticsBottomSheet.show(context, widget.catalog),
                    icon: const Icon(CupertinoIcons.chart_bar_alt_fill, size: 14, color: Color(0xFF059669)),
                    label: Text(
                      'ดูสถิติ',
                      style: GoogleFonts.prompt(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF17221C),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD9D7CD), width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── 4. Executive Metric Summary Strip (4 คอลัมน์คมชัด) ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2DFD5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildMetricCell(
                    value: '${widget.catalog.totalViews}',
                    label: 'ยอดวิวเปิดอ่าน',
                    color: const Color(0xFF17221C),
                  ),
                  _buildVerticalDivider(),
                  _buildMetricCell(
                    value: '${widget.catalog.uniqueReaders.clamp(1, 999999)}',
                    label: 'คนอ่านจริง',
                    color: const Color(0xFF059669),
                  ),
                  _buildVerticalDivider(),
                  _buildMetricCell(
                    value: widget.catalog.formattedSize,
                    label: 'ขนาดไฟล์ PDF',
                    color: const Color(0xFF755A47),
                  ),
                  _buildVerticalDivider(),
                  _buildMetricCell(
                    value: '${widget.catalog.pageCount > 0 ? widget.catalog.pageCount : 11}',
                    label: 'จำนวนหน้า',
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 5. Compact Luxury QR Code Card (ขนาดสมดุล สวยงาม ไม่กินทั้งจอ) ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2DFD5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Compact 100x100 QR Code with Pedebook logo overlay
                      Container(
                        width: 106,
                        height: 106,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E2D9), width: 1),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            QrImageView(
                              data: widget.catalog.publicUrl,
                              version: QrVersions.auto,
                              size: 92,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF17221C),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF17221C),
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF243129),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Center(
                                child: Icon(Icons.auto_stories, color: Color(0xFFC5A059), size: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Info & Studio Button
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QR Code ประจำเล่ม',
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF17221C),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'สแกนเปิดอ่านได้ทันทีบนมือถือ หรือพิมพ์ติดหน้าร้าน',
                              style: GoogleFonts.prompt(
                                fontSize: 11,
                                color: const Color(0xFF6E746F),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 32,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const QrStudioScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(CupertinoIcons.sparkles, size: 13, color: Color(0xFF755A47)),
                                label: Text(
                                  'แต่งสีในสตูดิโอ QR',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF755A47),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFAF9F5),
                                  side: const BorderSide(color: Color(0xFFD9D7CD), width: 1),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // URL Box with one-tap copy
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E2D9), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.link, size: 14, color: Color(0xFF9E9D97)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF17221C),
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
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell({
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6E746F),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE5E2D9),
    );
  }
}
