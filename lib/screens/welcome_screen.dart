import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/language_button.dart';

/// Welcome / language-selection screen for PREEM COFFEE.
///
/// Displays a full-screen café background, brand logo, tagline,
/// language picker, and a primary "Start Ordering" call-to-action.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.selectedLanguage,
    this.onLanguageSelected,
    this.onStartOrdering,
  });

  /// Currently selected language code (e.g. "en", "fr", "ar").
  final String? selectedLanguage;

  /// Fired when the user picks a language.
  final ValueChanged<String>? onLanguageSelected;

  /// Fired when the user taps "START ORDERING".
  final VoidCallback? onStartOrdering;

  // ── Brand & asset paths ──────────────────────────────────────────────
  static const String _backgroundImage = 'assets/images/preem_cofee.jpg';
  static const String _logoImage = 'assets/images/logo.png';
  static const Color _coffeeBrown = Color(0xFF8B4513);
  static const Color _overlayColor = Color(0x99000000); // ~60% black

  @override
  Widget build(BuildContext context) {
    // MediaQuery gives us screen dimensions for responsive layout.
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final horizontalPadding = screenWidth * 0.06;

    // Logo scales with screen width but stays within sensible bounds.
    final logoSize = (screenWidth * 0.32).clamp(100.0, 140.0);

    // Headline font size adapts to screen width.
    final headlineSize = (screenWidth * 0.075).clamp(26.0, 36.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Full-screen background image ──────────────────
          Image.asset(
            _backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Fallback gradient when the asset is missing during dev.
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3E2723), Color(0xFF1B0E0A)],
                  ),
                ),
              );
            },
          ),

          // ── Layer 2: Dark overlay for text readability ───────────────
          Container(color: _overlayColor),

          // ── Layer 3: Scrollable content ────────────────────────────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  // Top spacing – proportional to screen height
                  SizedBox(height: screenHeight * 0.04),

                  // ── Top section: Circular logo ─────────────────────
                  _buildLogo(logoSize),

                  // Push middle content toward vertical center
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Middle section: Tagline ──────────────────
                        _buildTagline(headlineSize),
                      ],
                    ),
                  ),

                  // ── Bottom section: Language picker & CTA ──────────
                  _buildLanguageSection(context, screenWidth),
                  SizedBox(height: screenHeight * 0.025),

                  _buildStartButton(context),
                  SizedBox(height: screenHeight * 0.04),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Circular logo with white ring and soft drop shadow.
  Widget _buildLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: Image.asset(
          _logoImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF5D4037),
              child: Icon(
                Icons.coffee,
                size: size * 0.5,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Bold two-line tagline in Poppins.
  Widget _buildTagline(double fontSize) {
    return Text(
      'Fresh coffee.\nFresh moments.',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.3,
        letterSpacing: 0.5,
      ),
    );
  }

  /// "Choose your language" label + three equal-width language buttons.
  Widget _buildLanguageSection(BuildContext context, double screenWidth) {
    final languages = [
      ('en', 'English', '🇺🇸'),
      ('fr', 'Français', '🇫🇷'),
      ('ar', 'العربية', '🇲🇦'),
    ];

    return Column(
      children: [
        Text(
          'Choose your language',
          style: GoogleFonts.poppins(
            fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        SizedBox(height: screenWidth * 0.04),

        // Row of three equally-sized language buttons
        Row(
          children: [
            for (int i = 0; i < languages.length; i++) ...[
              if (i > 0) SizedBox(width: screenWidth * 0.03),
              LanguageButton(
                label: languages[i].$2,
                flag: languages[i].$3,
                isSelected: selectedLanguage == languages[i].$1,
                onTap: () => onLanguageSelected?.call(languages[i].$1),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Full-width primary CTA button.
  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onStartOrdering,
        style: ElevatedButton.styleFrom(
          backgroundColor: _coffeeBrown,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: _coffeeBrown.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'START ORDERING →',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
