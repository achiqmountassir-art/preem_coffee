import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_order.dart';
import '../../models/order_status.dart';
import '../../services/admin_order_service.dart';
import '../admin_colors.dart';

/// Live café overview: counts + recent tickets from Supabase.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, this.orderService});

  final AdminOrderService? orderService;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final AdminOrderService _orderService;
  List<AdminOrder> _orders = const [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? AdminOrderService();
    _load();
    _channel = _orderService.subscribeToOrders(
      channelName: 'admin-orders-dashboard',
      onChange: _onRealtimeChange,
    );
  }

  void _onRealtimeChange() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    try {
      final orders = await _orderService.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  int _count(OrderStatus status) =>
      _orders.where((order) => order.status == status).length;

  List<AdminOrder> get _recent => _orders.take(8).toList();

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dd = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$dd ${months[value.month - 1]} · $hh:$mm';
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    final channel = _channel;
    if (channel != null) {
      // ignore: discarded_futures
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _loading ? '—' : '${_count(OrderStatus.pending)}';
    final accepted = _loading ? '—' : '${_count(OrderStatus.accepted)}';
    final cancelled = _loading ? '—' : '${_count(OrderStatus.cancelled)}';

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final horizontal = constraints.maxWidth >= 700 ? 32.0 : 20.0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A calm overview of café orders.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AdminColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 8),
                sliver: SliverToBoxAdapter(
                  child: wide
                      ? Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.notifications_active_rounded,
                                label: 'Pending',
                                value: pending,
                                subtitle: 'New orders',
                                accent: AdminColors.gold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle_rounded,
                                label: 'Accepted',
                                value: accepted,
                                subtitle: 'Ready for the bar',
                                accent: const Color(0xFF3D7A4A),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.cancel_rounded,
                                label: 'Cancelled',
                                value: cancelled,
                                subtitle: 'Not fulfilled',
                                accent: const Color(0xFFA33B2B),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _StatCard(
                              icon: Icons.notifications_active_rounded,
                              label: 'Pending',
                              value: pending,
                              subtitle: 'New orders',
                              accent: AdminColors.gold,
                            ),
                            const SizedBox(height: 12),
                            _StatCard(
                              icon: Icons.check_circle_rounded,
                              label: 'Accepted',
                              value: accepted,
                              subtitle: 'Ready for the bar',
                              accent: const Color(0xFF3D7A4A),
                            ),
                            const SizedBox(height: 12),
                            _StatCard(
                              icon: Icons.cancel_rounded,
                              label: 'Cancelled',
                              value: cancelled,
                              subtitle: 'Not fulfilled',
                              accent: const Color(0xFFA33B2B),
                            ),
                          ],
                        ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
                sliver: SliverToBoxAdapter(
                  child: _RecentOrdersPanel(
                    loading: _loading,
                    error: _error,
                    orders: _recent,
                    formatDate: _formatDate,
                    onRetry: _load,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AdminColors.espresso.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AdminColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AdminColors.espresso,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AdminColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({
    required this.loading,
    required this.error,
    required this.orders,
    required this.formatDate,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final List<AdminOrder> orders;
  final String Function(DateTime) formatDate;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AdminColors.espresso.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Orders',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AdminColors.espresso,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Latest tickets from the café.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AdminColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: AdminColors.coffeeBrown),
              ),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: const Color(0xFFA33B2B)),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            )
          else if (orders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 42,
                      color: AdminColors.coffeeBrown.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No orders yet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AdminColors.espresso,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final order in orders) ...[
              _RecentOrderRow(
                order: order,
                dateLabel: formatDate(order.createdAt),
              ),
              if (order != orders.last) const Divider(height: 20),
            ],
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({
    required this.order,
    required this.dateLabel,
  });

  final AdminOrder order;
  final String dateLabel;

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:
        return AdminColors.gold;
      case OrderStatus.accepted:
        return const Color(0xFF3D7A4A);
      case OrderStatus.cancelled:
        return const Color(0xFFA33B2B);
      default:
        return AdminColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemSummary = order.items.isEmpty
        ? 'No items'
        : order.items
            .map((item) => '${item.quantity}× ${item.productName}')
            .join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.displayNumber}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AdminColors.espresso,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                itemSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AdminColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AdminColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${order.total.toStringAsFixed(0)} MAD',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AdminColors.coffeeBrown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.status.label.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
