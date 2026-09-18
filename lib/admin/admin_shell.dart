import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_order_service.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import 'admin_colors.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_orders_page.dart';
import 'pages/admin_products_page.dart';

/// Desktop/tablet admin shell with a coffee sidebar and cream content.
class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    this.initialSection = 0,
    this.productService,
    this.orderService,
    this.authService,
  });

  final int initialSection;
  final ProductService? productService;
  final AdminOrderService? orderService;
  final AuthService? authService;

  static const double sidebarBreakpoint = 960;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _selectedIndex;

  static const _sections = [
    _AdminSection(
      label: 'Dashboard',
      icon: Icons.space_dashboard_rounded,
    ),
    _AdminSection(
      label: 'Orders',
      icon: Icons.receipt_long_rounded,
    ),
    _AdminSection(
      label: 'Menu / Products',
      icon: Icons.restaurant_menu_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSection.clamp(0, _sections.length - 1);
  }

  void _selectSection(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _signOut() async {
    await widget.authService?.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= AdminShell.sidebarBreakpoint;

        return Scaffold(
          backgroundColor: AdminColors.cream,
          appBar: showSidebar
              ? null
              : AppBar(
                  backgroundColor: AdminColors.sidebar,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  title: Text(
                    'PREEM COFFEE',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  actions: [
                    if (widget.authService != null)
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout_rounded),
                      ),
                  ],
                ),
          drawer: showSidebar
              ? null
              : Drawer(
                  backgroundColor: AdminColors.sidebar,
                  child: SafeArea(
                    child: _AdminSidebar(
                      selectedIndex: _selectedIndex,
                      sections: _sections,
                      onSelect: (index) {
                        _selectSection(index);
                        Navigator.of(context).pop();
                      },
                      onSignOut:
                          widget.authService == null ? null : _signOut,
                    ),
                  ),
                ),
          body: Row(
            children: [
              if (showSidebar)
                SizedBox(
                  width: 260,
                  child: _AdminSidebar(
                    selectedIndex: _selectedIndex,
                    sections: _sections,
                    onSelect: _selectSection,
                    onSignOut: widget.authService == null ? null : _signOut,
                  ),
                ),
              Expanded(
                child: ColoredBox(
                  color: AdminColors.cream,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      AdminDashboardPage(orderService: widget.orderService),
                      AdminOrdersPage(orderService: widget.orderService),
                      AdminProductsPage(productService: widget.productService),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSection {
  const _AdminSection({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedIndex,
    required this.sections,
    required this.onSelect,
    this.onSignOut,
  });

  final int selectedIndex;
  final List<_AdminSection> sections;
  final ValueChanged<int> onSelect;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AdminColors.sidebar,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandHeader(),
              const SizedBox(height: 36),
              ...List.generate(sections.length, (index) {
                final section = sections[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SidebarItem(
                    icon: section.icon,
                    label: section.label,
                    selected: index == selectedIndex,
                    onTap: () => onSelect(index),
                  ),
                );
              }),
              const Spacer(),
              const _AdminIdentity(),
              if (onSignOut != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => onSignOut!(),
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  label: Text(
                    'Sign out',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: AdminColors.gold.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.coffee,
                color: AdminColors.coffeeBrown,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREEM',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.6,
                ),
              ),
              Text(
                'COFFEE',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AdminColors.gold,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AdminColors.cream.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AdminColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AdminColors.gold
                    : Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminIdentity extends StatelessWidget {
  const _AdminIdentity();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AdminColors.coffeeBrown,
            child: Text(
              'A',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Café Owner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
