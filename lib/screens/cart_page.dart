import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/cart_item.dart';
import '../widgets/product_image_view.dart';

/// Customer cart: quantities, totals, and Place Order.
class CartPage extends StatelessWidget {
  const CartPage({
    super.key,
    required this.items,
    required this.totalMad,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onClear,
    this.onPlaceOrder,
    this.isPlacingOrder = false,
  });

  final List<CartItem> items;
  final double totalMad;
  final ValueChanged<CartItem> onIncrease;
  final ValueChanged<CartItem> onDecrease;
  final ValueChanged<CartItem> onRemove;
  final VoidCallback onClear;
  final VoidCallback? onPlaceOrder;
  final bool isPlacingOrder;

  static const Color _cream = Color(0xFFF5E6D3);
  static const Color _espresso = Color(0xFF2C1810);
  static const Color _coffeeBrown = Color(0xFF8B4513);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _cream,
      child: SafeArea(
        child: items.isEmpty ? const _EmptyCart() : _buildFilledCart(context),
      ),
    );
  }

  Widget _buildFilledCart(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width * 0.06;
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Cart',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _espresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _espresso.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: isPlacingOrder ? null : onClear,
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    color: _coffeeBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _CartLine(
                item: item,
                onIncrease: () => onIncrease(item),
                onDecrease: () => onDecrease(item),
                onRemove: () => onRemove(item),
              );
            },
          ),
        ),
        _CheckoutBar(
          totalMad: totalMad,
          isPlacingOrder: isPlacingOrder,
          onPlaceOrder: onPlaceOrder,
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: const Color(0xFF8B4513).withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C1810),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add something delicious from the menu to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF2C1810).withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  static const Color _espresso = Color(0xFF2C1810);
  static const Color _coffeeBrown = Color(0xFF8B4513);

  @override
  Widget build(BuildContext context) {
    const imageSize = 88.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ProductImageView(
                source: item.product.imageAsset,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  final gradient = item.product.gradient;
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
                      color: gradient == null ? const Color(0xFF5D4037) : null,
                    ),
                    child: Icon(
                      item.product.category == 'Breakfast'
                          ? Icons.breakfast_dining_rounded
                          : Icons.local_cafe_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _espresso,
                          ),
                        ),
                      ),
                      IconButton(
                        key: ValueKey('cart-remove-${item.product.name}'),
                        onPressed: onRemove,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: _espresso.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${item.product.priceMad.toStringAsFixed(0)} MAD',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _espresso.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QuantityStepper(
                        productName: item.product.name,
                        quantity: item.quantity,
                        onIncrease: onIncrease,
                        onDecrease: onDecrease,
                      ),
                      const Spacer(),
                      Text(
                        '${item.lineTotalMad.toStringAsFixed(0)} MAD',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _coffeeBrown,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.productName,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  final String productName;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            key: ValueKey('cart-decrease-$productName'),
            icon: Icons.remove_rounded,
            onTap: onDecrease,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              key: ValueKey('cart-qty-$productName'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C1810),
              ),
            ),
          ),
          _StepperButton(
            key: ValueKey('cart-increase-$productName'),
            icon: Icons.add_rounded,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF8B4513),
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.totalMad,
    this.onPlaceOrder,
    this.isPlacingOrder = false,
  });

  final double totalMad;
  final VoidCallback? onPlaceOrder;
  final bool isPlacingOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2C1810).withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                '${totalMad.toStringAsFixed(0)} MAD',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8B4513),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              key: const ValueKey('place-order-button'),
              onPressed: isPlacingOrder ? () {} : onPlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF8B4513),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isPlacingOrder
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Placing order...',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'PLACE ORDER',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
