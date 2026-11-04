import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/supabase_service.dart';
import 'services/revenuecat_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase init warning: $e');
  }
  try {
    await RevenueCatService.instance.initialize();
  } catch (e) {
    debugPrint('RevenueCat init warning: $e');
  }
  runApp(const PedebookApp());
}

class PedebookApp extends StatelessWidget {
  const PedebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.promptTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      title: 'Pedebook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBFBF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B2820),
          primary: const Color(0xFF1B2820),
          secondary: const Color(0xFF1F7A54),
          surface: Colors.white,
          surfaceContainerLowest: const Color(0xFFFBFBF8),
          surfaceContainerLow: const Color(0xFFF5F3ED),
        ),
        textTheme: baseTextTheme.apply(
          bodyColor: const Color(0xFF15221B),
          displayColor: const Color(0xFF15221B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFBFBF8),
          foregroundColor: Color(0xFF15221B),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        splashFactory: NoSplash.splashFactory,
      ),
      home: const SplashScreen(),
    );
  }
}
