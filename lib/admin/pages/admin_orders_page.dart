import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_order.dart';
import '../../models/order_status.dart';
import '../../services/admin_order_service.dart';
import '../admin_colors.dart';
import '../admin_notification_sound.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key, this.orderService});

  final AdminOrderService? orderService;

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  static const _filters = ['Pending', 'Accepted', 'Cancelled'];

  late final AdminOrderService _orderService;
  List<AdminOrder> _orders = const [];
  String? _error;
  bool _loading = true;
  int _filterIndex = 0;
  String? _bannerText;
  final Set<String> _notifiedPendingIds = {};
  final Set<String> _busyIds = {};
  RealtimeChannel? _channel;
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? AdminOrderService();
    _load(initial: true);
    _channel = _orderService.subscribeToOrders(
      channelName: 'admin-orders-page',
      onChange: _onRealtimeChange,
    );
  }

  void _onRealtimeChange() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      _load();
    });
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final orders = await _orderService.fetchOrders();
      if (!mounted) return;

      final pending = orders
          .where((order) => order.status == OrderStatus.pending)
          .toList();

      String? banner;
      var playSound = false;

      if (initial) {
        for (final order in pending) {
          _notifiedPendingIds.add(order.id);
        }
      } else {
        for (final order in pending) {
          if (!_notifiedPendingIds.contains(order.id)) {
            _notifiedPendingIds.add(order.id);
            banner = '🔔 New Order #${order.displayNumber}';
            playSound = true;
          }
        }
      }
      _notifiedPendingIds.removeWhere(
        (id) => !pending.any((order) => order.id == id),
      );

      setState(() {
        _orders = orders;
        _loading = false;
        _error = null;
        if (banner != null) _bannerText = banner;
      });

      if (playSound) {
        playAdminOrderNotificationSound();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _accept(AdminOrder order) async {
    setState(() => _busyIds.add(order.id));
    try {
      await _orderService.acceptOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.displayNumber} accepted'),
          backgroundColor: AdminColors.coffeeBrown,
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFA33B2B),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(order.id));
    }
  }

  Future<void> _cancel(AdminOrder order) async {
    setState(() => _busyIds.add(order.id));
    try {
      await _orderService.cancelOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.displayNumber} cancelled'),
          backgroundColor: AdminColors.coffeeBrown,
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFA33B2B),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(order.id));
    }
  }

  List<AdminOrder> get _filtered {
    final wanted = switch (_filterIndex) {
      1 => OrderStatus.accepted,
      2 => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
    return _orders.where((order) => order.status == wanted).toList();
  }

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
    return '$dd ${months[value.month - 1]} ${value.year} · $hh:$mm';
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    final channel = _channel;
    if (channel != null) {
      // Fire-and-forget unsubscribe.
      // ignore: discarded_futures
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 700 ? 32.0 : 20.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.espresso,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review pending tickets, then accept or cancel.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AdminColors.muted,
                  ),
                ),
                if (_bannerText != null) ...[
                  const SizedBox(height: 14),
                  Material(
                    color: AdminColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _bannerText!,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AdminColors.espresso,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _bannerText = null),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _filters.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: _FilterChip(
                          label: _filters[i],
                          selected: _filterIndex == i,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AdminColors.coffeeBrown,
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFA33B2B),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _load(initial: true),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : filtered.isEmpty
                              ? _EmptyOrders(
                                  label: switch (_filterIndex) {
                                    1 => 'No accepted orders',
                                    2 => 'No cancelled orders',
                                    _ => 'No pending orders',
                                  },
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final order = filtered[index];
                                    final isPending =
                                        order.status == OrderStatus.pending;
                                    return _OrderCard(
                                      order: order,
                                      dateLabel: _formatDate(order.createdAt),
                                      busy: _busyIds.contains(order.id),
                                      onAccept:
                                          isPending ? () => _accept(order) : null,
                                      onCancel:
                                          isPending ? () => _cancel(order) : null,
                                    );
                                  },
                                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AdminColors.coffeeBrown.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AdminColors.espresso,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.dateLabel,
    required this.busy,
    this.onAccept,
    this.onCancel,
  });

  final AdminOrder order;
  final String dateLabel;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AdminColors.espresso.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.displayNumber}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.espresso,
                  ),
                ),
              ),
              Text(
                '${order.total.toStringAsFixed(0)} MAD',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AdminColors.coffeeBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AdminColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}× ${item.productName}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AdminColors.espresso,
                      ),
                    ),
                  ),
                  Text(
                    '${item.price.toStringAsFixed(0)} MAD',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AdminColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          if (onAccept != null || onCancel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (onCancel != null)
                    OutlinedButton(
                      onPressed: busy ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFA33B2B),
                        side: const BorderSide(color: Color(0xFFA33B2B)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (onAccept != null)
                    FilledButton(
                      onPressed: busy ? null : onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminColors.coffeeBrown,
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Accept',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AdminColors.coffeeBrown : AdminColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AdminColors.espresso.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AdminColors.espresso,
        ),
      ),
    );
  }
}
