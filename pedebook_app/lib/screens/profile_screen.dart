import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../services/revenuecat_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _email = '';
  String? _avatarUrl;
  bool _isLoading = true;

  double _usedStorageMb = 29.6;
  final double _totalStorageQuotaMb = 100.0;
  String _currentPlan = 'free';
  String _currentPlanDisplay = 'แพ็กเกจฟรี (Free Tier) • 100 MB';



  @override
  void initState() {
    super.initState();
    RevenueCatService.instance.initialize(userId: AuthService.currentUser?.id);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = AuthService.currentUser;
    setState(() {
      _email = user?.email ?? 'std.65122420112@ubru.ac.th';
      _avatarUrl = user?.userMetadata?['avatar_url'] as String? ??
          user?.userMetadata?['picture'] as String?;
      _displayName = user?.userMetadata?['full_name'] as String? ??
          user?.userMetadata?['name'] as String? ??
          (_email.contains('@') ? _email.split('@').first : 'Pedebook Creator');
    });

    try {
      final catalogs = await CatalogService.getUserCatalogs();
      if (mounted && catalogs.isNotEmpty) {
        final totalB = catalogs.fold<int>(0, (sum, c) => sum + c.fileSizeBytes);
        final mb = totalB > 0 ? (totalB / (1024 * 1024)) : 29.6;

        setState(() {
          _usedStorageMb = mb;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Business / Profile Details
  String _brandName = 'Wallcraft Marble Studio';
  String _phoneNumber = '081-234-5678';
  String _lineId = '@wallcraft';

  // ── 1. Modern iOS Bottom Sheet สำหรับแก้ไขข้อมูลโปรไฟล์ & แบรนด์ (ไม่ใช้รูปคนแปลกหน้า) ──
  void _openEditProfileSheet() {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController(text: _displayName);
    final brandCtrl = TextEditingController(text: _brandName);
    final phoneCtrl = TextEditingController(text: _phoneNumber);
    final lineCtrl = TextEditingController(text: _lineId);
    final avatarUrlCtrl = TextEditingController(text: _avatarUrl ?? '');
    String? tempAvatar = _avatarUrl;

    // ไอคอนสไตล์ครีเอเตอร์ & ธุรกิจสำหรับให้เลือกแทนรูปคนแปลกหน้า
    final List<Map<String, dynamic>> creatorBadges = [
      {'label': 'แมวมาสคอต', 'icon': '🐱', 'url': 'https://api.dicebear.com/7.x/bottts/png?seed=pedebook_cat'},
      {'label': 'หน้าร้าน/แบรนด์', 'icon': '🏢', 'url': 'https://api.dicebear.com/7.x/identicon/png?seed=store'},
      {'label': 'แค็ตตาล็อก', 'icon': '📚', 'url': 'https://api.dicebear.com/7.x/identicon/png?seed=catalog'},
      {'label': 'ดีไซเนอร์', 'icon': '🎨', 'url': 'https://api.dicebear.com/7.x/identicon/png?seed=designer'},
      {'label': 'มืออาชีพ', 'icon': '💼', 'url': 'https://api.dicebear.com/7.x/identicon/png?seed=pro'},
      {'label': 'สตาร์ทอัพ', 'icon': '🚀', 'url': 'https://api.dicebear.com/7.x/identicon/png?seed=rocket'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBFBF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                const SizedBox(height: 14),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'แก้ไขข้อมูลโปรไฟล์ & แบรนด์',
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
                  'ข้อมูลนี้จะแสดงในหน้าแค็ตตาล็อก 3D และข้อมูลติดต่อร้านค้าของคุณ',
                  style: GoogleFonts.prompt(fontSize: 11.5, color: const Color(0xFF78867E)),
                ),
                const SizedBox(height: 18),

                // ── Center Avatar Preview ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1F7A54), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1F7A54).withValues(alpha: 0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: tempAvatar != null && tempAvatar!.isNotEmpty
                              ? Image.network(
                                  tempAvatar!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _buildDefaultAvatar(),
                                )
                              : _buildDefaultAvatar(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'เลือกไอคอนตัวแทนหรือวางลิงก์รูปภาพของคุณเอง',
                        style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF6E746F)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Creator Badges Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: creatorBadges.map((badge) {
                      final url = badge['url'] as String;
                      final isSelected = tempAvatar == url;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              tempAvatar = url;
                              avatarUrlCtrl.text = url;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1B2820) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1B2820) : const Color(0xFFE5E2D9),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(badge['icon'] as String, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 5),
                                Text(
                                  badge['label'] as String,
                                  style: GoogleFonts.prompt(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : const Color(0xFF1B2820),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Form Fields
                _buildFormField(
                  label: 'ชื่อที่แสดงในระบบ (Display Name)',
                  controller: nameCtrl,
                  icon: CupertinoIcons.person_fill,
                  hint: 'เช่น O-IT-0114 หรือชื่อแบรนด์',
                ),
                const SizedBox(height: 12),

                _buildFormField(
                  label: 'ชื่อร้านค้า / แบรนด์ (Shop or Brand)',
                  controller: brandCtrl,
                  icon: CupertinoIcons.bag_fill,
                  hint: 'เช่น Wallcraft Marble Studio',
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        label: 'เบอร์โทรติดต่อ',
                        controller: phoneCtrl,
                        icon: CupertinoIcons.phone_fill,
                        hint: '081-234-5678',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFormField(
                        label: 'LINE ID หน้าร้าน',
                        controller: lineCtrl,
                        icon: CupertinoIcons.chat_bubble_fill,
                        hint: '@yourbrand',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Custom Avatar Image URL Field
                _buildFormField(
                  label: 'ลิงก์รูปภาพโปรไฟล์ (Custom Image URL)',
                  controller: avatarUrlCtrl,
                  icon: CupertinoIcons.photo,
                  hint: 'https://example.com/my-photo.jpg',
                  onChanged: (val) {
                    if (val.trim().isNotEmpty) {
                      setModalState(() => tempAvatar = val.trim());
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Email Account Row (Google Verified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E5DD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.mail_solid, size: 16, color: Color(0xFF6E746F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _email,
                          style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF6E746F)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF5F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 11, color: Color(0xFF1F7A54)),
                            const SizedBox(width: 3),
                            Text(
                              'ยืนยันแล้ว',
                              style: GoogleFonts.prompt(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F7A54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFECE9E0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'ยกเลิก',
                            style: GoogleFonts.prompt(
                              color: const Color(0xFF6E746F),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () async {
                            final newName = nameCtrl.text.trim();
                            if (newName.isNotEmpty) {
                              try {
                                await AuthService.updateProfile(
                                  displayName: newName,
                                  avatarUrl: tempAvatar,
                                );
                              } catch (_) {}
                              setState(() {
                                _displayName = newName;
                                _avatarUrl = tempAvatar;
                                _brandName = brandCtrl.text.trim();
                                _phoneNumber = phoneCtrl.text.trim();
                                _lineId = lineCtrl.text.trim();
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Color(0xFF1F7A54), size: 18),
                                        SizedBox(width: 8),
                                        Text('บันทึกข้อมูลโปรไฟล์และแบรนด์เรียบร้อยแล้วครับ'),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF1B2820),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B2820),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'บันทึกการแก้ไข',
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.prompt(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1B2820)),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.prompt(fontSize: 13, color: const Color(0xFF1B2820)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.prompt(fontSize: 12.5, color: const Color(0xFF888E89)),
            prefixIcon: Icon(icon, size: 16, color: const Color(0xFF6E746F)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E2D9))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E2D9))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1F7A54), width: 1.5)),
          ),
        ),
      ],
    );
  }

  // ── 2. Storage Breakdown Sheet ──
  void _openStorageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายละเอียดพื้นที่จัดเก็บ',
                  style: GoogleFonts.prompt(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ใช้ไปแล้ว (Used):', style: GoogleFonts.prompt(fontSize: 13, color: const Color(0xFF6E746F))),
                Text(
                  '${_usedStorageMb.toStringAsFixed(1)} MB',
                  style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF17221C)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('โควต้ารวม (Free Tier):', style: GoogleFonts.prompt(fontSize: 13, color: const Color(0xFF6E746F))),
                Text(
                  '${_totalStorageQuotaMb.toStringAsFixed(0)} MB',
                  style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B2820)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_usedStorageMb / _totalStorageQuotaMb).clamp(0.01, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFF0EFE9),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F7A54)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '• พื้นที่จัดเก็บโควตาเริ่มต้นในแพ็กเกจฟรีคือ 100 MB (อัปโหลดเกินได้ แต่จะเริ่มมีโฆษณาผู้สนับสนุน)\n• หากต้องการพื้นที่ขนาดใหญ่ 5 GB ขึ้นไป ปลดล็อกลายน้ำ และไม่มีโฆษณา สามารถอัปเกรดเป็นแพ็กเกจ Pro เพียง ฿49/เดือน เท่านั้นครับ',
              style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF6E746F), height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openProUpgradeSheet();
                },
                icon: const Icon(CupertinoIcons.sparkles, size: 16, color: Color(0xFFFDE68A)),
                label: Text(
                  'ดูแพ็กเกจอัปเกรดพื้นที่ & ฟีเจอร์ Pro',
                  style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── 3. Pro Upgrade Sheet (แพ็กเกจ & ชำระเงินด้วย RevenueCat In-App Purchase) ──
  void _openProUpgradeSheet() {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    bool isYearly = true;
    int selectedPlanIndex = 0;
    bool isProcessingPayment = false;
    final pageController = PageController(viewportFraction: 0.86);

    const plans = [
      _PricingPlan(
        id: 'pro',
        name: 'Pro',
        title: 'แพ็กเกจ Pro (สุดคุ้ม 49.-)',
        badge: '⭐ สุดคุ้ม แนะนำ',
        monthlyPrice: '฿49 / เดือน',
        yearlyPrice: '฿490 / ปี',
        yearlyDiscount: 'เฉลี่ย ~40 บ./เดือน • แถมฟรี 2 เดือน 🔥',
        storage: '5 GB บนคลาวด์',
        features: [
          'พื้นที่จัดเก็บบนคลาวด์ขนาดใหญ่ 5 GB',
          'ไม่มีโฆษณาในเล่มสมุด (Ad-Free 100%)',
          'ปลดล็อกลายน้ำ Pedebook ออกจากเล่มสมุด',
          'ระบบล็อกรหัสผ่าน (Password Protection) ราคาส่ง',
          'สถิติเปิดอ่านแต่ละหน้า (หน้าไหนคนอ่านนานสุด)',
          'เปิด/ปิด ปุ่มดาวน์โหลดไฟล์ PDF ต้นฉบับได้',
        ],
      ),
      _PricingPlan(
        id: 'ultra',
        name: 'Ultra',
        title: 'แพ็กเกจ Ultra (ยอดนิยม 199.-)',
        badge: '🔥 ยอดนิยม ขายดี',
        monthlyPrice: '฿199 / เดือน',
        yearlyPrice: '฿1,990 / ปี',
        yearlyDiscount: 'เฉลี่ย ~165 บ./เดือน • แถมฟรี 2 เดือน 🔥',
        storage: '50 GB คลาวด์ SaaS',
        features: [
          'พื้นที่ขนาดใหญ่พิเศษ 50 GB',
          'ทุกฟังก์ชันของแพ็กเกจ Pro ครบถ้วน',
          'ใส่โลโก้แบรนด์ของตัวเอง (Custom Branding)',
          'แดชบอร์ด Heatmap วิเคราะห์เวลารายหน้าละเอียด',
          'ปุ่มสั่งซื้อด่วน (Call-to-Action) เชื่อม LINE OA',
          'Priority CDN ความเร็วสูงสุดระดับ Global Edge',
        ],
      ),
      _PricingPlan(
        id: 'business',
        name: 'Business',
        title: 'แพ็กเกจ Business (ทีม 599.-)',
        badge: '🏢 องค์กร & ทีม',
        monthlyPrice: '฿599 / เดือน',
        yearlyPrice: '฿5,990 / ปี',
        yearlyDiscount: 'เฉลี่ย ~499 บ./เดือน • แถมฟรี 2 เดือน 🔥',
        storage: '300 GB ระดับองค์กร',
        features: [
          'พื้นที่จัดเก็บระดับองค์กร 300 GB',
          'ระบบเชิญทีมงาน (Team Collaboration) สูงสุด 10 คน',
          'กำหนดสิทธิ์สมาชิก (Owner, Admin, Editor, Viewer)',
          'ทุกฟังก์ชันของแพ็กเกจ Ultra',
          'ส่งออกสถิติรายงาน (CSV / Excel)',
          'ทีมงานดูแลและให้คำปรึกษาด่วนพิเศษผ่าน LINE',
        ],
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFBFBF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
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
                const SizedBox(height: 14),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'เลือกแพ็กเกจที่ลงตัวกับธุรกิจ',
                                style: GoogleFonts.prompt(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF17221C),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F7A54).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'OFFICIAL',
                                  style: GoogleFonts.prompt(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F7A54),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'แผนบริการที่โปร่งใส ชำระปลอดภัยผ่าน RevenueCat',
                            style: GoogleFonts.prompt(
                              fontSize: 11.5,
                              color: const Color(0xFF6E746F),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFFC7C2B4), size: 24),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Billing Cycle Switcher
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E4DB),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => isYearly = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !isYearly ? const Color(0xFF243129) : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              'ชำระรายเดือน',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.prompt(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !isYearly ? const Color(0xFFE8DCC7) : const Color(0xFF6E746F),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => isYearly = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isYearly ? const Color(0xFF243129) : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ชำระรายปี',
                                  style: GoogleFonts.prompt(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isYearly ? const Color(0xFFE8DCC7) : const Color(0xFF6E746F),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F7A54),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'แถม 2 ด. 🔥',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
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
                const SizedBox(height: 14),

                // Horizontal Swipe Cards (การ์ดเลื่อนซ้ายขวา)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: pageController,
                          itemCount: plans.length,
                          onPageChanged: (idx) {
                            setModalState(() {
                              selectedPlanIndex = idx;
                            });
                          },
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            final isCurrent = index == selectedPlanIndex;
                            return GestureDetector(
                              onTap: () {
                                if (!isCurrent) {
                                  pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isCurrent ? const Color(0xFFFAF9F5) : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isCurrent ? const Color(0xFF1F7A54) : const Color(0xFFE2DFD5),
                                    width: isCurrent ? 2.0 : 1.0,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF1F7A54).withValues(alpha: 0.12),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: isCurrent ? const Color(0xFF1F7A54) : const Color(0xFFEAE7DE),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              plan.badge,
                                              style: GoogleFonts.prompt(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrent ? Colors.white : const Color(0xFF6E746F),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF3F0),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              plan.storage,
                                              style: GoogleFonts.prompt(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF1F7A54),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        plan.title,
                                        style: GoogleFonts.prompt(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF17221C),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            isYearly ? plan.yearlyPrice : plan.monthlyPrice,
                                            style: GoogleFonts.prompt(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF1F7A54),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isYearly) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          plan.yearlyDiscount,
                                          style: GoogleFonts.prompt(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      const Divider(height: 1, color: Color(0xFFE8E5DD)),
                                      const SizedBox(height: 10),
                                      ...plan.features.map(
                                        (feat) => Padding(
                                          padding: const EdgeInsets.only(bottom: 7),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                CupertinoIcons.checkmark_circle_fill,
                                                size: 15,
                                                color: Color(0xFF1F7A54),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  feat,
                                                  style: GoogleFonts.prompt(
                                                    fontSize: 12,
                                                    color: const Color(0xFF374151),
                                                    height: 1.35,
                                                  ),
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
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Carousel Indicators (Dots)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          plans.length,
                          (idx) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3.5),
                            width: selectedPlanIndex == idx ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: selectedPlanIndex == idx
                                  ? const Color(0xFF1F7A54)
                                  : const Color(0xFFD6D2C4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Bottom Action Bar: In-App Purchase via RevenueCat
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFECE9E0))),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isProcessingPayment
                              ? null
                              : () async {
                                  final activePlan = plans[selectedPlanIndex];
                                  setModalState(() => isProcessingPayment = true);
                                  HapticFeedback.mediumImpact();

                                  final result = await RevenueCatService.instance.purchasePlan(
                                    planId: activePlan.id,
                                    isYearly: isYearly,
                                  );

                                  setModalState(() => isProcessingPayment = false);

                                  if (result['success'] == true) {
                                    HapticFeedback.heavyImpact();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      setState(() {
                                        _currentPlan = activePlan.id;
                                        _currentPlanDisplay = '${activePlan.title} • ${activePlan.storage}';
                                      });
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'ยินดีด้วยครับ! สมัครสมาชิก ${activePlan.title} สำเร็จแล้ว 🎉',
                                                  style: GoogleFonts.prompt(fontSize: 12.5, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFF1F7A54),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } else if (result['cancelled'] != true) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ?? 'เกิดข้อผิดพลาดในการชำระเงิน กรุณาลองใหม่อีกครั้ง',
                                          style: GoogleFonts.prompt(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F7A54),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: isProcessingPayment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(CupertinoIcons.sparkles, size: 17, color: Color(0xFFFDE68A)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'สมัครสมาชิก ${plans[selectedPlanIndex].name} (${isYearly ? plans[selectedPlanIndex].yearlyPrice : plans[selectedPlanIndex].monthlyPrice})',
                                      style: GoogleFonts.prompt(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '🔒 ปลอดภัยผ่าน RevenueCat • ยกเลิกได้ตลอดเวลา',
                            style: GoogleFonts.prompt(fontSize: 9.5, color: const Color(0xFF888E89)),
                          ),
                          InkWell(
                            onTap: () async {
                              final restored = await RevenueCatService.instance.restorePurchases();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    restored ? 'กู้คืนการซื้อสำเร็จแล้ว' : 'ไม่พบรายการที่เคยซื้อ',
                                    style: GoogleFonts.prompt(fontSize: 12),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'กู้คืนการซื้อ (Restore)',
                              style: GoogleFonts.prompt(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F7A54),
                                decoration: TextDecoration.underline,
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
          ),
        ),
      ),
    );
  }

  // ── 6. Rating & Feedback Dialog ──
  void _openRateAppDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: const [
            Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 8),
            Text('ให้คะแนน Pedebook', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'ชื่นชอบการสร้างแค็ตตาล็อก 3D Flipbook ด้วย Pedebook ไหมครับ? ร่วมให้ 5 ดาวเพื่อเป็นกำลังใจให้ทีมงานพัฒนาฟีเจอร์ใหม่ๆ อย่างต่อเนื่อง!',
          style: GoogleFonts.prompt(fontSize: 12.5, color: const Color(0xFF6E746F), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ไว้ทีหลัง', style: GoogleFonts.prompt(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ขอบพระคุณสำหรับข้อเสนอแนะและกำลังใจครับนายครับ! ⭐⭐⭐⭐⭐'),
                  backgroundColor: const Color(0xFF1B2820),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2820),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('ให้ 5 ดาว ⭐', style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── 7. Help & Support Sheet ──
  void _openHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ศูนย์ช่วยเหลือ & ติดต่อทีมงาน',
                  style: GoogleFonts.prompt(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildContactItem(
              icon: CupertinoIcons.chat_bubble_2_fill,
              title: 'LINE Official Account',
              detail: '@pedebook (มีเจ้าหน้าที่คอยดูแลตลอด 24 ชม.)',
              color: const Color(0xFF06C755),
            ),
            const SizedBox(height: 10),
            _buildContactItem(
              icon: CupertinoIcons.mail_solid,
              title: 'อีเมลฝ่ายบริการลูกค้า',
              detail: 'support@pedebook.com',
              color: const Color(0xFF243129),
            ),
            const SizedBox(height: 10),
            _buildContactItem(
              icon: CupertinoIcons.question_circle_fill,
              title: 'คู่มือการใช้งาน & คำถามที่พบบ่อย',
              detail: 'อ่านวิธีแปลงไฟล์ PDF และปรับแต่ง 3D Flipbook',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── 8. Privacy Policy Sheet ──
  void _openPrivacySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'นโยบายความเป็นส่วนตัว',
                    style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pedebook Privacy Policy & Terms of Service',
                style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF755A47)),
              ),
              const SizedBox(height: 14),
              Text(
                '1. การรักษาความปลอดภัยข้อมูล:\nไฟล์เอกสาร PDF และข้อมูลผู้อ่านทั้งหมดของคุณจะได้รับการเข้ารหัสด้วยมาตรฐานสากลบน Cloud Server ชั้นนำระดับโลก\n\n'
                '2. การนับสถิติผู้อ่าน (Analytics):\nระบบจำแนกผู้ใช้งานโดยใช้ Fingerprint ไม่มีการจัดเก็บข้อมูลส่วนบุคคลที่เป็นความลับของผู้อ่าน\n\n'
                '3. สิทธิ์การเป็นเจ้าของผลงาน:\nไฟล์ PDF และเนื้อหาแค็ตตาล็อกทั้งหมดที่คุณอัปโหลด เป็นลิขสิทธิ์ของคุณ 100% Pedebook ไม่มีสิทธิ์นำไปจำหน่ายหรือดัดแปลงใดๆ\n\n'
                '4. การสนับสนุนและคุ้มครองผู้ใช้งาน:\nทีมงานพร้อมให้ความช่วยเหลือและดูแลความปลอดภัยตลอดอายุการใช้งาน',
                style: GoogleFonts.prompt(fontSize: 12.5, color: const Color(0xFF6E746F), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 9. Logout Handler ──
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.88,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2DFD5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF17221C).withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Center(
                    child: Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ยืนยันการออกจากระบบ',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF17221C),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'คุณต้องการออกจากระบบ Pedebook หรือไม่?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(
                    fontSize: 12.5,
                    color: const Color(0xFF6E746F),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFD9D7CD), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'ยกเลิก',
                            style: GoogleFonts.prompt(
                              color: const Color(0xFF6E746F),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'ออกจากระบบ',
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBFBF8),
        body: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              Text(
                'ข้อมูลบัญชี',
                style: GoogleFonts.prompt(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF17221C),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'จัดการโปรไฟล์และแพ็กเกจการใช้งานทั้งหมดในแอป',
                style: GoogleFonts.prompt(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // ── 1. Profile Hero Card ──
              InkWell(
                onTap: _openEditProfileSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E2D9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1F7A54), width: 2),
                        ),
                        child: ClipOval(
                          child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? Image.network(
                                  _avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _buildDefaultAvatar(),
                                )
                              : _buildDefaultAvatar(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _displayName,
                                    style: GoogleFonts.prompt(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF17221C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F7A54).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'แก้ไข',
                                    style: GoogleFonts.prompt(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _email,
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentPlanDisplay,
                              style: GoogleFonts.prompt(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _currentPlan == 'free' ? const Color(0xFF9A7257) : const Color(0xFF1F7A54),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── 2. Storage Quota Card ──
              InkWell(
                onTap: _openStorageSheet,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E2D9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.cloud, size: 16, color: Color(0xFF243129)),
                              const SizedBox(width: 6),
                              Text(
                                'พื้นที่จัดเก็บแค็ตตาล็อก',
                                style: GoogleFonts.prompt(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF17221C),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${_usedStorageMb.toStringAsFixed(1)} MB / ${_totalStorageQuotaMb.toStringAsFixed(0)} MB',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.chevron_right, size: 12, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_usedStorageMb / _totalStorageQuotaMb).clamp(0.01, 1.0),
                          minHeight: 5.5,
                          backgroundColor: const Color(0xFFF0EFE9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F7A54)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'เหลือพื้นที่อีก ${(_totalStorageQuotaMb - _usedStorageMb).clamp(0.0, 100.0).toStringAsFixed(1)} MB แตะเพื่อดูรายละเอียด',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── 4. Package & Plans Banner ──
              InkWell(
                onTap: _openProUpgradeSheet,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B2820), Color(0xFF26382E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A059).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC5A059).withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Text('👑', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'แพ็กเกจและการอัปเกรด (Plans)',
                              style: GoogleFonts.prompt(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE8DCC7),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Pro ฿49 • Ultra ฿199 • ปลดล็อกลายน้ำ 5GB+',
                              style: GoogleFonts.prompt(
                                fontSize: 10.5,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A059),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ดูราคา & แพ็กเกจ',
                          style: GoogleFonts.prompt(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF17221C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── 5. Support & Legal Section ──
              _buildSectionHeader('ศูนย์ช่วยเหลือและการสนับสนุน', CupertinoIcons.info_circle_fill),
              const SizedBox(height: 8),

              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E2D9)),
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: CupertinoIcons.phone_circle,
                        title: 'ศูนย์ช่วยเหลือ & ติดต่อทีมงาน',
                        subtitle: 'LINE Official และฝ่ายบริการลูกค้า 24 ชม.',
                        onTap: _openHelpSheet,
                      ),
                      const Divider(height: 1, indent: 52),
                      _buildListTile(
                        icon: CupertinoIcons.star_fill,
                        title: 'ให้คะแนนแอปและรีวิว 5 ดาว',
                        subtitle: 'ร่วมเป็นกำลังใจให้ทีมงานพัฒนา Pedebook',
                        onTap: _openRateAppDialog,
                      ),
                      const Divider(height: 1, indent: 52),
                      _buildListTile(
                        icon: CupertinoIcons.shield_lefthalf_fill,
                        title: 'นโยบายความเป็นส่วนตัว & เงื่อนไข',
                        subtitle: 'อ่านข้อกำหนดและการคุ้มครองข้อมูลในแอป',
                        onTap: _openPrivacySheet,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 8. Sign Out Card ──
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: ListTile(
                    leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.red, size: 18),
                    title: Text(
                      'ออกจากระบบ',
                      style: GoogleFonts.prompt(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.red, size: 14),
                    onTap: _handleLogout,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Version Footer
              Center(
                child: Text(
                  'Pedebook App v1.0.0 (iOS & Android Edition)\nลิขสิทธิ์แท้โดยทีมงาน Pedebook',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(fontSize: 10.5, color: Colors.grey.shade400, height: 1.5),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1B2820)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF17221C),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF243129),
      child: Center(
        child: Text(
          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'P',
          style: const TextStyle(
            color: Color(0xFFE8DCC7),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String detail,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E5DD)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B2820)),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailingWidget,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1B2820), size: 17),
      ),
      title: Text(
        title,
        style: GoogleFonts.prompt(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1B2820),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.prompt(fontSize: 10.5, color: Colors.grey.shade500),
      ),
      trailing: trailingWidget ?? const Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 14),
      onTap: onTap,
    );
  }
}

class _PricingPlan {
  final String id;
  final String name;
  final String title;
  final String badge;
  final String monthlyPrice;
  final String yearlyPrice;
  final String yearlyDiscount;
  final String storage;
  final List<String> features;

  const _PricingPlan({
    required this.id,
    required this.name,
    required this.title,
    required this.badge,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlyDiscount,
    required this.storage,
    required this.features,
  });
}
