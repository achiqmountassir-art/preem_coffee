import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/admin_order_service.dart';
import '../services/product_service.dart';
import 'admin_shell.dart';
import 'pages/admin_login_page.dart';
import 'admin_colors.dart';

/// Gates `/admin` behind Supabase Auth + admin_users allowlist.
class AdminGate extends StatefulWidget {
  const AdminGate({
    super.key,
    this.authService,
    this.productService,
    this.orderService,
  });

  final AuthService? authService;
  final ProductService? productService;
  final AdminOrderService? orderService;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late final AuthService _authService;
  StreamSubscription<AuthState>? _authSub;
  bool _checking = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _authSub = _authService.authStateChanges.listen((_) => _refresh());
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final session = _authService.currentSession;
      final admin = session == null ? false : await _authService.isAdmin();
      if (!mounted) return;
      setState(() {
        _isAdmin = admin;
        _checking = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _checking = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AdminColors.cream,
        body: Center(
          child: CircularProgressIndicator(color: AdminColors.coffeeBrown),
        ),
      );
    }

    if (_error != null && _authService.currentSession == null) {
      return AdminLoginPage(
        authService: _authService,
        onSignedIn: _refresh,
      );
    }

    if (!_isAdmin) {
      return AdminLoginPage(
        authService: _authService,
        onSignedIn: _refresh,
      );
    }

    return AdminShell(
      authService: _authService,
      productService: widget.productService,
      orderService: widget.orderService,
    );
  }
}
