import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catalog_model.dart';
import '../services/catalog_service.dart';

enum QrMode {
  catalog,
  url,
  line,
  wifi,
  text,
  phone,
}

class QrStudioScreen extends StatefulWidget {
  final CatalogItem? initialCatalog;

  const QrStudioScreen({super.key, this.initialCatalog});

  @override
  State<QrStudioScreen> createState() => _QrStudioScreenState();
}

class _QrStudioScreenState extends State<QrStudioScreen> {
  final GlobalKey _qrCardKey = GlobalKey();

  // Mode Selection
  QrMode _currentMode = QrMode.catalog;

  // Catalogs
  List<CatalogItem> _catalogs = [];
  CatalogItem? _selectedCatalog;
  bool _isLoadingCatalogs = true;

  // Input Controllers
  final TextEditingController _urlController = TextEditingController(text: 'https://www.pedebook.com');
  final TextEditingController _lineController = TextEditingController(text: '@pedebook');
  final TextEditingController _textController = TextEditingController(text: 'ยินดีต้อนรับสู่ Pedebook 3D Digital Flipbook');
  final TextEditingController _wifiSsidController = TextEditingController(text: 'Pedebook-Guest');
  final TextEditingController _wifiPassController = TextEditingController(text: 'pedebook2025');
  final String _wifiAuthType = 'WPA'; // WPA, WEP, nopass

  final TextEditingController _phoneController = TextEditingController(text: '0812345678');

  // Customization Options
  Color _qrColor = const Color(0xFF243129); // Default: Pedebook Deep Forest Green
  QrEyeShape _eyeShape = QrEyeShape.square;
  QrDataModuleShape _dataShape = QrDataModuleShape.square;
  bool _showCenterLogo = true;
  bool _showFrameHeader = true;

  // Preset Palettes
  final List<Map<String, dynamic>> _colorPresets = [
    {'name': 'เขียวป่า', 'color': const Color(0xFF243129), 'label': 'Forest'},
    {'name': 'ดำสนิท', 'color': const Color(0xFF111827), 'label': 'Classic'},
    {'name': 'มรกต', 'color': const Color(0xFF10B981), 'label': 'Emerald'},
    {'name': 'เนวีบลู', 'color': const Color(0xFF1E3A8A), 'label': 'Navy'},
    {'name': 'ดินเผา', 'color': const Color(0xFF9A3412), 'label': 'Warm'},
    {'name': 'ม่วงหรู', 'color': const Color(0xFF581C87), 'label': 'Royal'},
    {'name': 'ไวน์แดง', 'color': const Color(0xFF881337), 'label': 'Ruby'},
    {'name': 'ทองอำพัน', 'color': const Color(0xFFB45309), 'label': 'Gold'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _lineController.dispose();
    _textController.dispose();
    _wifiSsidController.dispose();
    _wifiPassController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    setState(() => _isLoadingCatalogs = true);
    try {
      final items = await CatalogService.getUserCatalogs();
      if (mounted) {
        setState(() {
          _catalogs = items;
          if (widget.initialCatalog != null) {
            _selectedCatalog = items.firstWhere(
              (c) => c.id == widget.initialCatalog!.id,
              orElse: () => items.isNotEmpty ? items.first : widget.initialCatalog!,
            );
          } else if (items.isNotEmpty) {
            _selectedCatalog = items.first;
          }
          _isLoadingCatalogs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCatalogs = false);
      }
    }
  }

  /// Calculates the final QR payload based on the selected mode
  String get _qrPayload {
    switch (_currentMode) {
      case QrMode.catalog:
        if (_selectedCatalog != null) {
          return _selectedCatalog!.publicUrl;
        }
        return 'https://www.pedebook.com';

      case QrMode.url:
        final raw = _urlController.text.trim();
        if (raw.isEmpty) return 'https://www.pedebook.com';
        if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
          return 'https://$raw';
        }
        return raw;

      case QrMode.line:
        final raw = _lineController.text.trim();
        if (raw.isEmpty) return 'https://line.me/R/ti/p/@pedebook';
        if (raw.startsWith('http')) return raw;
        final cleanId = raw.startsWith('@') ? raw : '@$raw';
        return 'https://line.me/R/ti/p/$cleanId';

      case QrMode.wifi:
        final ssid = _wifiSsidController.text.trim();
        final pass = _wifiPassController.text.trim();
        return 'WIFI:T:$_wifiAuthType;S:$ssid;P:$pass;;';

      case QrMode.text:
        final raw = _textController.text.trim();
        return raw.isEmpty ? 'Pedebook 3D Digital Flipbook' : raw;

      case QrMode.phone:
        final raw = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
        return raw.isEmpty ? 'tel:0812345678' : 'tel:$raw';
    }
  }

  /// Label shown on the QR frame preview
  String get _displayTitle {
    switch (_currentMode) {
      case QrMode.catalog:
        return _selectedCatalog?.title ?? 'แค็ตตาล็อก Pedebook 3D';
      case QrMode.url:
        return 'สแกนเพื่อเปิดเว็บไซต์';
      case QrMode.line:
        return 'แอด LINE Official Account';
      case QrMode.wifi:
        return 'สแกนเชื่อมต่อ Wi-Fi อัตโนมัติ';
      case QrMode.text:
        return 'ข้อความ / รายละเอียดสินค้า';
      case QrMode.phone:
        return 'สแกนเพื่อโทรออกด่วน';
    }
  }

  String get _displaySubtitle {
    switch (_currentMode) {
      case QrMode.catalog:
        return 'เปิดอ่านแบบ 3D พลิกหน้าเสมือนจริง';
      case QrMode.url:
        return _urlController.text.trim();
      case QrMode.line:
        return _lineController.text.trim();
      case QrMode.wifi:
        return 'SSID: ${_wifiSsidController.text.trim()}';
      case QrMode.text:
        return 'บันทึกหรือดูข้อความได้ทันที';
      case QrMode.phone:
        return _phoneController.text.trim();
    }
  }

  IconData get _modeIcon {
    switch (_currentMode) {
      case QrMode.catalog:
        return Icons.menu_book_rounded;
      case QrMode.url:
        return Icons.language_rounded;
      case QrMode.line:
        return Icons.chat_bubble_rounded;
      case QrMode.wifi:
        return Icons.wifi_rounded;
      case QrMode.text:
        return Icons.short_text_rounded;
      case QrMode.phone:
        return Icons.phone_rounded;
    }
  }

  /// Copies data to clipboard
  void _copyPayload() {
    Clipboard.setData(ClipboardData(text: _qrPayload));
    _showSnackBar('คัดลอกข้อมูลเรียบร้อยแล้วครับ: $_qrPayload', Icons.check_circle_rounded);
  }

  /// Tests opening the link or action
  Future<void> _testOpen() async {
    final payload = _qrPayload;
    if (payload.startsWith('http://') || payload.startsWith('https://') || payload.startsWith('tel:')) {
      final uri = Uri.parse(payload);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    _copyPayload();
  }

  /// Exports and shares/downloads the QR code image
  Future<void> _exportImage() async {
    try {
      final boundary = _qrCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final filename = 'pedebook_qr_${DateTime.now().millisecondsSinceEpoch}.png';

      await Share.shareXFiles(
        [
          XFile.fromData(
            pngBytes,
            mimeType: 'image/png',
            name: filename,
          ),
        ],
        text: 'QR Code สำหรับ $_displayTitle จาก Pedebook Studio',
      );
    } catch (e) {
      _showSnackBar('ขออภัย ไม่สามารถบันทึกภาพได้ในขณะนี้: $e', Icons.error_outline_rounded);
    }
  }

  /// Shares the QR code text / URL
  void _shareContent() {
    Share.share(
      '$_displayTitle\nเปิดดูหรือสแกนได้ที่: $_qrPayload',
      subject: _displayTitle,
    );
  }

  void _showSnackBar(String text, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: const Color(0xFF243129),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBF8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2820),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.qrcode,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สตูดิโอสร้าง QR Code',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF17221C),
                  ),
                ),
                Text(
                  'สร้างและตกแต่ง QR สำหรับแชร์หรือพิมพ์ป้าย',
                  style: GoogleFonts.prompt(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'รีเซ็ตเป็นค่าเริ่มต้น',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF243129), size: 20),
            onPressed: () {
              setState(() {
                _qrColor = const Color(0xFF243129);
                _eyeShape = QrEyeShape.square;
                _dataShape = QrDataModuleShape.square;
                _showCenterLogo = true;
                _showFrameHeader = true;
              });
              _showSnackBar('รีเซ็ตการตกแต่งเป็นค่ามาตรฐานแล้วครับ', Icons.check_circle_outline_rounded);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. LIVE QR CODE PREVIEW CARD (RepaintBoundary) ──
              Center(
                child: RepaintBoundary(
                  key: _qrCardKey,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E2D9), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF243129).withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Card Header Badge
                        if (_showFrameHeader) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _qrColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_modeIcon, size: 14, color: _qrColor),
                                const SizedBox(width: 6),
                                Text(
                                  _currentMode == QrMode.catalog
                                      ? 'PEDEBOOK 3D FLIPBOOK'
                                      : _currentMode.name.toUpperCase(),
                                  style: GoogleFonts.prompt(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: _qrColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // The QR Code Image with Center Emblem
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: _qrPayload,
                                version: QrVersions.auto,
                                size: 195,
                                gapless: true,
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: _eyeShape,
                                  color: _qrColor,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: _dataShape,
                                  color: _qrColor,
                                ),
                              ),
                              if (_showCenterLogo)
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: _qrColor.withValues(alpha: 0.25),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _qrColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.menu_book_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title & Prompt in Card
                        Text(
                          _displayTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF17221C),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _displaySubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. BALANCED 2-TIER QUICK EXPORT & ACTION DECK ──
              Column(
                children: [
                  // Row 1: Primary Actions (50/50 Balanced)
                  Row(
                    children: [
                      // Download / Save PNG
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _exportImage,
                            icon: const Icon(Icons.download_rounded, size: 17, color: Color(0xFFE8DCC7)),
                            label: Text(
                              'บันทึกภาพ QR',
                              style: GoogleFonts.prompt(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B2820),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Share to Social / LINE
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _shareContent,
                            icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                            label: Text(
                              'แชร์ QR Code',
                              style: GoogleFonts.prompt(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F7A54),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Secondary Tools (Copy Link & Test Open)
                  Row(
                    children: [
                      // Copy Payload
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: _copyPayload,
                            icon: const Icon(CupertinoIcons.doc_on_doc, size: 14, color: Color(0xFF1B2820)),
                            label: Text(
                              'คัดลอกลิงก์',
                              style: GoogleFonts.prompt(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B2820),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFDDD9CF), width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Test Open Link
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: _testOpen,
                            icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 14, color: Color(0xFF1B2820)),
                            label: Text(
                              'ทดลองเปิดอ่าน',
                              style: GoogleFonts.prompt(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B2820),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFDDD9CF), width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 3. DATA SOURCE SELECTOR (แบบครบวงจร) ──
              _buildSectionTitle('1. เลือกประเภทข้อมูลที่ต้องการสร้าง QR', Icons.tune_rounded),
              const SizedBox(height: 10),

              // Segmented Category Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModeChip(QrMode.catalog, 'แค็ตตาล็อก 3D', Icons.menu_book_rounded),
                    const SizedBox(width: 8),
                    _buildModeChip(QrMode.url, 'เว็บไซต์ / ลิงก์', Icons.language_rounded),
                    const SizedBox(width: 8),
                    _buildModeChip(QrMode.line, 'LINE Official', Icons.chat_bubble_rounded),
                    const SizedBox(width: 8),
                    _buildModeChip(QrMode.wifi, 'Wi-Fi ร้าน/บูธ', Icons.wifi_rounded),
                    const SizedBox(width: 8),
                    _buildModeChip(QrMode.text, 'ข้อความ/โน้ต', Icons.short_text_rounded),
                    const SizedBox(width: 8),
                    _buildModeChip(QrMode.phone, 'เบอร์โทรศัพท์', Icons.phone_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Category Specific Input Form
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E2D9)),
                ),
                child: _buildModeInputForm(),
              ),
              const SizedBox(height: 20),

              // ── 4. DESIGN & COLOR CUSTOMIZATION ──
              _buildSectionTitle('2. ตกแต่งสีสันและสไตล์ QR Code', Icons.palette_rounded),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E2D9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Palette Row
                    Text(
                      'โทนสีของ QR Code:',
                      style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF17221C)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorPresets.map((preset) {
                        final color = preset['color'] as Color;
                        final isSelected = _qrColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _qrColor = color),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? color : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : color.withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  preset['name'] as String,
                                  style: GoogleFonts.prompt(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : const Color(0xFF17221C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24, thickness: 0.8),

                    // Eye Shape & Data Shape
                    Row(
                      children: [
                        // Eye Shape
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ขอบมุม (Eye Frame):',
                                style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildShapePill(
                                    label: 'เหลี่ยม',
                                    isSelected: _eyeShape == QrEyeShape.square,
                                    onTap: () => setState(() => _eyeShape = QrEyeShape.square),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildShapePill(
                                    label: 'กลม',
                                    isSelected: _eyeShape == QrEyeShape.circle,
                                    onTap: () => setState(() => _eyeShape = QrEyeShape.circle),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Data Shape
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'จุดข้อมูล (Data Dots):',
                                style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildShapePill(
                                    label: 'เหลี่ยม',
                                    isSelected: _dataShape == QrDataModuleShape.square,
                                    onTap: () => setState(() => _dataShape = QrDataModuleShape.square),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildShapePill(
                                    label: 'กลม',
                                    isSelected: _dataShape == QrDataModuleShape.circle,
                                    onTap: () => setState(() => _dataShape = QrDataModuleShape.circle),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.8),

                    // Toggles: Center Logo & Frame Header
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _showCenterLogo = !_showCenterLogo),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _showCenterLogo ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    color: _showCenterLogo ? const Color(0xFF10B981) : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ใส่โลโก้ตรงกลาง',
                                    style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _showFrameHeader = !_showFrameHeader),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _showFrameHeader ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    color: _showFrameHeader ? const Color(0xFF10B981) : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'หัวข้อการ์ด SCAN ME',
                                    style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF243129)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF17221C),
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip(QrMode mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF243129) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF243129) : const Color(0xFFE5E2D9),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF243129).withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.prompt(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFF17221C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF243129) : const Color(0xFFF4F3ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF243129) : const Color(0xFFE2DFD5),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFF17221C),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeInputForm() {
    switch (_currentMode) {
      case QrMode.catalog:
        if (_isLoadingCatalogs) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
          );
        }
        if (_catalogs.isEmpty) {
          return Text(
            'ไม่พบสมุดแค็ตตาล็อก กรุณาสร้างสมุดใหม่ที่หน้าแรกก่อนครับ',
            style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey.shade600),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เลือกสมุดแค็ตตาล็อกที่ต้องการแปลงเป็น QR Code:',
              style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF17221C)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E2D9)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CatalogItem>(
                  value: _selectedCatalog,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF243129)),
                  items: _catalogs.map((cat) {
                    return DropdownMenuItem<CatalogItem>(
                      value: cat,
                      child: Row(
                        children: [
                          const Icon(Icons.book_rounded, size: 16, color: Color(0xFF243129)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.title,
                              style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            cat.formattedSize,
                            style: GoogleFonts.prompt(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCatalog = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ลิงก์: ${_selectedCatalog?.publicUrl ?? ""}',
              style: GoogleFonts.prompt(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

      case QrMode.url:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กรอกลิงก์หรือเว็บไซต์ (URL):',
              style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF17221C)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'https://www.example.com',
                prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF243129)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  tooltip: 'วางข้อความ',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _urlController.text = data!.text!;
                      setState(() {});
                    }
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFFAF9F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E2D9))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E2D9))),
              ),
              style: GoogleFonts.prompt(fontSize: 12),
            ),
          ],
        );

      case QrMode.line:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กรอก LINE ID หรือลิงก์ LINE Official:',
              style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF17221C)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lineController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '@pedebook หรือ Line ID',
                prefixIcon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Color(0xFF06C755)),
                filled: true,
                fillColor: const Color(0xFFFAF9F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E2D9))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E2D9))),
              ),
              style: GoogleFonts.prompt(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              'จะแปลงเป็นลิงก์เปิดแอป LINE ทันทีเมื่อลูกค้าสแกน',
              style: GoogleFonts.prompt(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        );

      case QrMode.wifi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตั้งค่า Wi-Fi ให้ลูกค้าสแกนต่อเน็ตอัตโนมัติ:',
              style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF17221C)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wifiSsidController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'ชื่อเครือข่าย Wi-Fi (SSID)',
                prefixIcon: const Icon(Icons.wifi_rounded, size: 18),
                filled: true,
                fillColor: const Color(0xFFFAF9F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.prompt(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wifiPassController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน Wi-Fi (Password)',
                prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                filled: true,
                fillColor: const Color(0xFFFAF9F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.prompt(fontSize: 12),
            ),
          ],
        );

      case QrMode.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กรอกข้อความหรือบันทึกที่ต้องการแชร์:',
              style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF17221C)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความอิสระที่นี่...',
                filled: true,
                fillColor: const Color(0xFFFAF9F5),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.prompt(fontSize: 12),
            ),
          ],
        );

      case QrMode.phone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กรอกเบอร์โทรศัพท์สำหรับโทรออกทันที:',
              style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF17221C)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'เช่น 0812345678',
                prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF243129)),
                filled: true,
                fillColor: const Color(0xFFFAF9F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.prompt(fontSize: 12),
            ),
          ],
        );
    }
  }
}
