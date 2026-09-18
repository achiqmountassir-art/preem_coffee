import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Placeholder profile screen — connect to auth / user data later.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5E6D3),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 64,
                color: const Color(0xFF8B4513).withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Profile',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C1810),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Profile settings coming soon',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2C1810).withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
