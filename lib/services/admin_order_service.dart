import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_tables.dart';
import '../models/admin_order.dart';
import '../models/order_status.dart';

class AdminOrderService {
  AdminOrderService({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<AdminOrder>> fetchOrders() async {
    final response = await _supabase
        .from(SupabaseTables.orders)
        .select(
          'id, order_number, status, total, created_at, '
          'order_items(id, product_id, product_name, price, quantity)',
        )
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(AdminOrder.fromJson).toList();
  }

  Future<AdminOrder> acceptOrder(String orderId) async {
    return _updatePendingStatus(orderId, OrderStatus.accepted);
  }

  Future<AdminOrder> cancelOrder(String orderId) async {
    return _updatePendingStatus(orderId, OrderStatus.cancelled);
  }

  Future<AdminOrder> _updatePendingStatus(
    String orderId,
    OrderStatus next,
  ) async {
    final response = await _supabase
        .from(SupabaseTables.orders)
        .update({'status': next.dbValue})
        .eq('id', orderId)
        .eq('status', OrderStatus.pending.dbValue)
        .select(
          'id, order_number, status, total, created_at, '
          'order_items(id, product_id, product_name, price, quantity)',
        )
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'Order could not be ${next.dbValue} (missing or not pending).',
      );
    }

    return AdminOrder.fromJson(Map<String, dynamic>.from(response));
  }

  RealtimeChannel? subscribeToOrders({
    required void Function() onChange,
    String channelName = 'admin-orders',
  }) {
    return _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseTables.orders,
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseTables.orders,
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
