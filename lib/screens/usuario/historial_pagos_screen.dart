import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pago_semanal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caja_ahorro_provider.dart';
import '../../utils/formatters.dart';

class HistorialPagosScreen extends StatelessWidget {
  const HistorialPagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaAhorroProvider>();
    final auth = context.watch<AuthProvider>();
    final clienteId = auth.clienteId;
    final pagosUsuario = clienteId == null
        ? <PagoSemanal>[]
        : caja.pagos.where((p) => p.clienteId == clienteId).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos'),
      ),
      body: pagosUsuario.isEmpty
          ? const Center(child: Text('No tienes pagos registrados'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pagosUsuario.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final pago = pagosUsuario[i];
                return ListTile(
                  leading: Icon(
                    pago.estado == EstadoPago.pagado
                        ? Icons.check_circle
                        : pago.estado == EstadoPago.parcial
                            ? Icons.timelapse
                            : Icons.pending_actions,
                    color: pago.estado == EstadoPago.pagado
                        ? Colors.green
                        : pago.estado == EstadoPago.parcial
                            ? Colors.orange
                            : Colors.red,
                  ),
                  title: Text('Semana ${pago.semana} · ${pago.anio}'),
                  subtitle: Text('Estado: ${_estadoLabel(pago.estado)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFmt.format(pago.montoPagado),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (pago.fechaPago != null)
                        Text(dateFmt.format(pago.fechaPago!),
                            style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _estadoLabel(EstadoPago estado) {
    switch (estado) {
      case EstadoPago.pagado:
        return 'Pagado';
      case EstadoPago.parcial:
        return 'Parcial';
      case EstadoPago.pendiente:
        return 'Pendiente';
    }
  }
}
