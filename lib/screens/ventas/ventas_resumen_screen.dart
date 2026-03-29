import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';

class VentasResumenScreen extends StatelessWidget {
  const VentasResumenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<VentasProvider>();
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid;
    final isAdmin = auth.isAdmin;
    final ventasFiltradas = ventas.ventasFiltradas(uid, isAdmin: isAdmin);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ventas',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text('Resumen de ventas',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),

          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 600 ? 3 : 2;
            final itemW = (constraints.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemW,
                  child: StatCard(
                    title: 'Ventas Hoy',
                    value: currencyFmt.format(ventas.totalVentasHoy(uid, isAdmin: isAdmin)),
                    icon: Icons.today,
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: itemW,
                  child: StatCard(
                    title: 'Ventas del Mes',
                    value: currencyFmt.format(ventas.totalVentasMes(uid, isAdmin: isAdmin)),
                    icon: Icons.calendar_month,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: itemW,
                  child: StatCard(
                    title: 'Stock Bajo',
                    value: '${ventas.stockBajoCount} productos',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                    onTap: () => context.go('/app/ventas/productos'),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(auth.isAdmin ? 'Nueva Venta' : 'Mis Compras',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (auth.isAdmin)
                FilledButton.icon(
                  onPressed: () => context.go('/app/ventas/nueva'),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Crear Venta'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Últimas Ventas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (ventas.loading)
            const Center(child: CircularProgressIndicator())
          else if (ventasFiltradas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: Text('Sin ventas registradas',
                      style: TextStyle(color: Colors.grey))),
            )
          else
            ...ventasFiltradas.take(10).map((v) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.withAlpha(31),
                      child: const Icon(Icons.receipt_long,
                          color: Colors.purple, size: 18),
                    ),
                    title: Text(
                      v.clienteNombre ?? 'Venta directa',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${v.items.length} producto(s)  ·  ${dateTimeFmt.format(v.fecha)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      currencyFmt.format(v.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
