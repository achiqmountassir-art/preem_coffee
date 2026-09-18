import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/menu_product.dart';
import 'product_image_view.dart';

/// Premium horizontal product card for the menu list.
class MenuProductCard extends StatefulWidget {
  const MenuProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  final MenuProduct product;
  final VoidCallback onAdd;

  @override
  State<MenuProductCard> createState() => _MenuProductCardState();
}

class _MenuProductCardState extends State<MenuProductCard> {
  bool _isPressed = false;

  static const Color _coffeeBrown = Color(0xFF8B4513);
  static const Color _espresso = Color(0xFF2C1810);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageSize = (screenWidth * 0.26).clamp(96.0, 120.0);

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _espresso.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ProductImageView(
                  source: widget.product.imageAsset,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    final gradient = widget.product.gradient;
                    return Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        gradient: gradient != null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gradient,
                              )
                            : null,
                        color: gradient == null
                            ? const Color(0xFF5D4037)
                            : null,
                      ),
                      child: Icon(
                        widget.product.category == 'Breakfast'
                            ? Icons.breakfast_dining_rounded
                            : Icons.local_cafe_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 36,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Name, description, price, add button
              Expanded(
                child: SizedBox(
                  height: imageSize,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _espresso,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          widget.product.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.4,
                            color: _espresso.withValues(alpha: 0.58),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${widget.product.priceMad.toStringAsFixed(0)} MAD',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _coffeeBrown,
                            ),
                          ),
                          const Spacer(),
                          _AddButton(
                            key: ValueKey('add-${widget.product.name}'),
                            onTap: () {
                              setState(() => _isPressed = true);
                              widget.onAdd();
                              Future.delayed(const Duration(milliseconds: 150), () {
                                if (mounted) setState(() => _isPressed = false);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF8B4513),
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      shadowColor: const Color(0xFF8B4513).withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
