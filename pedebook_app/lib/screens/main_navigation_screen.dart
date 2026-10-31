import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF1E2A22),
              unselectedItemColor: const Color(0xFF9E9D97),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 10.5,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.book, size: 21),
                  activeIcon: Icon(CupertinoIcons.book_fill, size: 21),
                  label: 'สมุดของฉัน',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.chart_bar_alt_fill, size: 21),
                  activeIcon: Icon(CupertinoIcons.chart_bar_alt_fill, size: 21),
                  label: 'สถิติ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.qrcode, size: 21),
                  activeIcon: Icon(CupertinoIcons.qrcode_viewfinder, size: 21),
                  label: 'สตูดิโอ QR',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person_crop_circle, size: 21),
                  activeIcon: Icon(CupertinoIcons.person_crop_circle_fill, size: 21),
                  label: 'บัญชี',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
