import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'qr_studio_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
    QrStudioScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    (
      icon: CupertinoIcons.book,
      activeIcon: CupertinoIcons.book_fill,
      label: 'สมุดของฉัน',
    ),
    (
      icon: CupertinoIcons.chart_bar,
      activeIcon: CupertinoIcons.chart_bar_alt_fill,
      label: 'สถิติ',
    ),
    (
      icon: CupertinoIcons.qrcode,
      activeIcon: CupertinoIcons.qrcode_viewfinder,
      label: 'สตูดิโอ QR',
    ),
    (
      icon: CupertinoIcons.person_crop_circle,
      activeIcon: CupertinoIcons.person_crop_circle_fill,
      label: 'บัญชี',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              border: const Border(
                top: BorderSide(color: Color(0xFFEEEBE3), width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B2820).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final isSelected = _currentIndex == index;

                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_currentIndex != index) {
                            HapticFeedback.selectionClick();
                            setState(() => _currentIndex = index);
                          }
                        },
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1B2820).withValues(alpha: 0.06)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 21,
                                color: isSelected
                                    ? const Color(0xFF1B2820)
                                    : const Color(0xFF9EA39F),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.label,
                                style: GoogleFonts.prompt(
                                  fontSize: 10.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1B2820)
                                      : const Color(0xFF888E89),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
