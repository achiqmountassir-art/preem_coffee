import 'package:flutter_test/flutter_test.dart';

import 'package:preem_coffee/main.dart';

void main() {
  testWidgets('Welcome screen displays tagline and language options',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PreemCoffeeApp());
    await tester.pumpAndSettle();

    expect(find.text('Fresh coffee.\nFresh moments.'), findsOneWidget);
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('START ORDERING →'), findsOneWidget);
  });

  testWidgets('Start ordering navigates to home after language selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PreemCoffeeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START ORDERING →'));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning ☕'), findsOneWidget);
    expect(find.text('Popular Products'), findsOneWidget);
  });

  testWidgets('Coffee category on home navigates to menu page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PreemCoffeeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START ORDERING →'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();

    expect(find.text('PREEM COFFEE'), findsOneWidget);
    expect(find.text('Coffee Ice Cream'), findsOneWidget);
    expect(find.text('Espresso'), findsWidgets);
  });

  testWidgets('Menu bottom nav opens full menu screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PreemCoffeeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START ORDERING →'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    expect(find.text('PREEM COFFEE'), findsOneWidget);
    expect(find.text('Coffee Ice Cream'), findsOneWidget);
    expect(find.text('Breakfast'), findsWidgets);
    expect(find.text('Drinks'), findsWidgets);
  });
}
