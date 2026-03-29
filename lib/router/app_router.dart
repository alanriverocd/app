import '../screens/admin/permisos_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/admin/usuarios_screen.dart';
import '../screens/usuario/historial_pagos_screen.dart';
import '../screens/caja_ahorro/caja_resumen_screen.dart';
import '../screens/caja_ahorro/clientes_screen.dart';
import '../screens/caja_ahorro/graficos_screen.dart';
import '../screens/caja_ahorro/ingresos_screen.dart';
import '../screens/caja_ahorro/tablero_pagos_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/ventas/nueva_venta_screen.dart';
import '../screens/ventas/productos_screen.dart';
import '../screens/ventas/ventas_resumen_screen.dart';
import '../widgets/nav_shell.dart';

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isAuthenticated = auth.isAuthenticated;
        final loc = state.matchedLocation;

        if (loc == '/splash') return null;
        if (!isAuthenticated && !loc.startsWith('/auth')) return '/auth/login';
        if (isAuthenticated && loc.startsWith('/auth')) return '/app/dashboard';

        // Protección por rol y permisos personalizados
        if (isAuthenticated && auth.perfil != null && !auth.isAdmin) {
          // Mapear rutas a menuId
          String menuId = '';
          if (loc.contains('tablero')) menuId = 'mis_pagos';
          else if (loc.contains('dashboard')) menuId = 'dashboard';
          else if (loc.contains('resumen') && loc.contains('ventas')) menuId = 'mis_compras';
          else if (loc.contains('resumen')) menuId = 'resumen';
          else if (loc.contains('clientes')) menuId = 'clientes';
          else if (loc.contains('ingresos')) menuId = 'ingresos';
          else if (loc.contains('graficos')) menuId = 'graficos';
          else if (loc.contains('productos')) menuId = 'productos';
          else if (loc.contains('nueva')) menuId = 'nueva_venta';
          else if (loc.contains('usuarios')) menuId = 'usuarios';
          else if (loc.contains('permisos')) menuId = 'permisos';

          if (menuId.isNotEmpty && !auth.menusPermitidos.contains(menuId)) {
            // Si intenta acceder a un menú no permitido, redirigir al primero permitido o dashboard
            final destino = auth.menusPermitidos.contains('dashboard')
                ? '/app/dashboard'
                : auth.menusPermitidos.contains('mis_pagos')
                    ? '/app/caja/tablero'
                    : auth.menusPermitidos.contains('mis_compras')
                        ? '/app/ventas/resumen'
                        : '/app/dashboard';
            return destino;
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => NavShell(child: child),
          routes: [
            GoRoute(
              path: '/app/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/app/caja/resumen',
              builder: (context, state) => const CajaResumenScreen(),
            ),
            GoRoute(
              path: '/app/caja/clientes',
              builder: (context, state) => const ClientesScreen(),
            ),
            GoRoute(
              path: '/app/caja/tablero',
              builder: (context, state) => const TableroPagosScreen(),
            ),
            GoRoute(
              path: '/app/caja/ingresos',
              builder: (context, state) => const IngresosScreen(),
            ),
            GoRoute(
              path: '/app/caja/graficos',
              builder: (context, state) => const GraficosScreen(),
            ),
            GoRoute(
              path: '/app/ventas/resumen',
              builder: (context, state) => const VentasResumenScreen(),
            ),
            GoRoute(
              path: '/app/ventas/productos',
              builder: (context, state) => const ProductosScreen(),
            ),
            GoRoute(
              path: '/app/ventas/nueva',
              builder: (context, state) => const NuevaVentaScreen(),
            ),
            GoRoute(
              path: '/app/usuario/historial-pagos',
              builder: (context, state) => const HistorialPagosScreen(),
            ),
            GoRoute(
              path: '/app/admin/usuarios',
              builder: (context, state) => const UsuariosScreen(),
            ),
            GoRoute(
              path: '/app/admin/permisos',
              builder: (context, state) => const PermisosMenuScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
