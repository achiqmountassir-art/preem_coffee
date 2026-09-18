/// Kitchen/order lifecycle. New customer orders always start as [pending].
enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  completed,
  cancelled;

  String get dbValue => name;

  String get label => '${name[0].toUpperCase()}${name.substring(1)}';

  static OrderStatus fromDb(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}
