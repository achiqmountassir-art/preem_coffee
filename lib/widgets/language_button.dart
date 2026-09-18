import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable language selection button for the welcome screen.
///
/// Displays a flag emoji and language label with a clean white card style.
/// Supports a selected state with a coffee-brown border highlight.
class LanguageButton extends StatelessWidget {
  const LanguageButton({
    super.key,
    required this.label,
    required this.flag,
    required this.onTap,
    this.isSelected = false,
  });

  /// Language name shown below the flag (e.g. "English").
  final String label;

  /// Flag emoji for the language (e.g. "🇺🇸").
  final String flag;

  /// Called when the user taps this language option.
  final VoidCallback onTap;

  /// Whether this language is currently selected.
  final bool isSelected;

  /// Coffee brown accent used for the selected border.
  static const Color _selectedBorderColor = Color(0xFF8B4513);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Scale flag and text based on screen width for smaller devices.
    final flagSize = screenWidth * 0.06;
    final labelSize = screenWidth * 0.028;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.035,
              horizontal: screenWidth * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _selectedBorderColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  flag,
                  style: TextStyle(fontSize: flagSize.clamp(20.0, 28.0)),
                ),
                SizedBox(height: screenWidth * 0.015),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: labelSize.clamp(10.0, 13.0),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
