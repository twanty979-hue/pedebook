import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/google_logo.dart';
import '../widgets/pedebook_logo.dart';
import 'main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'std.65122420112@ubru.ac.th');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.signInWithGoogle();
      if (!success && mounted) {
        setState(() {
          _errorMessage = 'ไม่สามารถเชื่อมต่อกับ Google ได้ กรุณาลองใหม่อีกครั้ง';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบด้วย Google: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้งครับ';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _quickFillDemo() {
    _emailController.text = 'demo@pedebook.com';
    _passwordController.text = '123456';
    _handleLogin();
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  Widget _buildBrandIcon() {
    return const PedebookLogo(size: 46, borderRadius: 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2DFD5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF243129).withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Brand Logo Lockup (Exact match with website) ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBrandIcon(),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pedebook',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF17221C),
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Digital Flipbook Platform',
                                style: GoogleFonts.prompt(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9A7257),
                                  letterSpacing: 0.5,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── 2. Greeting Header ──
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.prompt(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF17221C),
                          ),
                          children: const [
                            TextSpan(text: 'ยินดีต้อนรับ '),
                            TextSpan(
                              text: 'กลับมาครับ',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF9A7257),
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'เข้าสู่ระบบเพื่อจัดการและเผยแพร่แค็ตตาล็อกของคุณ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error Box
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── 3. Email Field ──
                      Text(
                        'อีเมล',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF755A47),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD9D7CD)),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 13.5, color: Color(0xFF17221C)),
                          decoration: InputDecoration(
                            hintText: 'example@email.com',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'กรุณากรอกอีเมล';
                            }
                            if (!val.contains('@')) {
                              return 'รูปแบบอีเมลไม่ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 4. Password Field ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'รหัสผ่าน',
                            style: GoogleFonts.prompt(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF755A47),
                              letterSpacing: 0.5,
                            ),
                          ),
                          InkWell(
                            onTap: _quickFillDemo,
                            child: Text(
                              'ใช้บัญชี Demo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF9A7257),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD9D7CD)),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 13.5, color: Color(0xFF17221C)),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'กรุณากรอกรหัสผ่าน';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 5. Primary Submit Button (เข้าสู่ระบบ) ──
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'เข้าสู่ระบบ',
                                style: GoogleFonts.prompt(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // ── 6. Clean Divider (── หรือเข้าสู่ระบบด้วย ──) ──
                      Row(
                        children: [
                          Expanded(child: Divider(color: const Color(0xFFE2DFD5), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'หรือเข้าสู่ระบบด้วย',
                              style: GoogleFonts.prompt(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF755A47),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: const Color(0xFFE2DFD5), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── 7. Google Sign-In Button (4-Color Vector) ──
                      OutlinedButton(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD9D7CD), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const GoogleLogoWidget(size: 19),
                            const SizedBox(width: 10),
                            Text(
                              'ดำเนินการต่อด้วย Google',
                              style: GoogleFonts.prompt(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF17221C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 8. Register & Guest Links ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ยังไม่มีบัญชีใช่หรือไม่? ',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'สร้างบัญชีฟรี',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _continueAsGuest,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade500,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 24),
                          ),
                          child: const Text(
                            'เข้าดูตัวอย่างแบบผู้มาเยือน (Guest Mode) →',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
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
    );
  }
}
