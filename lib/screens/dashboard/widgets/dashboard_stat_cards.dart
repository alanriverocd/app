import '../../../widgets/stat_card.dart';
import 'package:flutter/material.dart';
import '../../../utils/formatters.dart';
import '../../../models/pago_semanal.dart';

class DashboardStatCards extends StatelessWidget {
  final double saldoActual;
  final int pendientes;
  final int pagosRealizados;
  const DashboardStatCards({
    super.key,
    required this.saldoActual,
    required this.pendientes,
    required this.pagosRealizados,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 700 ? 4 : 2;
      final itemW = (constraints.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: itemW,
            child: StatCard(
              title: 'Saldo Actual',
              value: currencyFmt.format(saldoActual),
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),
          ),
          SizedBox(
            width: itemW,
            child: StatCard(
              title: 'Pagos Pendientes',
              value: '$pendientes',
              icon: Icons.pending_actions,
              color: Colors.orange,
              subtitle: 'Esta semana',
            ),
          ),
          SizedBox(
            width: itemW,
            child: StatCard(
              title: 'Pagos Realizados',
              value: '$pagosRealizados',
              icon: Icons.check_circle_outline,
              color: Colors.blue,
            ),
          ),
        ],
      );
    });
  }
}
