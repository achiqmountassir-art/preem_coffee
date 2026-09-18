import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_tables.dart';
import '../models/cart_item.dart';
import '../models/placed_order.dart';

/// Creates a pending order + line items in Supabase.
///
/// Cart → create order → create order_items → status = pending.
class OrderService {
  OrderService({this._client});

  final SupabaseClient? _client;

  /// Private getter to access the client safely.
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Maps local [CartItem]s to the format expected by the Supabase RPC.
  Future<PlacedOrder> placePendingOrderFromCart(List<CartItem> items) {
    return placePendingOrder(
      items
          .map(
            (item) => OrderLineInput(
              productName: item.product.name,
              price: item.product.priceMad,
              quantity: item.quantity,
            ),
          )
          .toList(),
    );
  }

  /// Calls the `place_pending_order` PostgreSQL function.
  Future<PlacedOrder> placePendingOrder(List<OrderLineInput> items) async {
    if (items.isEmpty) {
      throw ArgumentError('Cannot place an empty order.');
    }

    final response = await _supabase.rpc(
      SupabaseRpcs.placePendingOrder,
      params: {
        'p_items': items.map((item) => item.toJson()).toList(),
      },
    );

    if (response == null) {
      throw Exception('Failed to receive a response from the server.');
    }

    final json = Map<String, dynamic>.from(response as Map);
    return PlacedOrder.fromJson(json);
  }
}
