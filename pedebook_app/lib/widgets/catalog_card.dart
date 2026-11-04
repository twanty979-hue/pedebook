import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catalog_model.dart';
import '../screens/book_detail_screen.dart';
import '../screens/qr_studio_screen.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'analytics_bottom_sheet.dart';
import 'share_bottom_sheet.dart';

class CatalogCard extends StatefulWidget {
  final CatalogItem catalog;
  final VoidCallback? onDeleted;

  const CatalogCard({super.key, required this.catalog, this.onDeleted});

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
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

  /// ── Exact 3D Luxury Hardcover Fallback from pedebook.com ──
  Widget _buildLuxuryWebCover() {
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
      child: Stack(
        children: [
          // Left Gold Spine Strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 7,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF7A5836),
                    const Color(0xFFC5A059),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),

          // Gold Foil Border Frame
          Positioned.fill(
            left: 9,
            top: 7,
            right: 7,
            bottom: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFC5A059).withValues(alpha: 0.45),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gold Pedebook Emblem at Top
                  Column(
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        size: 15,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'PEDEBOOK',
                        style: GoogleFonts.prompt(
                          fontSize: 7,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC5A059),
                        ),
                      ),
                    ],
                  ),

                  // Book Title in Serif Font
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.catalog.title,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF5EEDB),
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Digital Edition Badge at Bottom
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 1,
                        color: const Color(0xFFC5A059).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'DIGITAL EDITION',
                        style: GoogleFonts.prompt(
                          fontSize: 6,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC5A059).withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3D Lighting Curve Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverContent() {
    final bytes = _getCoverBytes();
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildLuxuryWebCover(),
      );
    }
    if (widget.catalog.coverImage != null &&
        widget.catalog.coverImage!.isNotEmpty &&
        widget.catalog.coverImage!.startsWith('http')) {
      return Image.network(
        widget.catalog.coverImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildLuxuryWebCover(),
      );
    }
    return _buildLuxuryWebCover();
  }

  Future<void> _openReader() async {
    final uri = Uri.parse(widget.catalog.publicUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(catalog: widget.catalog),
      ),
    );
  }

  Future<void> _replaceFile() async {
    final uri = Uri.parse('https://www.pedebook.com/dashboard');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static const List<Map<String, dynamic>> _modalThemes = [
    {
      'id': 'auto',
      'name': 'ไล่สี',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDE68A), Color(0xFFFECDD3), Color(0xFFA7F3D0)],
      ),
    },
    {
      'id': 'cream',
      'name': 'ครีมสตูดิโอ',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF6F4EE), Color(0xFFD8D4C7)],
      ),
    },
    {
      'id': 'warm',
      'name': 'ดินเผา',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDFC2AC), Color(0xFFA7836B)],
      ),
    },
    {
      'id': 'forest',
      'name': 'เขียวป่า',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF243129), Color(0xFF121915)],
      ),
    },
    {
      'id': 'slate',
      'name': 'หินชนวนดำ',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E2022), Color(0xFF111215)],
      ),
    },
    {
      'id': 'linen',
      'name': 'ผ้าลินิน',
      'gradient': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE2DFD5), Color(0xFFD5D1C5)],
      ),
    },
  ];

  Future<void> _saveDecorationPreferences(String theme, bool isFloating) async {
    final bgType = theme == 'auto' ? 'gradient' : 'default';
    final bgValue = theme;
    try {
      // 1. Sync directly to Supabase
      await SupabaseService.client.from('catalogs').update({
        'bg_type': bgType,
        'bg_value': bgValue,
        'is_floating': isFloating,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.catalog.id);
    } catch (e) {
      debugPrint('Save decoration via Supabase error: $e');
    }

    try {
      // 2. Also sync to Web API (triggers cache clear and supabaseAdmin sync)
      await PedebookApiService.updateCatalogDecoration(
        catalogId: widget.catalog.id,
        bgType: bgType,
        bgValue: bgValue,
        isFloating: isFloating,
      );
    } catch (e) {
      debugPrint('Save decoration via Web API error: $e');
    }
  }

  Widget _buildCompactBottomButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 33,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9D7CD), width: 0.9),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17221C).withValues(alpha: 0.03),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 3.5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.prompt(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? const Color(0xFF17221C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalMetricBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E2D9), width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.prompt(
                    fontSize: 9.5,
                    color: const Color(0xFF6E746F),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF17221C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapMiniRow(String pageLabel, String duration, double ratio) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            pageLabel,
            style: GoogleFonts.prompt(fontSize: 10, color: const Color(0xFF17221C), fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E2D9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          duration,
          style: GoogleFonts.prompt(fontSize: 9.5, color: const Color(0xFF6E746F)),
        ),
      ],
    );
  }

  /// ── โมดอลกลางจอพร้อม Live Preview สมุด 3D และตัวตกแต่งทันที (สไตล์สตูดิโอระดับ Executive) ──
  void _showCenterActionsModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    String selectedTheme = widget.catalog.bgValue.isNotEmpty ? widget.catalog.bgValue : 'auto';
    bool isFloating = widget.catalog.isFloating;
    bool modalCopied = false;
    String modalView = 'main'; // 'main', 'qr', 'analytics', 'delete'

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final activeTheme = _modalThemes.firstWhere(
            (t) => t['id'] == selectedTheme,
            orElse: () => _modalThemes[0],
          );
          final activeGradient = activeTheme['gradient'] as Gradient;

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                constraints: const BoxConstraints(maxWidth: 405),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2DFD5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF17221C).withValues(alpha: 0.22),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: modalView == 'qr'
                      // ──────────────────────────────────────────
                      // VIEW: QR Code & ลิงก์แชร์ (มีปุ่มย้อนกลับชัดเจน)
                      // ──────────────────────────────────────────
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Back Button (←) and Close Button (X)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                                  color: const Color(0xFF17221C),
                                  tooltip: 'ย้อนกลับ',
                                  onPressed: () => setModalState(() => modalView = 'main'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'QR Code & สแกนอ่าน',
                                        style: GoogleFonts.prompt(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF17221C),
                                        ),
                                      ),
                                      Text(
                                        widget.catalog.title,
                                        style: GoogleFonts.prompt(
                                          fontSize: 10.5,
                                          color: const Color(0xFF6E746F),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  color: Colors.grey.shade500,
                                  onPressed: () => Navigator.pop(ctx),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // QR Code Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBFBF9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E2D9)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: QrImageView(
                                      data: widget.catalog.publicUrl,
                                      version: QrVersions.auto,
                                      size: 165,
                                      gapless: true,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: Color(0xFF17221C),
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: Color(0xFF17221C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 5),
                                      Text(
                                        'ยื่นมือถือให้ลูกค้าสแกนเปิดอ่านได้ทันที',
                                        style: GoogleFonts.prompt(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF17221C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // URL Bar with Copy button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F7F4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E2D9)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.link, size: 13, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.catalog.publicUrl,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF17221C),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Clipboard.setData(ClipboardData(text: widget.catalog.publicUrl));
                                      setModalState(() => modalCopied = true);
                                      Future.delayed(const Duration(seconds: 2), () {
                                        if (ctx.mounted) setModalState(() => modalCopied = false);
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: modalCopied ? const Color(0xFF059669) : Colors.white,
                                        border: Border.all(
                                          color: modalCopied ? const Color(0xFF059669) : const Color(0xFF10B981),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        modalCopied ? 'คัดลอกแล้ว' : 'คัดลอก',
                                        style: GoogleFonts.prompt(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: modalCopied ? Colors.white : const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Actions Row: [🎨 ปรับแต่งสตูดิโอ QR]
                            SizedBox(
                              width: double.infinity,
                              height: 35,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QrStudioScreen(initialCatalog: widget.catalog),
                                    ),
                                  );
                                },
                                icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 13, color: Color(0xFF17221C)),
                                label: Text(
                                  'สตูดิโอปรับแต่งสีและโลโก้ QR Code',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF17221C),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFD9D7CD), width: 1.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Bottom Back Button (ปุ่มย้อนกลับชัดเจน)
                            SizedBox(
                              width: double.infinity,
                              height: 35,
                              child: OutlinedButton.icon(
                                onPressed: () => setModalState(() => modalView = 'main'),
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Color(0xFF17221C)),
                                label: Text(
                                  '← ย้อนกลับไปหน้าจัดการสมุด',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF17221C),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF9F8F5),
                                  side: const BorderSide(color: Color(0xFFE2DFD5), width: 1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        )
                      : modalView == 'analytics'
                          // ──────────────────────────────────────────
                          // VIEW: สถิติผู้อ่านเชิงลึก (มีปุ่มย้อนกลับชัดเจน)
                          // ──────────────────────────────────────────
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with Back Button (←) and Close Button (X)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                                      color: const Color(0xFF17221C),
                                      tooltip: 'ย้อนกลับ',
                                      onPressed: () => setModalState(() => modalView = 'main'),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'สถิติผู้อ่าน (Reader Insights)',
                                            style: GoogleFonts.prompt(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF17221C),
                                            ),
                                          ),
                                          Text(
                                            widget.catalog.title,
                                            style: GoogleFonts.prompt(
                                              fontSize: 10.5,
                                              color: const Color(0xFF6E746F),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      color: Colors.grey.shade500,
                                      onPressed: () => Navigator.pop(ctx),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // 4 Metric Cards Grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModalMetricBox(
                                        icon: CupertinoIcons.person_2_fill,
                                        label: 'คนอ่านจริง (Unique)',
                                        value: '${widget.catalog.uniqueReaders} คน',
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildModalMetricBox(
                                        icon: CupertinoIcons.eye_fill,
                                        label: 'ยอดเปิดอ่านสะสม',
                                        value: '${widget.catalog.totalViews} ครั้ง',
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModalMetricBox(
                                        icon: CupertinoIcons.doc_text_fill,
                                        label: 'ขนาดไฟล์ PDF',
                                        value: widget.catalog.formattedSize,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildModalMetricBox(
                                        icon: CupertinoIcons.arrow_2_circlepath,
                                        label: 'คนเดิมอ่านซ้ำ',
                                        value: '${widget.catalog.returningCount} คน (${widget.catalog.returnRate}%)',
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Page Heatmap Mini Summary
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBFBF9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E2D9)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🔥 หน้าที่คนอ่านสนใจมากที่สุด',
                                        style: GoogleFonts.prompt(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF17221C),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildHeatmapMiniRow('หน้า 1 (หน้าปก)', '3.1 วินาที/คน', 1.0),
                                      const SizedBox(height: 5),
                                      _buildHeatmapMiniRow('หน้า 2 (สารบัญ)', '1.3 วินาที/คน', 0.65),
                                      const SizedBox(height: 5),
                                      _buildHeatmapMiniRow('หน้า 4 (สินค้าเด่น)', '1.8 วินาที/คน', 0.78),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Open Full Analytics Sheet Option
                                SizedBox(
                                  width: double.infinity,
                                  height: 35,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      AnalyticsBottomSheet.show(context, widget.catalog);
                                    },
                                    icon: const Icon(CupertinoIcons.chart_bar_square_fill, size: 14, color: Color(0xFF10B981)),
                                    label: Text(
                                      'ดูสถิติฉบับเต็มพร้อมตารางทุกหน้า',
                                      style: GoogleFonts.prompt(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF17221C),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFFD9D7CD), width: 1.1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Bottom Back Button (ปุ่มย้อนกลับชัดเจน)
                                SizedBox(
                                  width: double.infinity,
                                  height: 35,
                                  child: OutlinedButton.icon(
                                    onPressed: () => setModalState(() => modalView = 'main'),
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Color(0xFF17221C)),
                                    label: Text(
                                      '← ย้อนกลับไปหน้าจัดการสมุด',
                                      style: GoogleFonts.prompt(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF17221C),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF9F8F5),
                                      side: const BorderSide(color: Color(0xFFE2DFD5), width: 1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            )
                      : modalView == 'delete'
                          // ──────────────────────────────────────────
                          // VIEW: ยืนยันการลบสมุด (ปลอดภัย ไม่แครช พร้อมปุ่มย้อนกลับ)
                          // ──────────────────────────────────────────
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with Back Button (←) and Close Button (X)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                                      color: const Color(0xFF17221C),
                                      tooltip: 'ย้อนกลับ',
                                      onPressed: () => setModalState(() => modalView = 'main'),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ยืนยันการลบสมุด',
                                            style: GoogleFonts.prompt(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          ),
                                          Text(
                                            widget.catalog.title,
                                            style: GoogleFonts.prompt(
                                              fontSize: 10.5,
                                              color: const Color(0xFF6E746F),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      color: Colors.grey.shade500,
                                      onPressed: () => Navigator.pop(ctx),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Warning Card
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFECACA), width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFFCA5A5)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(CupertinoIcons.trash, color: Color(0xFFDC2626), size: 22),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'คุณต้องการลบสมุดนี้หรือไม่?',
                                        style: GoogleFonts.prompt(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF991B1B),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'สมุด "${widget.catalog.title}" ขนาด ${widget.catalog.formattedSize} จะถูกลบออกจากบัญชีอย่างถาวร ลิงก์สาธารณะและสถิติทั้งหมดจะไม่สามารถกู้คืนได้',
                                        style: GoogleFonts.prompt(
                                          fontSize: 11.5,
                                          color: const Color(0xFF7F1D1D),
                                          height: 1.45,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Action Buttons: Cancel vs Delete
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: OutlinedButton(
                                          onPressed: () => setModalState(() => modalView = 'main'),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(color: Color(0xFFD9D7CD), width: 1.1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text(
                                            'ยกเลิก',
                                            style: GoogleFonts.prompt(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF17221C),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            widget.onDeleted?.call();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'ลบสมุดเรียบร้อยแล้ว',
                                                  style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                                                ),
                                                backgroundColor: const Color(0xFF17221C),
                                              ),
                                            );
                                          },
                                          icon: const Icon(CupertinoIcons.trash, size: 14),
                                          label: Text(
                                            'ยืนยันการลบ',
                                            style: GoogleFonts.prompt(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFDC2626),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Bottom Back Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 35,
                                  child: OutlinedButton.icon(
                                    onPressed: () => setModalState(() => modalView = 'main'),
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Color(0xFF17221C)),
                                    label: Text(
                                      '← ย้อนกลับไปหน้าจัดการสมุด',
                                      style: GoogleFonts.prompt(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF17221C),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF9F8F5),
                                      side: const BorderSide(color: Color(0xFFE2DFD5), width: 1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            )
                      // ──────────────────────────────────────────
                      // VIEW: MAIN (หน้าแรก จัดการ ตกแต่ง และปุ่มทั้งหมด)
                      // ──────────────────────────────────────────
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Header: Title + Views + Close Button (✕)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.catalog.title,
                                        style: GoogleFonts.prompt(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF17221C),
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            widget.catalog.formattedSize,
                                            style: GoogleFonts.prompt(
                                              fontSize: 10.5,
                                              color: const Color(0xFF6E746F),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                                          const Icon(CupertinoIcons.eye_fill, size: 11, color: Color(0xFF10B981)),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${widget.catalog.totalViews} วิวสะสม',
                                            style: GoogleFonts.prompt(
                                              fontSize: 10.5,
                                              color: const Color(0xFF10B981),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  color: Colors.grey.shade500,
                                  onPressed: () => Navigator.pop(ctx),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 2. Big 3D Book Live Preview Stage (ตัวตกแต่ง + พรีวิวสมุดขนาดใหญ่ทันที)
                            Container(
                              height: 186,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: activeGradient,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF17221C).withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Ground shadow when floating
                                  if (isFloating)
                                    Positioned(
                                      bottom: 12,
                                      child: Container(
                                        width: 86,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(100),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.28),
                                              blurRadius: 14,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // The Big 3D Hardcover Book Mockup
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOutCubic,
                                    transform: isFloating
                                        ? Matrix4.translationValues(0, -6, 0)
                                        : Matrix4.identity(),
                                    width: 112,
                                    height: 154,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(8),
                                      ),
                                      border: const Border(
                                        left: BorderSide(color: Color(0xFF9A7257), width: 4.5),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isFloating ? 0.35 : 0.20,
                                          ),
                                          blurRadius: isFloating ? 16 : 8,
                                          offset: isFloating
                                              ? const Offset(0, 10)
                                              : const Offset(-3, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(8),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildCoverContent(),
                                          // Gold Spine Crease
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            bottom: 0,
                                            width: 1.2,
                                            child: Container(
                                              color: const Color(0xFFC5A059).withValues(alpha: 0.6),
                                            ),
                                          ),
                                          // 3D Flipbook Badge
                                          Positioned(
                                            bottom: 5,
                                            right: 5,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.72),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.auto_stories, size: 8, color: Color(0xFF10B981)),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    '3D',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.bold,
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

                                  // Floating status badge in stage
                                  Positioned(
                                    top: 8,
                                    left: 9,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.90),
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: Colors.black.withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isFloating ? Icons.flight_takeoff_rounded : Icons.menu_book_rounded,
                                            size: 10,
                                            color: const Color(0xFF17221C),
                                          ),
                                          const SizedBox(width: 3.5),
                                          Text(
                                            isFloating ? 'สมุดลอย 3D' : 'สมุดระนาบ',
                                            style: GoogleFonts.prompt(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF17221C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 3. Inline Decoration Controls (แต่งธีมและเอฟเฟกต์ทันทีในโมดอล ไม่ต้องเปลี่ยนหน้า)
                            Row(
                              children: [
                                // Theme Swatches
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'ธีมสีพื้นหลัง',
                                            style: GoogleFonts.prompt(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF17221C),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '• ${activeTheme['name']}',
                                            style: GoogleFonts.prompt(
                                              fontSize: 9.5,
                                              color: const Color(0xFF10B981),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: _modalThemes.map((t) {
                                          final isSelected = selectedTheme == t['id'];
                                          return GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setModalState(() => selectedTheme = t['id']);
                                              _saveDecorationPreferences(selectedTheme, isFloating);
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 6),
                                              width: 23,
                                              height: 23,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: t['gradient'] as Gradient,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color(0xFF10B981)
                                                      : Colors.black.withValues(alpha: 0.15),
                                                  width: isSelected ? 2.2 : 1,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 1),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: isSelected
                                                  ? const Center(
                                                      child: Icon(Icons.check, size: 11, color: Color(0xFF10B981)),
                                                    )
                                                  : null,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),

                                // Floating Book Toggle Switch
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F6F2),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: const Color(0xFFE5E2D9), width: 0.8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'เอฟเฟกต์ลอย 3D',
                                        style: GoogleFonts.prompt(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF17221C),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Transform.scale(
                                        scale: 0.68,
                                        child: CupertinoSwitch(
                                          value: isFloating,
                                          activeTrackColor: const Color(0xFF10B981),
                                          onChanged: (val) {
                                            HapticFeedback.selectionClick();
                                            setModalState(() => isFloating = val);
                                            _saveDecorationPreferences(selectedTheme, isFloating);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 4. Unified Action Toolbar Panel (รวมกลุ่มปุ่มทั้งหมดเป็นระบบสีเดียวกัน เข้าพวกกัน 100%)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F8F5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2DFD5), width: 1),
                              ),
                              child: Column(
                                children: [
                                  // แถวบน: ปุ่มหลัก [ 📖 เปิดอ่าน ] + [ 🔗 คัดลอกลิงก์ ]
                                  Row(
                                    children: [
                                      // [ 📖 เปิดอ่าน ] (สไตล์คลีนขาวมินิมอล ขอบเขียวมรกต เข้ากับทุกปุ่ม ไม่มีสีดำที่นายไม่ชอบ)
                                      Expanded(
                                        child: SizedBox(
                                          height: 35,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              Navigator.pop(ctx);
                                              _openReader();
                                            },
                                            icon: const Icon(CupertinoIcons.book_fill, size: 13, color: Color(0xFF10B981)),
                                            label: Text(
                                              'เปิดอ่าน',
                                              style: GoogleFonts.prompt(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF17221C),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 7),

                                      // [ 🔗 คัดลอกลิงก์ ] (สไตล์คลีนขาวมินิมอล ขอบลินิน เข้ากลุ่มกับปุ่มอื่นๆ 100%)
                                      Expanded(
                                        child: SizedBox(
                                          height: 35,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              Clipboard.setData(ClipboardData(text: widget.catalog.publicUrl));
                                              setModalState(() => modalCopied = true);
                                              Future.delayed(const Duration(seconds: 2), () {
                                                if (ctx.mounted) {
                                                  setModalState(() => modalCopied = false);
                                                }
                                              });
                                            },
                                            icon: Icon(
                                              modalCopied ? CupertinoIcons.checkmark_alt : CupertinoIcons.link,
                                              size: 13,
                                              color: modalCopied ? const Color(0xFF059669) : const Color(0xFF10B981),
                                            ),
                                            label: Text(
                                              modalCopied ? 'คัดลอกแล้ว' : 'คัดลอกลิงก์',
                                              style: GoogleFonts.prompt(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: modalCopied ? const Color(0xFF059669) : const Color(0xFF17221C),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: modalCopied ? const Color(0xFFECFDF5) : Colors.white,
                                              side: BorderSide(
                                                color: modalCopied ? const Color(0xFF10B981) : const Color(0xFFD9D7CD),
                                                width: 1.1,
                                              ),
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),

                                  // แถวล่าง: ปุ่มเครื่องมือแนวนอน (กดแล้วเปลี่ยนหน้าในโมดอลพร้อมปุ่มย้อนกลับ)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCompactBottomButton(
                                          icon: CupertinoIcons.chart_bar_alt_fill,
                                          label: 'สถิติ',
                                          iconColor: const Color(0xFF10B981),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setModalState(() => modalView = 'analytics');
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _buildCompactBottomButton(
                                          icon: CupertinoIcons.qrcode,
                                          label: 'QR Code',
                                          iconColor: const Color(0xFF17221C),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setModalState(() => modalView = 'qr');
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _buildCompactBottomButton(
                                          icon: CupertinoIcons.arrow_2_circlepath,
                                          label: 'เปลี่ยนไฟล์',
                                          iconColor: const Color(0xFF17221C),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _replaceFile();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _buildCompactBottomButton(
                                          icon: CupertinoIcons.trash,
                                          label: 'ลบ',
                                          iconColor: const Color(0xFFDC2626),
                                          textColor: const Color(0xFFDC2626),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setModalState(() => modalView = 'delete');
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE9E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2820).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. 3D Hardcover View (แตะปกเพื่อเปิดรายละเอียด) ──
          Expanded(
            child: GestureDetector(
              onTap: () => _openDetail(context),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F7F3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF8C6648), width: 3.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B2820).withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(-3, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildCoverContent(),
                            // Floating 3D Quick Indicator (Luxury Glass Pill)
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: InkWell(
                                onTap: _openReader,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_stories_rounded, size: 9, color: Colors.white),
                                      SizedBox(width: 3),
                                      Text(
                                        '3D',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 2. Clean Metadata & Balanced Action Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                InkWell(
                  onTap: () => _openDetail(context),
                  child: Text(
                    widget.catalog.title,
                    style: GoogleFonts.prompt(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15221B),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),

                // File Size & Views Row with Crisp Chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F1EC),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        widget.catalog.formattedSize,
                        style: GoogleFonts.prompt(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A635D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('•', style: TextStyle(color: Color(0xFFB0AAA0), fontSize: 10)),
                    const SizedBox(width: 5),
                    const Icon(
                      CupertinoIcons.eye,
                      size: 11,
                      color: Color(0xFF1F7A54),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.catalog.totalViews} วิว',
                      style: GoogleFonts.prompt(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F7A54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),

                // ── 3. High-End Balanced Actions: [📤 แชร์] + [⋯ จัดการ] ──
                Row(
                  children: [
                    // Primary CTA: [📤 แชร์]
                    Expanded(
                      child: SizedBox(
                        height: 33,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ShareBottomSheet.show(context, widget.catalog);
                          },
                          icon: const Icon(
                            CupertinoIcons.share,
                            size: 13,
                            color: Color(0xFFE8DCC7),
                          ),
                          label: Text(
                            'แชร์',
                            style: GoogleFonts.prompt(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B2820),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Contextual Action: [⋯] (จัดการ / เมนูเครื่องมือ)
                    SizedBox(
                      width: 34,
                      height: 33,
                      child: OutlinedButton(
                        onPressed: () => _showCenterActionsModal(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBFBF8),
                          side: const BorderSide(color: Color(0xFFDDD9CF), width: 1.0),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.ellipsis,
                          size: 14,
                          color: Color(0xFF1B2820),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
