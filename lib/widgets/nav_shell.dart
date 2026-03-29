import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/caja_ahorro_provider.dart';
import '../providers/ventas_provider.dart';
import '../models/cliente.dart';

class _NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? sectionHeader;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.sectionHeader,
  });
}

List<_NavItem> buildNavItems(AuthProvider auth) {
  // Si es admin, mostrar todos los menús como antes
  if (auth.isAdmin) {
    final items = <_NavItem>[
      const _NavItem(
        path: '/app/dashboard',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Dashboard',
      ),
      _NavItem(
        path: '/app/caja/resumen',
        icon: Icons.savings_outlined,
        selectedIcon: Icons.savings,
        label: 'Resumen',
        sectionHeader: 'CAJA DE AHORRO',
      ),
      const _NavItem(
        path: '/app/caja/clientes',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: 'Clientes',
      ),
      _NavItem(
        path: '/app/caja/tablero',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: 'Tablero Pagos',
      ),
      const _NavItem(
        path: '/app/caja/ingresos',
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
        label: 'Ingresos',
      ),
      const _NavItem(
        path: '/app/caja/graficos',
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        label: 'Gráficos',
      ),
      _NavItem(
        path: '/app/ventas/resumen',
        icon: Icons.store_outlined,
        selectedIcon: Icons.store,
        label: 'Resumen Ventas',
        sectionHeader: 'VENTAS',
      ),
      const _NavItem(
        path: '/app/ventas/productos',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Productos',
      ),
      const _NavItem(
        path: '/app/ventas/nueva',
        icon: Icons.add_shopping_cart_outlined,
        selectedIcon: Icons.add_shopping_cart,
        label: 'Nueva Venta',
      ),
      const _NavItem(
        path: '/app/admin/usuarios',
        icon: Icons.manage_accounts_outlined,
        selectedIcon: Icons.manage_accounts,
        label: 'Usuarios',
        sectionHeader: 'ADMINISTRACIÓN',
      ),
      const _NavItem(
        path: '/app/admin/permisos',
        icon: Icons.lock_outline,
        selectedIcon: Icons.lock,
        label: 'Permisos',
      ),
    ];
    return items;
  }

  // Si es cliente, mostrar solo los menús permitidos
  final allMenus = <_NavItem>[
    _NavItem(
      path: '/app/dashboard',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Dashboard',
    ),
    _NavItem(
      path: '/app/caja/tablero',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Mis Pagos',
    ),
    _NavItem(
      path: '/app/ventas/resumen',
      icon: Icons.store_outlined,
      selectedIcon: Icons.store,
      label: 'Mis Compras',
    ),
    _NavItem(
      path: '/app/caja/resumen',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
      label: 'Resumen',
      sectionHeader: 'CAJA DE AHORRO',
    ),
    _NavItem(
      path: '/app/caja/clientes',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Clientes',
    ),
    _NavItem(
      path: '/app/caja/ingresos',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
      label: 'Ingresos',
    ),
    _NavItem(
      path: '/app/caja/graficos',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Gráficos',
    ),
    _NavItem(
      path: '/app/ventas/productos',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Productos',
    ),
    _NavItem(
      path: '/app/ventas/nueva',
      icon: Icons.add_shopping_cart_outlined,
      selectedIcon: Icons.add_shopping_cart,
      label: 'Nueva Venta',
    ),
    _NavItem(
      path: '/app/admin/usuarios',
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
      label: 'Usuarios',
      sectionHeader: 'ADMINISTRACIÓN',
    ),
  ];
  final permitidos = auth.menusPermitidos;
  return allMenus.where((item) => permitidos.contains(_menuIdFromPath(item.path))).toList();
}

String _menuIdFromPath(String path) {
  if (path.contains('tablero')) return 'mis_pagos';
  if (path.contains('dashboard')) return 'dashboard';
  if (path.contains('resumen') && path.contains('ventas')) return 'mis_compras';
  if (path.contains('resumen')) return 'resumen';
  if (path.contains('clientes')) return 'clientes';
  if (path.contains('ingresos')) return 'ingresos';
  if (path.contains('graficos')) return 'graficos';
  if (path.contains('productos')) return 'productos';
  if (path.contains('nueva')) return 'nueva_venta';
  if (path.contains('usuarios')) return 'usuarios';
  if (path.contains('permisos')) return 'permisos';
  return '';
}
// ...existing code...

class NavShell extends StatefulWidget {
  final Widget child;
  const NavShell({super.key, required this.child});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CajaAhorroProvider>().loadAll();
      context.read<VentasProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            const _SideDrawerContent(),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FINATIOL',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const Drawer(child: _SideDrawerContent()),
      body: widget.child,
    );
  }
}

class _SideDrawerContent extends StatelessWidget {
  const _SideDrawerContent();

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final caja = context.watch<CajaAhorroProvider>();
    final user = auth.currentUser;
    final navItems = buildNavItems(auth);
    // Buscar cliente si el usuario está vinculado
    Cliente? cliente;
    if (auth.clienteId != null) {
      try {
        cliente = caja.clientes.firstWhere((c) => c.id == auth.clienteId);
      } catch (_) {
        cliente = null;
      }
    } else {
      cliente = null;
    }

    return SizedBox(
      width: 260,
      child: Material(
        color: colorScheme.surface,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B4F72), Color(0xFF2E86C1)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'FINATIOL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 2),
                    if (cliente != null) ...[
                      Text(
                        cliente.nombreCompleto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cliente.correo.isNotEmpty)
                        Text(
                          cliente.correo,
                          style: TextStyle(
                            color: Colors.white.withAlpha(191),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ] else ...[
                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withAlpha(191),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: auth.isAdmin
                            ? Colors.purple.withAlpha(76)
                            : Colors.blue.withAlpha(76),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auth.isAdmin ? 'Administrador' : 'Cliente',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Nav Items ────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in navItems) ...[
                    if (item.sectionHeader != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          item.sectionHeader!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: colorScheme.outlineVariant),
                      const SizedBox(height: 4),
                    ],
                    _NavTile(
                      item: item,
                      selected: currentPath.startsWith(item.path),
                      onTap: () {
                        if (MediaQuery.sizeOf(context).width < 900) {
                          Navigator.of(context).pop();
                        }
                        context.go(item.path);
                      },
                    ),
                  ],
                ],
              ),
            ),
            // ── Footer ───────────────────────────────────────────────────
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.redAccent, fontSize: 14)),
              onTap: () async {
                await auth.signOut();
                if (context.mounted) context.go('/auth/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: true,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: selected,
        selectedTileColor: colorScheme.primaryContainer,
        leading: Icon(
          selected ? item.selectedIcon : item.icon,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 21,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
