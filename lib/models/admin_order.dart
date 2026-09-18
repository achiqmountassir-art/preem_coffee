import 'order_status.dart';

class AdminOrderItem {
  const AdminOrderItem({
    required this.id,
    required this.productName,
    required this.price,
    required this.quantity,
    this.productId,
  });

  final String id;
  final String? productId;
  final String productName;
  final double price;
  final int quantity;

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
      id: json['id'].toString(),
      productId: json['product_id']?.toString(),
      productName: json['product_name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final double total;
  final DateTime createdAt;
  final List<AdminOrderItem> items;

  String get displayNumber {
    final parsed = int.tryParse(orderNumber);
    if (parsed == null) return orderNumber;
    return parsed.toString().padLeft(4, '0');
  }

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'];
    final items = <AdminOrderItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        items.add(
          AdminOrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
        );
      }
    }

    return AdminOrder(
      id: json['id'].toString(),
      orderNumber: json['order_number'].toString(),
      status: OrderStatus.fromDb(json['status'].toString()),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      items: items,
    );
  }
}
