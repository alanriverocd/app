import 'package:flutter/material.dart';
import '../../../models/pago_semanal.dart';
import '../../../utils/formatters.dart';

class DashboardRecentPayments extends StatelessWidget {
  final List<PagoSemanal> pagos;
  const DashboardRecentPayments({super.key, required this.pagos});

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return const Text('No tienes pagos registrados', style: TextStyle(color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...pagos.take(5).map((p) => ListTile(
              leading: Icon(
                p.estado == EstadoPago.pagado
                    ? Icons.check_circle
                    : p.estado == EstadoPago.parcial
                        ? Icons.timelapse
                        : Icons.pending_actions,
                color: p.estado == EstadoPago.pagado
                    ? Colors.green
                    : p.estado == EstadoPago.parcial
                        ? Colors.orange
                        : Colors.red,
              ),
              title: Text('Semana ${p.semana} - ${currencyFmt.format(p.montoPagado)}'),
              subtitle: Text('Año ${p.anio}'),
              trailing: Text(
                p.estado == EstadoPago.pagado
                    ? 'Pagado'
                    : p.estado == EstadoPago.parcial
                        ? 'Parcial'
                        : 'Pendiente',
                style: TextStyle(
                  color: p.estado == EstadoPago.pagado
                      ? Colors.green
                      : p.estado == EstadoPago.parcial
                          ? Colors.orange
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
      ],
    );
  }
}
