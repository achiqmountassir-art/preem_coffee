import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preem_coffee/models/cart_item.dart';
import 'package:preem_coffee/models/order_status.dart';
import 'package:preem_coffee/models/placed_order.dart';
import 'package:preem_coffee/screens/main_shell.dart';
import 'package:preem_coffee/services/order_service.dart';

class _FakeOrderService extends OrderService {
  _FakeOrderService({
    this.delay = Duration.zero,
    this.error,
  });

  final Duration delay;
  final Object? error;
  int callCount = 0;
  List<CartItem>? lastItems;

  @override
  Future<PlacedOrder> placePendingOrderFromCart(List<CartItem> items) async {
    callCount++;
    lastItems = List<CartItem>.from(items);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (error != null) {
      throw error!;
    }
    return PlacedOrder(
      id: 'order-test-id',
      orderNumber: '0042',
      status: OrderStatus.pending,
      total: items.fold(0, (sum, item) => sum + item.lineTotalMad),
      createdAt: DateTime.utc(2026, 9, 16, 20),
    );
  }
}

Future<void> _pumpShell(
  WidgetTester tester, {
  OrderService? orderService,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: MainShell(orderService: orderService),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _addEspressoTwice(WidgetTester tester) async {
  final addButton = find.byKey(const ValueKey('add-Espresso'));
  await tester.ensureVisible(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

Future<void> _tapPlaceOrder(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('place-order-button'));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty cart cannot place an order', (tester) async {
    final service = _FakeOrderService();
    await _pumpShell(tester, orderService: service);

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('PLACE ORDER'), findsNothing);
    expect(service.callCount, 0);
  });

  testWidgets('successful place order shows confirmation and clears cart',
      (tester) async {
    final service = _FakeOrderService();
    await _pumpShell(tester, orderService: service);

    await _addEspressoTwice(tester);
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('36 MAD'), findsWidgets);
    await _tapPlaceOrder(tester);
    await _pumpUntil(tester, find.text('Order Confirmed'));

    expect(service.callCount, 1);
    expect(service.lastItems, isNotNull);
    expect(service.lastItems!.single.product.name, 'Espresso');
    expect(service.lastItems!.single.quantity, 2);
    expect(find.text('Order Confirmed'), findsOneWidget);
    expect(find.text('Order #0042'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('36 MAD'), findsOneWidget);
    expect(find.text('Your order has been received.'), findsOneWidget);

    await tester.tap(find.text('BACK TO HOME'));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning ☕'), findsOneWidget);
    expect(find.text('Order Confirmed'), findsNothing);

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('failed place order keeps the cart and re-enables the button',
      (tester) async {
    final service = _FakeOrderService(error: Exception('network down'));
    await _pumpShell(tester, orderService: service);

    await _addEspressoTwice(tester);
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    await _tapPlaceOrder(tester);
    await _pumpUntil(
      tester,
      find.text('Unable to place your order. Please try again.'),
    );

    expect(service.callCount, 1);
    expect(find.text('Espresso'), findsOneWidget);
    expect(find.text('PLACE ORDER'), findsOneWidget);
    expect(find.text('36 MAD'), findsWidgets);
    expect(find.text('Order Confirmed'), findsNothing);
  });

  testWidgets('duplicate taps do not create duplicate orders', (tester) async {
    final service = _FakeOrderService(
      delay: const Duration(milliseconds: 400),
    );
    await _pumpShell(tester, orderService: service);

    await _addEspressoTwice(tester);
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    await _tapPlaceOrder(tester);
    await tester.pump();
    expect(find.text('Placing order...'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('place-order-button')));
    await tester.pump();
    expect(service.callCount, 1);

    await tester.pump(const Duration(milliseconds: 450));
    await _pumpUntil(tester, find.text('Order Confirmed'));
    expect(service.callCount, 1);
  });
}
