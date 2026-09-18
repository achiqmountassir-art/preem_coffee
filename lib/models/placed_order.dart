import 'order_status.dart';

class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final double total;
  final DateTime createdAt;

  factory PlacedOrder.fromJson(Map<String, dynamic> json) {
    return PlacedOrder(
      id: json['id'].toString(),
      orderNumber: json['order_number'].toString(),
      status: OrderStatus.fromDb(json['status'].toString()),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

/// Snapshot of a cart line for `place_pending_order`.
class OrderLineInput {
  const OrderLineInput({
    required this.productName,
    required this.price,
    required this.quantity,
    this.productId,
  });

  final String? productId;
  final String productName;
  final double price;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
    };
  }
}
