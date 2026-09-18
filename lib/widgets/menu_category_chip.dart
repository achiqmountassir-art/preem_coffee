import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Horizontally scrollable category pill for the menu page.
class MenuCategoryChip extends StatelessWidget {
  const MenuCategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color _coffeeBrown = Color(0xFF8B4513);
  static const Color _espresso = Color(0xFF2C1810);
  static const Color _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Material(
        color: isSelected ? _coffeeBrown : Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: isSelected ? 4 : 1,
        shadowColor: _coffeeBrown.withValues(alpha: 0.25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? _gold : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _espresso,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
