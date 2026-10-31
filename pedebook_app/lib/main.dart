import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase init warning: $e');
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
        scaffoldBackgroundColor: const Color(0xFFF6F4EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF243129),
          primary: const Color(0xFF243129),
          secondary: const Color(0xFF10B981),
          surface: Colors.white,
        ),
        textTheme: baseTextTheme.apply(
          bodyColor: const Color(0xFF17221C),
          displayColor: const Color(0xFF17221C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F4EE),
          foregroundColor: Color(0xFF17221C),
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
