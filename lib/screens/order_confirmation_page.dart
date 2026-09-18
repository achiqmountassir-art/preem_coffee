import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/placed_order.dart';

/// Shown after Supabase successfully creates a pending order.
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({
    super.key,
    required this.order,
    required this.onBackToHome,
  });

  final PlacedOrder order;
  final VoidCallback onBackToHome;

  static const Color _cream = Color(0xFFF5E6D3);
  static const Color _espresso = Color(0xFF2C1810);
  static const Color _coffeeBrown = Color(0xFF8B4513);
  static const Color _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              Text(
                'PREEM COFFEE',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _espresso,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _espresso.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _gold,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Confirmed',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _espresso,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Order #${order.orderNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _coffeeBrown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your order has been received.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                  color: _espresso.withValues(alpha: 0.58),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _espresso.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Status', value: order.status.label),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Total',
                      value: '${order.total.toStringAsFixed(0)} MAD',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const ValueKey('back-to-home'),
                  onPressed: onBackToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _coffeeBrown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'BACK TO HOME',
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
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF2C1810).withValues(alpha: 0.55),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C1810),
          ),
        ),
      ],
    );
  }
}
