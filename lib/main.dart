import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'backend/supabase_bootstrap.dart';
import 'admin/admin_gate.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const PreemCoffeeApp());
}

/// Root application widget for PREEM COFFEE.
class PreemCoffeeApp extends StatelessWidget {
  const PreemCoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PREEM COFFEE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/admin') {
          return MaterialPageRoute<void>(
            builder: (_) => const AdminGate(),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const WelcomeScreenHost(),
        );
      },
    );
  }
}

/// Host widget that manages language selection state for [WelcomeScreen].
class WelcomeScreenHost extends StatefulWidget {
  const WelcomeScreenHost({super.key});

  @override
  State<WelcomeScreenHost> createState() => _WelcomeScreenHostState();
}

class _WelcomeScreenHostState extends State<WelcomeScreenHost> {
  String? _selectedLanguage;

  void _onLanguageSelected(String code) {
    setState(() => _selectedLanguage = code);
  }

  void _onStartOrdering() {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please choose a language first',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      selectedLanguage: _selectedLanguage,
      onLanguageSelected: _onLanguageSelected,
      onStartOrdering: _onStartOrdering,
    );
  }
}
