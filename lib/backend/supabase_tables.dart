/// Postgres table names used by the future order flow.
abstract final class SupabaseTables {
  static const products = 'products';
  static const orders = 'orders';
  static const orderItems = 'order_items';
  static const adminUsers = 'admin_users';
}

abstract final class SupabaseRpcs {
  static const placePendingOrder = 'place_pending_order';
}
