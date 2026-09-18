import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preem_coffee/screens/main_shell.dart';

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: MainShell()));
  await tester.pumpAndSettle();
}

Future<void> _tapAdd(WidgetTester tester, String productName) async {
  final addButton = find.byKey(ValueKey('add-$productName'));
  await tester.ensureVisible(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

Finder _qty(String productName) =>
    find.byKey(ValueKey('cart-qty-$productName'));

void _expectQuantity(WidgetTester tester, String productName, String quantity) {
  expect(_qty(productName), findsOneWidget);
  expect(tester.widget<Text>(_qty(productName)).data, quantity);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty cart shows a professional empty state', (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('PLACE ORDER'), findsNothing);
  });

  testWidgets('menu add, quantity, totals, and empty cart work', (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    await _tapAdd(tester, 'Coffee Ice Cream');
    expect(find.text('Coffee Ice Cream added to cart'), findsOneWidget);

    await _tapAdd(tester, 'Coffee Ice Cream');

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Coffee Ice Cream'), findsOneWidget);
    _expectQuantity(tester, 'Coffee Ice Cream', '2');
    expect(find.text('56 MAD'), findsWidgets);
    expect(find.text('PLACE ORDER'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cart-increase-Coffee Ice Cream')));
    await tester.pump();
    _expectQuantity(tester, 'Coffee Ice Cream', '3');
    expect(find.text('84 MAD'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('cart-decrease-Coffee Ice Cream')));
    await tester.pump();
    _expectQuantity(tester, 'Coffee Ice Cream', '2');

    await tester.tap(find.byKey(const ValueKey('cart-remove-Coffee Ice Cream')));
    await tester.pump();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('home and menu add to the same cart', (tester) async {
    await _pumpShell(tester);

    await _tapAdd(tester, 'Espresso');
    expect(find.text('Espresso added to cart'), findsOneWidget);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Espresso');
    await tester.pumpAndSettle();

    await _tapAdd(tester, 'Espresso');

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Espresso'), findsOneWidget);
    _expectQuantity(tester, 'Espresso', '2');
    expect(find.text('36 MAD'), findsWidgets);
  });
}
