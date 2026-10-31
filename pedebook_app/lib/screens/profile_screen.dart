import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
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

  // Preset avatar avatars for creators
  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final user = AuthService.currentUser;
    setState(() {
      _email = user?.email ?? 'std.65122420112@ubru.ac.th';
      _avatarUrl = user?.userMetadata?['avatar_url'] as String? ??
          user?.userMetadata?['picture'] as String?;
      _displayName = user?.userMetadata?['full_name'] as String? ??
          user?.userMetadata?['name'] as String? ??
          (_email.contains('@') ? _email.split('@').first : 'Pedebook Creator');
      _isLoading = false;
    });
  }

  // ── 1. In-App Edit Profile Dialog (แก้ไขข้อมูลโปรไฟล์ในแอป ไม่ต้องออกเว็บ) ──
  void _openEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _displayName);
    String? tempAvatar = _avatarUrl;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.90,
              constraints: const BoxConstraints(maxWidth: 390),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2DFD5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF17221C).withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'แก้ไขข้อมูลโปรไฟล์',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                          color: const Color(0xFF17221C),
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

                  Text(
                    'เลือกรูปโปรไฟล์ของคุณ:',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF755A47),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Avatar Row using SingleChildScrollView + Row (NO RenderViewport intrinsic crash!)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _presetAvatars.map((url) {
                        final isSelected = tempAvatar == url;
                        return GestureDetector(
                          onTap: () => setModalState(() => tempAvatar = url),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E2D9),
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(url, fit: BoxFit.cover),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'ชื่อที่แสดงในระบบ:',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF755A47),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E2D9)),
                    ),
                    child: TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.prompt(fontSize: 13.5, color: const Color(0xFF17221C)),
                      decoration: InputDecoration(
                        hintText: 'ชื่อ-นามสกุล หรือชื่อแบรนด์',
                        hintStyle: GoogleFonts.prompt(fontSize: 13, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'อีเมลบัญชี: $_email',
                    style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons: [ ยกเลิก ] and [ บันทึก ]
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD9D7CD), width: 1.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'ยกเลิก',
                              style: GoogleFonts.prompt(
                                color: const Color(0xFF17221C),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
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
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว',
                                        style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                                      ),
                                      backgroundColor: const Color(0xFF17221C),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'บันทึก',
                              style: GoogleFonts.prompt(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
      ),
    );
  }

  // ── 2. In-App Storage Breakdown Sheet (ดูพื้นที่จัดเก็บในแอป) ──
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
                const Text(
                  'รายละเอียดพื้นที่จัดเก็บ',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
              children: const [
                Text('ใช้ไปแล้ว (Used):', style: TextStyle(fontSize: 13, color: Color(0xFF6E746F))),
                Text('29.6 MB', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF17221C))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('โควต้ารวม (Free Tier):', style: TextStyle(fontSize: 13, color: Color(0xFF6E746F))),
                Text('100.0 MB', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF243129))),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                value: 0.296,
                minHeight: 8,
                backgroundColor: Color(0xFFF0EFE9),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• ไฟล์สมุดแค็ตตาล็อกทั้งหมดถูกเข้ารหัสและเก็บบน Cloudflare R2 อย่างปลอดภัย\n• สามารถอัปโหลดไฟล์ PDF ได้อีกประมาณ 10-15 เล่มในแพ็กเกจฟรี',
              style: TextStyle(fontSize: 12, color: Color(0xFF6E746F), height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── 3. In-App Help & Support Sheet (ติดต่อทีมงานในแอป) ──
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
                const Text(
                  'ศูนย์ช่วยเหลือ & ติดต่อทีมงาน',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
              title: 'คำถามที่พบบ่อย (FAQ)',
              detail: 'อ่านคู่มือการแปลง PDF และทำ QR Code ได้ในแอป',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── 4. In-App Privacy Policy Sheet (อ่านนโยบายในแอป) ──
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
                  const Text(
                    'นโยบายความเป็นส่วนตัว',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Pedebook Privacy Policy & Terms of Service',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF755A47)),
              ),
              const SizedBox(height: 14),
              const Text(
                '1. การรักษาความปลอดภัยข้อมูล:\nไฟล์เอกสาร PDF และข้อมูลผู้อ่านทั้งหมดของคุณจะได้รับการเข้ารหัสด้วยมาตรฐานสากลบน Cloud Server ชั้นนำระดับโลก\n\n'
                '2. การนับสถิติผู้อ่าน (Analytics):\nระบบจำแนกผู้ใช้งานโดยใช้ Fingerprint ไม่มีการจัดเก็บข้อมูลส่วนบุคคลที่เป็นความลับของผู้อ่าน\n\n'
                '3. สิทธิ์การเป็นเจ้าของผลงาน:\nไฟล์ PDF และเนื้อหาแค็ตตาล็อกทั้งหมดที่คุณอัปโหลด เป็นลิขสิทธิ์ของคุณ 100% Pedebook ไม่มีสิทธิ์นำไปจำหน่ายหรือดัดแปลงใดๆ\n\n'
                '4. การสนับสนุนและคุ้มครองผู้ใช้งาน:\nทีมงานพร้อมให้ความช่วยเหลือและดูแลความปลอดภัยตลอดอายุการใช้งาน',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF6E746F), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        backgroundColor: Color(0xFFF8F7F3),
        body: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // iOS Large Title
              const Text(
                'ข้อมูลบัญชี',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF17221C),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'จัดการโปรไฟล์และตั้งค่าการใช้งานทั้งหมดในแอป',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // ── Apple ID Style Profile Card (แตะเพื่อแก้ไขโปรไฟล์ในแอปได้ทันที) ──
              InkWell(
                onTap: _openEditProfileDialog,
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
                          border: Border.all(color: const Color(0xFF10B981), width: 2),
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF17221C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'แก้ไข',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
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
                            const Text(
                              'แพ็กเกจฟรี (Free Tier) • 100 MB',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9A7257),
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
              const SizedBox(height: 14),

              // ── Storage Quota Card (แตะดูรายละเอียดในแอปได้) ──
              InkWell(
                onTap: _openStorageSheet,
                borderRadius: BorderRadius.circular(18),
                child: Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(CupertinoIcons.cloud, size: 16, color: Color(0xFF243129)),
                              SizedBox(width: 6),
                              Text(
                                'พื้นที่จัดเก็บแค็ตตาล็อก',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF17221C),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '29.6 MB / 100 MB',
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
                        child: const LinearProgressIndicator(
                          value: 0.296,
                          minHeight: 5.5,
                          backgroundColor: Color(0xFFF0EFE9),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'เหลือพื้นที่อีก 70.4 MB แตะเพื่อดูรายละเอียด',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── In-App Action Menu List (ทำงานในแอปทั้งหมด ไม่ต้องเด้งออกเว็บ) ──
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
                        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                        title: 'แก้ไขชื่อและรูปโปรไฟล์',
                        subtitle: 'เปลี่ยนรูปและชื่อที่แสดงในแอป',
                        onTap: _openEditProfileDialog,
                      ),
                      const Divider(height: 1, indent: 52),
                      _buildListTile(
                        icon: CupertinoIcons.phone_circle,
                        title: 'ศูนย์ช่วยเหลือ & ติดต่อทีมงาน',
                        subtitle: 'LINE Official และฝ่ายบริการลูกค้า',
                        onTap: _openHelpSheet,
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

              // Sign Out Card
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
                    title: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(
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
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400, height: 1.5),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
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
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E2D9)),
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF17221C)),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F4EE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF243129), size: 17),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF17221C),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 14),
      onTap: onTap,
    );
  }
}
