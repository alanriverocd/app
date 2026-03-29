import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/ingreso.dart';
import '../../models/pago_semanal.dart';
import '../../providers/caja_ahorro_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';

class CajaResumenScreen extends StatelessWidget {
  const CajaResumenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaAhorroProvider>();
    final auth = context.watch<AuthProvider>();
    final semana = caja.semanaActual;
    final anio = DateTime.now().year;
    final isAdmin = auth.isAdmin;
    final clienteId = auth.clienteId;
    final semanaActual = caja.pagosFiltrados(clienteId, isAdmin: isAdmin).where((p) => p.semana == semana && p.anio == anio).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Caja de Ahorro',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text('Resumen general',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),

          // ── Stats ────────────────────────────────────────────────────
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
                    title: 'Capital Acumulado',
                    value: currencyFmt.format(caja.totalCapital(clienteId, isAdmin: isAdmin)),
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: itemW,
                  child: StatCard(
                    title: 'Ingresos del Mes',
                    value: currencyFmt.format(caja.ingresosMes(clienteId, isAdmin: isAdmin)),
                    icon: Icons.trending_up,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: itemW,
                  child: StatCard(
                    title: 'Clientes Activos',
                    value: '${caja.clientesActivos.length}',
                    icon: Icons.people,
                    color: Colors.orange,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 28),

          // ── Semana actual ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text('Semana $semana – Estado de Pagos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => context.go('/app/caja/tablero'),
                child: const Text('Ver tablero'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (semanaActual.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('No hay pagos generados para esta semana.'),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => context.go('/app/caja/tablero'),
                      child: const Text('Ir al Tablero de Pagos'),
                    ),
                  ],
                ),
              ),
            )
          else
            _EstadoSemanaCard(pagos: semanaActual),

          const SizedBox(height: 28),

          // ── Últimos ingresos ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Últimos Ingresos',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => context.go('/app/caja/ingresos'),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...caja.ingresos.take(8).map((i) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor:
                        _tipoColor(i.tipo).withAlpha(31),
                    radius: 18,
                    child: Icon(_tipoIcon(i.tipo),
                        color: _tipoColor(i.tipo), size: 16),
                  ),
                  title: Text(i.descripcion,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${i.tipo.label}  ·  ${dateFmt.format(i.fecha)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    currencyFmt.format(i.monto),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: i.tipo == TipoIngreso.retiro
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Color _tipoColor(TipoIngreso tipo) {
    switch (tipo) {
      case TipoIngreso.deposito:
        return Colors.blue;
      case TipoIngreso.pago:
        return Colors.green;
      case TipoIngreso.retiro:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _tipoIcon(TipoIngreso tipo) {
    switch (tipo) {
      case TipoIngreso.deposito:
        return Icons.savings;
      case TipoIngreso.pago:
        return Icons.check;
      case TipoIngreso.retiro:
        return Icons.arrow_upward;
      default:
        return Icons.attach_money;
    }
  }
}

class _EstadoSemanaCard extends StatelessWidget {
  final List pagos;
  const _EstadoSemanaCard({required this.pagos});

  @override
  Widget build(BuildContext context) {
    final pagados = pagos.where((p) => p.estado == EstadoPago.pagado).length;
    final pendientes =
        pagos.where((p) => p.estado == EstadoPago.pendiente).length;
    final parciales =
        pagos.where((p) => p.estado == EstadoPago.parcial).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatusChip(
                label: 'Pagados', count: pagados, color: Colors.green),
            _StatusChip(
                label: 'Pendientes',
                count: pendientes,
                color: Colors.orange),
            if (parciales > 0)
              _StatusChip(
                  label: 'Parciales',
                  count: parciales,
                  color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withAlpha(38),
          child: Text('$count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
