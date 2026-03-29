import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pago_semanal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caja_ahorro_provider.dart';
import '../../utils/formatters.dart';

class TableroPagosScreen extends StatefulWidget {
  const TableroPagosScreen({super.key});

  @override
  State<TableroPagosScreen> createState() => _TableroPagosScreenState();
}

class _TableroPagosScreenState extends State<TableroPagosScreen> {
  late int _semana;
  late int _anio;

  late int _semanaActualRef;

  @override
  void initState() {
    super.initState();
    final caja = context.read<CajaAhorroProvider>();
    _semana = caja.semanaActual;
    _anio = DateTime.now().year;
    _semanaActualRef = caja.semanaActual;
  }

  void _cambiarSemana(int delta) {
    setState(() {
      _semana += delta;
      if (_semana < 1) {
        _semana = 52;
        _anio--;
      } else if (_semana > 52) {
        _semana = 1;
        _anio++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaAhorroProvider>();
    final auth = context.watch<AuthProvider>();
    final todosPagos = caja.getPagosDeSemana(_semana, _anio);
    final pagos = auth.isAdmin
        ? todosPagos
        : todosPagos
            .where((p) => p.clienteId == auth.clienteId)
            .toList();
    final hayPagos = pagos.isNotEmpty;

    final pagados = pagos.where((p) => p.estado == EstadoPago.pagado).length;
    final pendientes =
        pagos.where((p) => p.estado == EstadoPago.pendiente).length;

    return Scaffold(
      body: Column(
        children: [
          // ── Header con selector de semana ─────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tablero de Pagos',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.filled(
                      onPressed: () => _cambiarSemana(-1),
                      icon: const Icon(Icons.chevron_left),
                      style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Semana $_semana',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text('Año $_anio',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                          if (_semana != _semanaActualRef ||
                              _anio != DateTime.now().year)
                            TextButton.icon(
                              onPressed: () => setState(() {
                                _semana = _semanaActualRef;
                                _anio = DateTime.now().year;
                              }),
                              icon: const Icon(Icons.today, size: 14),
                              label: const Text('Ir a hoy',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _cambiarSemana(1),
                      icon: const Icon(Icons.chevron_right),
                      style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer),
                    ),
                  ],
                ),
                if (hayPagos) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PillChip(
                          label: '$pagados pagados', color: Colors.green),
                      const SizedBox(width: 8),
                      _PillChip(
                          label: '$pendientes pendientes',
                          color: Colors.orange),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Cuerpo ────────────────────────────────────────────────────
          Expanded(
            child: caja.loading
                ? const Center(child: CircularProgressIndicator())
                : !hayPagos
                    ? (auth.isAdmin
                        ? _GenerarSemanaView(
                            semana: _semana,
                            anio: _anio,
                            hayClientes: caja.clientesActivos.isNotEmpty,
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No tienes pagos registrados para esta semana.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pagos.length,
                        itemBuilder: (ctx, i) =>
                            _PagoCard(pago: pagos[i], soloLectura: !auth.isAdmin),
                      ),
          ),
        ],
      ),
    );
  }
}

class _GenerarSemanaView extends StatefulWidget {
  final int semana;
  final int anio;
  final bool hayClientes;

  const _GenerarSemanaView({
    required this.semana,
    required this.anio,
    required this.hayClientes,
  });

  @override
  State<_GenerarSemanaView> createState() => _GenerarSemanaViewState();
}

class _GenerarSemanaViewState extends State<_GenerarSemanaView> {
  bool _generando = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No hay pagos para la semana ${widget.semana}/${widget.anio}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (widget.hayClientes)
              FilledButton.icon(
                onPressed: _generando ? null : _generar,
                icon: _generando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_task),
                label: Text('Generar Semana ${widget.semana}'),
              )
            else
              const Text(
                'Primero agrega clientes en la sección Clientes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generar() async {
    setState(() => _generando = true);
    try {
      await context
          .read<CajaAhorroProvider>()
          .generarPagosSemana(widget.semana, widget.anio);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }
}

class _PagoCard extends StatelessWidget {
  final PagoSemanal pago;
  final bool soloLectura;
  const _PagoCard({required this.pago, this.soloLectura = false});

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(pago.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(38),
          child: Text(
            pago.clienteNombre.isNotEmpty
                ? pago.clienteNombre[0].toUpperCase()
                : '?',
            style:
                TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(pago.clienteNombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Esperado: ${currencyFmt.format(pago.montoEsperado)}',
                style: const TextStyle(fontSize: 12)),
            if (pago.montoPagado > 0)
              Text('Pagado: ${currencyFmt.format(pago.montoPagado)}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.green.shade700)),
            if (pago.fechaPago != null)
              Text('Fecha: ${dateFmt.format(pago.fechaPago!)}',
                  style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EstadoBadge(estado: pago.estado),
            const SizedBox(height: 4),
            if (!soloLectura) ...[
              if (pago.estado != EstadoPago.pagado)
                TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () => _dialogoRegistrarPago(context, pago),
                  child: const Text('Registrar',
                      style: TextStyle(fontSize: 12)),
                )
              else
                TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Colors.grey),
                  onPressed: () => _dialogoRegistrarPago(context, pago),
                  child:
                      const Text('Editar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _estadoColor(EstadoPago estado) => switch (estado) {
        EstadoPago.pagado => Colors.green,
        EstadoPago.parcial => Colors.blue,
        EstadoPago.pendiente => Colors.orange,
      };

  Future<void> _dialogoRegistrarPago(
      BuildContext context, PagoSemanal pago) async {
    final ctrl =
        TextEditingController(text: pago.montoEsperado.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar Pago\n${pago.clienteNombre}',
            style: const TextStyle(fontSize: 16)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto pagado',
              hintText: 'Esperado: ${currencyFmt.format(pago.montoEsperado)}',
              border: const OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa un monto';
              if (double.tryParse(v) == null) return 'Monto inválido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final monto = double.parse(ctrl.text);
              Navigator.of(ctx).pop();
              try {
                await context
                    .read<CajaAhorroProvider>()
                    .registrarPago(pago, monto);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                            'Pago de ${pago.clienteNombre} registrado correctamente'),
                      ]),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('No se registró el pago: $e')),
                      ]),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoPago estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      EstadoPago.pagado => ('Pagado', Colors.green),
      EstadoPago.parcial => ('Parcial', Colors.blue),
      EstadoPago.pendiente => ('Pendiente', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final Color color;
  const _PillChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
