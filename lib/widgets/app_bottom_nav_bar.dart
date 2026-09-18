import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared full-width bottom navigation for Home, Menu, Cart, and Profile.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.cartItemCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount;

  static const Color _coffeeBrown = Color(0xFF8B4513);
  static const Color _cream = Color(0xFFF5E6D3);
  static const Color _espresso = Color(0xFF2C1810);
  static const Color _gold = Color(0xFFC9A227);

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.menu_book_rounded, 'Menu'),
    (Icons.shopping_bag_outlined, 'Cart'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (index) {
              final (icon, label) = _items[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _cream : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NavIcon(
                          icon: icon,
                          color: isSelected
                              ? _coffeeBrown
                              : _espresso.withValues(alpha: 0.45),
                          badgeCount: index == 2 ? cartItemCount : 0,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? _coffeeBrown
                                : _espresso.withValues(alpha: 0.45),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: _gold,
                              shape: BoxShape.circle,
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
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.color,
    required this.badgeCount,
  });

  final IconData icon;
  final Color color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 24, color: color);
    if (badgeCount <= 0) return iconWidget;

    return Badge(
      backgroundColor: AppBottomNavBar._gold,
      textColor: const Color(0xFF2C1810),
      label: Text(
        badgeCount > 99 ? '99+' : '$badgeCount',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: iconWidget,
    );
  }
}
