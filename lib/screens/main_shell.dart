import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/cart_item.dart';
import '../models/menu_product.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'cart_page.dart';
import 'home_page.dart';
import 'menu_page.dart';
import 'order_confirmation_page.dart';
import 'profile_page.dart';

/// Root shell with fixed bottom navigation shared across main tabs.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.initialTab = 0,
    this.initialMenuCategory,
    this.orderService,
    this.productService,
  });

  final int initialTab;
  final String? initialMenuCategory;
  final OrderService? orderService;
  final ProductService? productService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex;
  String? _menuCategory;
  int _menuResetToken = 0;
  int _homeResetToken = 0;
  List<CartItem> _cart = const [];
  bool _isPlacingOrder = false;
  late final OrderService _orderService;

  static const Color _espresso = Color(0xFF2C1810);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _menuCategory = widget.initialMenuCategory;
    _orderService = widget.orderService ?? OrderService();
  }

  int get _cartItemCount =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  double get _cartTotalMad =>
      _cart.fold(0.0, (sum, item) => sum + item.lineTotalMad);

  void _addToCart(MenuProduct product) {
    if (_isPlacingOrder) return;
    setState(() {
      final items = List<CartItem>.from(_cart);
      final index = items.indexWhere((item) => item.product.name == product.name);
      if (index >= 0) {
        final existing = items[index];
        items[index] = existing.copyWith(quantity: existing.quantity + 1);
      } else {
        items.add(CartItem(product: product, quantity: 1));
      }
      _cart = items;
    });
  }

  void _increaseQuantity(CartItem item) {
    if (_isPlacingOrder) return;
    setState(() {
      final items = List<CartItem>.from(_cart);
      final index = items.indexWhere(
        (cartItem) => cartItem.product.name == item.product.name,
      );
      if (index < 0) return;
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
      _cart = items;
    });
  }

  void _decreaseQuantity(CartItem item) {
    if (_isPlacingOrder) return;
    setState(() {
      final items = List<CartItem>.from(_cart);
      final index = items.indexWhere(
        (cartItem) => cartItem.product.name == item.product.name,
      );
      if (index < 0) return;
      if (items[index].quantity <= 1) {
        items.removeAt(index);
      } else {
        items[index] =
            items[index].copyWith(quantity: items[index].quantity - 1);
      }
      _cart = items;
    });
  }

  void _removeItem(CartItem item) {
    if (_isPlacingOrder) return;
    setState(() {
      _cart = _cart
          .where((cartItem) => cartItem.product.name != item.product.name)
          .toList();
    });
  }

  void _clearCart() {
    if (_isPlacingOrder) return;
    setState(() => _cart = const []);
  }

  Future<void> _onPlaceOrder() async {
    if (_isPlacingOrder || _cart.isEmpty) return;

    setState(() => _isPlacingOrder = true);
    final itemsToPlace = List<CartItem>.from(_cart);

    try {
      final placedOrder =
          await _orderService.placePendingOrderFromCart(itemsToPlace);
      if (!mounted) return;

      setState(() {
        _cart = const [];
        _isPlacingOrder = false;
      });

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (routeContext) => OrderConfirmationPage(
            order: placedOrder,
            onBackToHome: () {
              Navigator.of(routeContext).pop();
              if (!mounted) return;
              setState(() => _selectedIndex = 0);
            },
          ),
        ),
      );
    } catch (error) {
      debugPrint('Failed to place order: $error');
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _espresso,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Unable to place your order. Please try again.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
    }
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _homeResetToken++;
      }
      if (index == 1) {
        _menuCategory = null;
        _menuResetToken++;
      }
    });
  }

  void _openMenu({String? category}) {
    setState(() {
      _selectedIndex = 1;
      _menuCategory = category;
      _menuResetToken++;
    });
  }

  void _openCart() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(
            key: ValueKey('home-$_homeResetToken'),
            onOpenMenuCategory: (category) => _openMenu(category: category),
            onAddToCart: _addToCart,
            productService: widget.productService,
          ),
          MenuPage(
            key: ValueKey('menu-${_menuCategory ?? 'all'}-$_menuResetToken'),
            initialCategory: _menuCategory,
            embedded: true,
            showAllSections: true,
            onCartTap: _openCart,
            onAddToCart: _addToCart,
            cartItemCount: _cartItemCount,
            productService: widget.productService,
          ),
          CartPage(
            items: _cart,
            totalMad: _cartTotalMad,
            isPlacingOrder: _isPlacingOrder,
            onIncrease: _increaseQuantity,
            onDecrease: _decreaseQuantity,
            onRemove: _removeItem,
            onClear: _clearCart,
            onPlaceOrder: _onPlaceOrder,
          ),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
        cartItemCount: _cartItemCount,
      ),
    );
  }
}
