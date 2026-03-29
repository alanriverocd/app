import 'widgets/dashboard_recent_payments.dart';
import '../../models/cliente.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/ingreso.dart';
import '../../models/pago_semanal.dart';
import '../../providers/caja_ahorro_provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';
import 'widgets/dashboard_notification.dart';
import 'widgets/dashboard_stat_cards.dart';
import 'widgets/dashboard_user_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaAhorroProvider>();
    final auth = context.watch<AuthProvider>();
    final semana = caja.semanaActual;
    final anio = DateTime.now().year;
    final clienteId = auth.clienteId;
    // Filtrar pagos e ingresos solo del usuario logueado
    final pagosUsuario = clienteId == null
        ? <PagoSemanal>[]
        : caja.pagos.where((p) => p.clienteId == clienteId).toList();
    final pagosSemana = pagosUsuario.where((p) => p.semana == semana && p.anio == anio).toList();
    final pendientes = pagosSemana.where((p) => p.estado == EstadoPago.pendiente).length;
    // Notificación diaria después del martes si hay pago pendiente de la semana
    final hoy = DateTime.now();
    final esDespuesDeMartes = hoy.weekday > DateTime.tuesday;
    final pagoPendienteSemana = pagosSemana.where((p) => p.estado != EstadoPago.pagado).toList();
    final pagosPagados = pagosUsuario.where((p) => p.estado == EstadoPago.pagado).toList();
    final saldoActual = pagosPagados.fold(0.0, (s, p) => s + p.montoPagado);
    // Pagos recientes (los más nuevos primero)
    final pagosRecientes = List<PagoSemanal>.from(pagosPagados)
      ..sort((a, b) {
        // Si alguno no tiene fechaPago, lo manda al final
        if (b.fechaPago == null && a.fechaPago == null) return 0;
        if (b.fechaPago == null) return -1;
        if (a.fechaPago == null) return 1;
        return b.fechaPago!.compareTo(a.fechaPago!);
      });
    final ingresosUsuario = clienteId == null
        ? <Ingreso>[]
        : caja.ingresos.where((i) => i.clienteId == clienteId).toList();

    // --- Lógica de semanas y deuda desde la primera semana de febrero ---
    final now = DateTime.now();
    final anioInicio = now.year;
    final semanaInicio = DateTime(anioInicio, 2, 1).difference(DateTime(anioInicio, 1, 1)).inDays ~/ 7 + 1;
    final semanasActual = caja.semanaActual;
    final semanasRango = [for (int s = semanaInicio; s <= semanasActual; s++) s];
    final cajaProv = Provider.of<CajaAhorroProvider>(context, listen: false);
    final cliente = clienteId == null
        ? null
        : cajaProv.clientes.firstWhere(
            (c) => c.id == clienteId,
            orElse: () => Cliente(
              id: '',
              nombre: '',
              apellido: '',
              montoSemana: 0,
              fechaInicio: DateTime.now(),
            ),
          );
    final pagosPendientes = pagosUsuario.where((p) =>
      p.anio == anioInicio &&
      semanasRango.contains(p.semana) &&
      p.estado != EstadoPago.pagado
    ).toList();
    final semanasAdeudadas = pagosPendientes.length;
    final montoAdeudado = cliente != null ? cliente.montoSemana * semanasAdeudadas : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notificación de adeudos
          DashboardNotification(
            semanasAdeudadas: semanasAdeudadas,
            montoAdeudado: montoAdeudado,
          ),
          if (esDespuesDeMartes && pagoPendienteSemana.isNotEmpty)
            Card(
              color: Colors.orange.shade50,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.campaign, color: Colors.orange, size: 32),
                title: const Text('¡Por favor realiza tu pago semanal!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                subtitle: Text('Tienes pagos pendientes de esta semana. Toca para ver el detalle.'),
                trailing: const Icon(Icons.info_outline, color: Colors.orange),
                onTap: () {
                  final semanasFaltantes = pagoPendienteSemana.map((p) => 'Semana ${p.semana}').join(', ');
                  final totalPendiente = cliente != null ? cliente.montoSemana * pagoPendienteSemana.length : 0.0;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Resumen de deuda'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Debes las siguientes semanas:'),
                          const SizedBox(height: 8),
                          Text(semanasFaltantes, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text('Total pendiente: ${currencyFmt.format(totalPendiente)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          // Encabezado con nombre y correo del cliente
          if (cliente != null && cliente.id.isNotEmpty)
            DashboardUserHeader(cliente: cliente),
          Text('Semana $semana · $anio',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),

          // Stat cards modularizadas
          DashboardStatCards(
            saldoActual: saldoActual,
            pendientes: pendientes,
            pagosRealizados: pagosPagados.length,
          ),
          const SizedBox(height: 28),

          // ── Acceso rápido ────────────────────────────────────────────
          Text('Acceso Rápido',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickAction(
                label: 'Tablero Pagos',
                icon: Icons.calendar_month,
                color: Colors.blue,
                onTap: () => context.go('/app/caja/tablero'),
              ),
              _QuickAction(
                label: 'Historial de Pagos',
                icon: Icons.history,
                color: Colors.teal,
                onTap: () => context.go('/app/usuario/historial-pagos'),
              ),
              _QuickAction(
                label: 'Agregar Cliente',
                icon: Icons.person_add,
                color: Colors.green,
                onTap: () => context.go('/app/caja/clientes'),
              ),
              _QuickAction(
                label: 'Nueva Venta',
                icon: Icons.add_shopping_cart,
                color: Colors.purple,
                onTap: () => context.go('/app/ventas/nueva'),
              ),
              _QuickAction(
                label: 'Ver Gráficos',
                icon: Icons.bar_chart,
                color: Colors.orange,
                onTap: () => context.go('/app/caja/graficos'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Últimos pagos realizados ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Últimos Pagos Realizados',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                  onPressed: () => context.go('/app/usuario/historial-pagos'),
                  child: const Text('Ver historial')),
            ],
          ),
          const SizedBox(height: 8),
          DashboardRecentPayments(pagos: pagosRecientes),
        ],
      ),
    );
  }

  Color _colorTipo(TipoIngreso tipo) {
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

  IconData _iconTipo(TipoIngreso tipo) {
    switch (tipo) {
      case TipoIngreso.deposito:
        return Icons.arrow_downward;
      case TipoIngreso.pago:
        return Icons.check_circle_outline;
      case TipoIngreso.retiro:
        return Icons.arrow_upward;
      default:
        return Icons.attach_money;
    }
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String mensaje;
  const _EmptyHint({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(mensaje,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
