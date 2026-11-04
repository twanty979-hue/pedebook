import 'dart:convert';
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

enum QrCardTheme {
  igSunset,
  tikTokNeon,
  luxuryForest,
  pastelAura,
  midnightBlack,
  cleanStudio,
}

enum QrCardRatio {
  nametag, // Square 1:1 Instagram Nametag
  story,   // Tall 9:16 Story / TikTok Poster
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

  // Modern IG / TikTok Card Customization
  QrCardTheme _selectedTheme = QrCardTheme.igSunset;
  QrCardRatio _selectedRatio = QrCardRatio.nametag;
  QrEyeShape _eyeShape = QrEyeShape.circle;
  QrDataModuleShape _dataShape = QrDataModuleShape.circle;
  bool _showCenterLogo = true;
  bool _showVerifiedBadge = true;

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
  final String _wifiAuthType = 'WPA';
  final TextEditingController _phoneController = TextEditingController(text: '0812345678');

  // Preset Palettes (สไตล์ IG & TikTok)
  final List<Map<String, dynamic>> _themePresets = [
    {
      'theme': QrCardTheme.igSunset,
      'name': 'IG Sunset',
      'tag': '📸 ไอจี',
      'colors': [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
    },
    {
      'theme': QrCardTheme.tikTokNeon,
      'name': 'TikTok Neon',
      'tag': '⚡ ตอกตอก',
      'colors': [Color(0xFF0F0F14), Color(0xFF00F2FE), Color(0xFFFE2C55)],
    },
    {
      'theme': QrCardTheme.luxuryForest,
      'name': 'Emerald',
      'tag': '🌲 พรีเมียม',
      'colors': [Color(0xFF0D1C14), Color(0xFF1A3828), Color(0xFF4EE29B)],
    },
    {
      'theme': QrCardTheme.pastelAura,
      'name': 'Pastel Aura',
      'tag': '🦄 พาสเทล',
      'colors': [Color(0xFFE9D5FF), Color(0xFFCFFAFE), Color(0xFFFCE7F3)],
    },
    {
      'theme': QrCardTheme.midnightBlack,
      'name': 'Midnight Dark',
      'tag': '🖤 มินิมอล',
      'colors': [Color(0xFF18181B), Color(0xFF27272A), Color(0xFF71717A)],
    },
    {
      'theme': QrCardTheme.cleanStudio,
      'name': 'Clean Studio',
      'tag': '🤍 คลีนหรู',
      'colors': [Color(0xFFFFFFFF), Color(0xFFEFECE2), Color(0xFFD4CEC1)],
    },
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

  Uint8List? _getCoverBytes(CatalogItem? cat) {
    if (cat?.coverImage == null || cat!.coverImage!.isEmpty) return null;
    if (cat.coverImage!.startsWith('http')) return null;
    try {
      final img = cat.coverImage!;
      final base64String = img.contains(',') ? img.split(',').last : img;
      final clean = base64String.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (_) {
      return null;
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
        return 'สแกนเชื่อมต่อ Wi-Fi ร้าน';
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
        return Icons.auto_stories;
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

  Gradient _getThemeGradient() {
    switch (_selectedTheme) {
      case QrCardTheme.igSunset:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF833AB4), // Purple
            Color(0xFFFD1D1D), // Rose red
            Color(0xFFFCB045), // Warm orange
          ],
        );
      case QrCardTheme.tikTokNeon:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0F14),
            Color(0xFF1B1B28),
            Color(0xFF09090C),
          ],
        );
      case QrCardTheme.luxuryForest:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1C14),
            Color(0xFF1A3828),
            Color(0xFF0F241A),
          ],
        );
      case QrCardTheme.pastelAura:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE9D5FF),
            Color(0xFFCFFAFE),
            Color(0xFFFCE7F3),
          ],
        );
      case QrCardTheme.midnightBlack:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18181B),
            Color(0xFF27272A),
            Color(0xFF141416),
          ],
        );
      case QrCardTheme.cleanStudio:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8F7F3),
            Color(0xFFEFECE2),
          ],
        );
    }
  }

  Color _getThemeTextColor() {
    switch (_selectedTheme) {
      case QrCardTheme.pastelAura:
      case QrCardTheme.cleanStudio:
        return const Color(0xFF18221B);
      default:
        return Colors.white;
    }
  }

  Color _getThemeSubtextColor() {
    switch (_selectedTheme) {
      case QrCardTheme.pastelAura:
      case QrCardTheme.cleanStudio:
        return const Color(0xFF5F6862);
      default:
        return Colors.white.withValues(alpha: 0.82);
    }
  }

  Color _getVerifiedBadgeColor() {
    switch (_selectedTheme) {
      case QrCardTheme.igSunset:
        return const Color(0xFF3897F0); // Official IG blue check
      case QrCardTheme.tikTokNeon:
        return const Color(0xFF00F2FE); // TikTok cyan
      case QrCardTheme.luxuryForest:
        return const Color(0xFF4EE29B); // Emerald
      case QrCardTheme.pastelAura:
        return const Color(0xFF8B5CF6); // Purple
      case QrCardTheme.midnightBlack:
        return const Color(0xFFE4E4E7); // Titanium
      case QrCardTheme.cleanStudio:
        return const Color(0xFF1F7A54); // Forest
    }
  }

  Color _getQrCodeColor() {
    switch (_selectedTheme) {
      case QrCardTheme.tikTokNeon:
        return const Color(0xFF0F0F14);
      case QrCardTheme.luxuryForest:
        return const Color(0xFF10281C);
      default:
        return const Color(0xFF1B1B1F);
    }
  }

  /// Copies data to clipboard
  void _copyPayload() {
    Clipboard.setData(ClipboardData(text: _qrPayload));
    _showSnackBar('คัดลอกลิงก์เรียบร้อยแล้วครับ: $_qrPayload', Icons.check_circle_rounded);
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
      final filename = 'pedebook_${_selectedTheme.name}_${DateTime.now().millisecondsSinceEpoch}.png';

      await Share.shareXFiles(
        [
          XFile.fromData(
            pngBytes,
            mimeType: 'image/png',
            name: filename,
          ),
        ],
        text: 'เปิดอ่าน 3D Flipbook "$_displayTitle" ได้ทันที เพียงสแกน QR Code สไตล์ชิคนี้!',
      );
    } catch (e) {
      _showSnackBar('ขออภัย ไม่สามารถบันทึกภาพได้ในขณะนี้: $e', Icons.error_outline_rounded);
    }
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
        backgroundColor: const Color(0xFF1B2820),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                ),
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
                Row(
                  children: [
                    Text(
                      'สตูดิโอสร้าง QR Code',
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF17221C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF3F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'IG & TikTok',
                        style: GoogleFonts.prompt(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF435A4D),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'การ์ด QR โค้ดแนวโซเชียล สวยพร้อมแชร์ลงสตอรี่และพิมพ์ป้าย',
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
                _selectedTheme = QrCardTheme.igSunset;
                _selectedRatio = QrCardRatio.nametag;
                _eyeShape = QrEyeShape.circle;
                _dataShape = QrDataModuleShape.circle;
                _showCenterLogo = true;
                _showVerifiedBadge = true;
              });
              _showSnackBar('รีเซ็ตการตกแต่งเป็นค่ามาตรฐานแล้วครับ', Icons.check_circle_outline_rounded);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. LIVE AESTHETIC QR CARD PREVIEW (สไตล์ไอจี / ตอกตอก) ──
              Center(
                child: RepaintBoundary(
                  key: _qrCardKey,
                  child: _buildQrCardPreview(),
                ),
              ),
              const SizedBox(height: 18),

              // ── 2. QUICK ACTION DECK (แชร์การ์ด IG / TikTok & บันทึก HD) ──
              _buildActionDeck(),
              const SizedBox(height: 22),

              // ── 3. CARD FORMAT & RATIO SWITCHER ──
              _buildSectionTitle('1. รูปแบบการ์ด (Card Ratio)', CupertinoIcons.square_on_square),
              const SizedBox(height: 10),
              _buildRatioSelector(),
              const SizedBox(height: 20),

              // ── 4. THEME PRESETS SELECTOR (แนวไอจี & ตอกตอก) ──
              _buildSectionTitle('2. ธีมสีสไตล์ IG & TikTok', CupertinoIcons.sparkles),
              const SizedBox(height: 10),
              _buildThemePresetsSelector(),
              const SizedBox(height: 20),

              // ── 5. DATA SOURCE SELECTOR (เลือกเนื้อหา) ──
              _buildSectionTitle('3. ข้อมูลที่ต้องการแปลงเป็น QR Code', Icons.tune_rounded),
              const SizedBox(height: 10),

              // Category Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModeChip(QrMode.catalog, 'แค็ตตาล็อก 3D', Icons.auto_stories),
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

              // ── 6. QR CODE DETAIL CUSTOMIZATION (Dot & Eye Shapes) ──
              _buildSectionTitle('4. ปรับแต่งทรงจุด QR & สัญลักษณ์', Icons.palette_rounded),
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
                                    label: 'กลมมน (IG)',
                                    isSelected: _eyeShape == QrEyeShape.circle,
                                    onTap: () => setState(() => _eyeShape = QrEyeShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildShapePill(
                                    label: 'เหลี่ยม',
                                    isSelected: _eyeShape == QrEyeShape.square,
                                    onTap: () => setState(() => _eyeShape = QrEyeShape.square),
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
                                    label: 'จุดกลม (ชิค)',
                                    isSelected: _dataShape == QrDataModuleShape.circle,
                                    onTap: () => setState(() => _dataShape = QrDataModuleShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildShapePill(
                                    label: 'เหลี่ยม',
                                    isSelected: _dataShape == QrDataModuleShape.square,
                                    onTap: () => setState(() => _dataShape = QrDataModuleShape.square),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.8),

                    // Toggles: Center Logo & Verified Badge
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
                                    'ใส่โลโก้ตรงกลาง QR',
                                    style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _showVerifiedBadge = !_showVerifiedBadge),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _showVerifiedBadge ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    color: _showVerifiedBadge ? const Color(0xFF10B981) : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ตราติ๊กถูก Verified',
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

  // ── LIVE PREVIEW BUILDERS ──

  Widget _buildQrCardPreview() {
    final coverBytes = _getCoverBytes(_selectedCatalog);
    final themeGradient = _getThemeGradient();
    final textColor = _getThemeTextColor();
    final subtextColor = _getThemeSubtextColor();
    final verifiedColor = _getVerifiedBadgeColor();
    final qrColor = _getQrCodeColor();

    if (_selectedRatio == QrCardRatio.story) {
      return _buildStoryPosterCard(
        coverBytes: coverBytes,
        gradient: themeGradient,
        textColor: textColor,
        subtextColor: subtextColor,
        verifiedColor: verifiedColor,
        qrColor: qrColor,
      );
    }

    return _buildNametagCard(
      coverBytes: coverBytes,
      gradient: themeGradient,
      textColor: textColor,
      subtextColor: subtextColor,
      verifiedColor: verifiedColor,
      qrColor: qrColor,
    );
  }

  /// 1. Nametag 1:1 Instagram / TikTok Card
  Widget _buildNametagCard({
    required Uint8List? coverBytes,
    required Gradient gradient,
    required Color textColor,
    required Color subtextColor,
    required Color verifiedColor,
    required Color qrColor,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _selectedTheme == QrCardTheme.cleanStudio
              ? const Color(0xFFE5E1D5)
              : Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedTheme == QrCardTheme.tikTokNeon
                ? const Color(0xFF00F2FE).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          if (_selectedTheme == QrCardTheme.tikTokNeon)
            BoxShadow(
              color: const Color(0xFFFE2C55).withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(4, 12),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Avatar/Cover + Title + Verified Badge
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: coverBytes != null
                      ? Image.memory(coverBytes, fit: BoxFit.cover)
                      : Center(
                          child: Icon(
                            _modeIcon,
                            color: textColor,
                            size: 18,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _displayTitle,
                            style: GoogleFonts.prompt(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_showVerifiedBadge) ...[
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 14,
                            color: verifiedColor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _currentMode == QrMode.catalog
                          ? '@pedebook • 3D Flipbook'
                          : _displaySubtitle,
                      style: GoogleFonts.prompt(
                        fontSize: 10,
                        color: subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedTheme == QrCardTheme.tikTokNeon)
                      const Icon(CupertinoIcons.bolt_fill, size: 9, color: Color(0xFF00F2FE))
                    else
                      const Icon(CupertinoIcons.sparkles, size: 9, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      _selectedTheme == QrCardTheme.tikTokNeon ? 'TIKTOK' : 'SCAN ME',
                      style: GoogleFonts.prompt(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Floating Pure White QR Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 190,
                  gapless: true,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  eyeStyle: QrEyeStyle(
                    eyeShape: _eyeShape,
                    color: qrColor,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: _dataShape,
                    color: qrColor,
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
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: verifiedColor.withValues(alpha: 0.7),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _modeIcon,
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
          const SizedBox(height: 14),

          // Scan Instruction & Hashtag Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.camera_fill, size: 12, color: textColor),
                const SizedBox(width: 5),
                Text(
                  'สแกนด้วยกล้องมือถือ เพื่อเปิดอ่าน 3D ทันที',
                  style: GoogleFonts.prompt(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '#Pedebook3D  •  www.pedebook.com',
            style: GoogleFonts.prompt(
              fontSize: 9,
              color: subtextColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Tall 9:16 Instagram / TikTok Story Poster Card
  Widget _buildStoryPosterCard({
    required Uint8List? coverBytes,
    required Gradient gradient,
    required Color textColor,
    required Color subtextColor,
    required Color verifiedColor,
    required Color qrColor,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: _selectedTheme == QrCardTheme.cleanStudio
              ? const Color(0xFFE5E1D5)
              : Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Story Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.sparkles, size: 11, color: textColor),
                const SizedBox(width: 5),
                Text(
                  'PEDEBOOK STORY POSTER',
                  style: GoogleFonts.prompt(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Book 3D Cover Presentation (if Catalog Mode)
          if (_currentMode == QrMode.catalog && coverBytes != null) ...[
            Container(
              width: 95,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                border: const Border(left: BorderSide(color: Color(0xFFC5A059), width: 3.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(-2, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                child: Image.memory(coverBytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Title & Verified Seal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _displayTitle,
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_showVerifiedBadge) ...[
                const SizedBox(width: 5),
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 15,
                  color: verifiedColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _displaySubtitle,
            style: GoogleFonts.prompt(
              fontSize: 10.5,
              color: subtextColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Floating White QR Code Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 155,
                  gapless: true,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  eyeStyle: QrEyeStyle(
                    eyeShape: _eyeShape,
                    color: qrColor,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: _dataShape,
                    color: qrColor,
                  ),
                ),
                if (_showCenterLogo)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: verifiedColor, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(_modeIcon, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Prompt
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.camera_viewfinder, size: 12, color: textColor),
                const SizedBox(width: 5),
                Text(
                  'SCAN TO READ 3D FLIPBOOK',
                  style: GoogleFonts.prompt(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@pedebook.official  •  pedebook.com',
            style: GoogleFonts.prompt(
              fontSize: 9,
              color: subtextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTROLS & ACTIONS ──

  Widget _buildActionDeck() {
    return Column(
      children: [
        Row(
          children: [
            // Share Image to Social (IG / TikTok)
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _exportImage,
                  icon: const Icon(CupertinoIcons.share, size: 17, color: Colors.white),
                  label: Text(
                    'แชร์การ์ด (IG / TikTok)',
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2820),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Save Image to Device
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _exportImage,
                  icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF1F7A54)),
                  label: Text(
                    'บันทึก HD',
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: const Color(0xFF1F7A54),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEBF5F0),
                    foregroundColor: const Color(0xFF1F7A54),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFD4EADB), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: _copyPayload,
                  icon: const Icon(CupertinoIcons.doc_on_doc, size: 13.5, color: Color(0xFF1B2820)),
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
                    side: const BorderSide(color: Color(0xFFE2DFD5), width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: _testOpen,
                  icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 13.5, color: Color(0xFF1B2820)),
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
                    side: const BorderSide(color: Color(0xFFE2DFD5), width: 1.0),
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
    );
  }

  Widget _buildRatioSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E2D9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedRatio = QrCardRatio.nametag),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.5),
                decoration: BoxDecoration(
                  color: _selectedRatio == QrCardRatio.nametag
                      ? const Color(0xFF1B2820)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.square_fill,
                      size: 14,
                      color: _selectedRatio == QrCardRatio.nametag
                          ? Colors.white
                          : const Color(0xFF6E746F),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'การ์ด Nametag (1:1)',
                      style: GoogleFonts.prompt(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _selectedRatio == QrCardRatio.nametag
                            ? Colors.white
                            : const Color(0xFF6E746F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedRatio = QrCardRatio.story),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.5),
                decoration: BoxDecoration(
                  color: _selectedRatio == QrCardRatio.story
                      ? const Color(0xFF1B2820)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.device_phone_portrait,
                      size: 14,
                      color: _selectedRatio == QrCardRatio.story
                          ? Colors.white
                          : const Color(0xFF6E746F),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'สตอรี่โปสเตอร์ (9:16)',
                      style: GoogleFonts.prompt(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _selectedRatio == QrCardRatio.story
                            ? Colors.white
                            : const Color(0xFF6E746F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePresetsSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _themePresets.map((preset) {
          final theme = preset['theme'] as QrCardTheme;
          final isSelected = _selectedTheme == theme;
          final colors = preset['colors'] as List<Color>;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTheme = theme;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1B2820) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1B2820) : const Color(0xFFE5E2D9),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      preset['name'] as String,
                      style: GoogleFonts.prompt(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF1B2820),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      preset['tag'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white.withValues(alpha: 0.7) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1B2820)),
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
          color: isSelected ? const Color(0xFF1B2820) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B2820) : const Color(0xFFE5E2D9),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B2820).withValues(alpha: 0.15),
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
              color: isSelected ? const Color(0xFF4EE29B) : Colors.grey.shade700,
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
          padding: const EdgeInsets.symmetric(vertical: 6.5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1B2820) : const Color(0xFFF4F3ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF1B2820) : const Color(0xFFE2DFD5),
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
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1B2820)),
                  items: _catalogs.map((cat) {
                    return DropdownMenuItem<CatalogItem>(
                      value: cat,
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF1F7A54)),
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
              style: GoogleFonts.prompt(fontSize: 10, color: const Color(0xFF1F7A54), fontWeight: FontWeight.w600),
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
                prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF1B2820)),
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
                prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF1B2820)),
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
