import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preem_coffee/admin/admin_shell.dart';
import 'package:preem_coffee/admin/pages/admin_login_page.dart';
import 'package:preem_coffee/main.dart';
import 'package:preem_coffee/models/admin_order.dart';
import 'package:preem_coffee/models/cafe_product.dart';
import 'package:preem_coffee/services/admin_order_service.dart';
import 'package:preem_coffee/services/auth_service.dart';
import 'package:preem_coffee/services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeProductService extends ProductService {
  _FakeProductService(this.products);

  final List<CafeProduct> products;

  @override
  Future<List<CafeProduct>> fetchAll() async => products;
}

class _FakeOrderService extends AdminOrderService {
  @override
  Future<List<AdminOrder>> fetchOrders() async => const [];

  @override
  RealtimeChannel? subscribeToOrders({
    required void Function() onChange,
    String channelName = 'admin-orders',
  }) {
    return null;
  }
}

CafeProduct _product(
  String id,
  String name,
  String category,
  double price,
) {
  return CafeProduct(
    id: id,
    name: name,
    description: '$name description',
    priceMad: price,
    category: category,
    available: true,
    isPopular: false,
    imageUrl: 'assets/images/Espresso.png',
  );
}

final _seededProducts = [
  _product('1', 'Coffee Ice Cream', 'Coffee', 28),
  _product('2', 'Espresso', 'Coffee', 18),
  _product('3', 'Hot Milk', 'Coffee', 15),
  _product('4', 'Milk Coffee', 'Coffee', 22),
  _product('5', 'Latte', 'Coffee', 25),
  _product('6', 'Muffin', 'Breakfast', 25),
  _product('7', 'Chicken Salad', 'Breakfast', 25),
  _product('8', 'Eggs & Toast', 'Breakfast', 15),
  _product('9', 'Pancakes', 'Breakfast', 15),
  _product('10', 'Avocado Toast', 'Breakfast', 25),
  _product('11', 'Orange Juice', 'Drinks', 25),
  _product('12', 'Lemonade', 'Drinks', 18),
  _product('13', 'Mango Smoothie', 'Drinks', 28),
  _product('14', 'Strawberry Smoothie', 'Drinks', 24),
  _product('15', 'Avocado Smoothie', 'Drinks', 22),
  _product('16', 'Matcha', 'Drinks', 30),
  _product('17', 'Lemon Cheesecake', 'Desserts', 30),
  _product('18', 'Strawberry Cheesecake', 'Desserts', 32),
  _product('19', 'Almond Croissant', 'Desserts', 25),
  _product('20', 'Chocolate Brownie', 'Desserts', 25),
  _product('21', 'Crème Brûlée', 'Desserts', 30),
  _product('22', 'Vanilla Cupcake', 'Desserts', 22),
];

Future<void> _pumpAdmin(
  WidgetTester tester, {
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: AdminShell(
        productService: _FakeProductService(_seededProducts),
        orderService: _FakeOrderService(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin desktop sidebar shows all sections', (tester) async {
    await _pumpAdmin(tester);

    expect(find.text('PREEM'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Menu / Products'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Café Owner'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('ACCEPTED'), findsOneWidget);
    expect(find.text('CANCELLED'), findsOneWidget);
    expect(find.text('Recent Orders'), findsOneWidget);
    expect(find.text('No orders yet'), findsOneWidget);
  });

  testWidgets('admin menu loads all 22 supabase products', (tester) async {
    await _pumpAdmin(tester);

    await tester.tap(find.text('Menu / Products'));
    await tester.pump();

    expect(find.text('22 products across the café menu'), findsOneWidget);
    expect(find.text('Espresso'), findsOneWidget);
    expect(find.text('Hot Milk'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Vanilla Cupcake'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Vanilla Cupcake'), findsOneWidget);
    expect(find.text('Almond Croissant'), findsOneWidget);
  });

  testWidgets('admin compact layout uses a drawer instead of overflowing',
      (tester) async {
    await _pumpAdmin(tester, size: const Size(400, 800));

    expect(find.byType(Drawer), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsWidgets);
    await tester.tap(find.text('Orders').last);
    await tester.pump();
    await tester.pump();
    expect(find.text('No pending orders'), findsOneWidget);
  });

  testWidgets('customer welcome has no admin entry', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PreemCoffeeApp());
    await tester.pumpAndSettle();

    expect(find.text('Café Owner'), findsNothing);
    expect(find.text('START ORDERING →'), findsOneWidget);
  });

  testWidgets('/admin route is registered for admin login gate', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminLoginPage(
          authService: AuthService(client: null),
          onSignedIn: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('PREEM Admin'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
