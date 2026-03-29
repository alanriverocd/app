import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ingreso.dart';
import '../../providers/caja_ahorro_provider.dart';
import '../../utils/formatters.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  TipoIngreso? _filtroTipo;

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaAhorroProvider>();
    final filtrados = _filtroTipo == null
        ? caja.ingresos
        : caja.ingresos.where((i) => i.tipo == _filtroTipo).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ingresos',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FiltroChip(
                          label: 'Todos',
                          selected: _filtroTipo == null,
                          onTap: () =>
                              setState(() => _filtroTipo = null)),
                      const SizedBox(width: 6),
                      for (final tipo in TipoIngreso.values) ...[
                        _FiltroChip(
                          label: tipo.label,
                          selected: _filtroTipo == tipo,
                          color: _tipoColor(tipo),
                          onTap: () =>
                              setState(() => _filtroTipo = tipo),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: caja.loading
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? Center(
                        child: Text(
                          'Sin ingresos registrados',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filtrados.length,
                        itemBuilder: (ctx, i) =>
                            _IngresoTile(ingreso: filtrados[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialogoAgregarIngreso(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Ingreso'),
      ),
    );
  }

  Future<void> _dialogoAgregarIngreso(BuildContext context) async {
    final caja = context.read<CajaAhorroProvider>();
    final formKey = GlobalKey<FormState>();
    final descripcionCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    TipoIngreso tipoSeleccionado = TipoIngreso.deposito;
    String? clienteId;
    String? clienteNombre;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Registrar Ingreso'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: descripcionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v) == null) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TipoIngreso>(
                    initialValue: tipoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: TipoIngreso.values
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) =>
                        setS(() => tipoSeleccionado = v!),
                  ),
                  if (caja.clientesActivos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: clienteId,
                      decoration: const InputDecoration(
                        labelText: 'Cliente (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null,
                            child: Text('Sin cliente')),
                        ...caja.clientesActivos.map((c) =>
                            DropdownMenuItem(
                                value: c.id,
                                child: Text(c.nombreCompleto,
                                    overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (id) {
                        final c = caja.clientesActivos
                            .firstWhere((c) => c.id == id,
                                orElse: () => caja.clientesActivos.first);
                        setS(() {
                          clienteId = id;
                          clienteNombre = id != null ? c.nombreCompleto : null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => saving = true);
                      try {
                        await caja.agregarIngreso(Ingreso(
                          id: '',
                          descripcion: descripcionCtrl.text.trim(),
                          monto: double.parse(montoCtrl.text),
                          tipo: tipoSeleccionado,
                          clienteId: clienteId,
                          clienteNombre: clienteNombre,
                          fecha: DateTime.now(),
                        ));
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                const Text('Ingreso registrado correctamente'),
                              ]),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Row(children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        'No se registró el ingreso: $e')),
                              ]),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setS(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Registrar'),
            ),
          ],
        ),
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
      case TipoIngreso.otro:
        return Colors.grey;
    }
  }
}

class _IngresoTile extends StatelessWidget {
  final Ingreso ingreso;
  const _IngresoTile({required this.ingreso});

  @override
  Widget build(BuildContext context) {
    final color = _color(ingreso.tipo);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withAlpha(31),
          child: Icon(_icon(ingreso.tipo), color: color, size: 16),
        ),
        title: Text(ingreso.descripcion,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${ingreso.tipo.label}${ingreso.clienteNombre != null ? ' · ${ingreso.clienteNombre}' : ''}\n${dateTimeFmt.format(ingreso.fecha)}',
          style: const TextStyle(fontSize: 11),
        ),
        isThreeLine: true,
        trailing: Text(
          currencyFmt.format(ingreso.monto),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: ingreso.tipo == TipoIngreso.retiro
                ? Colors.red
                : Colors.green,
          ),
        ),
      ),
    );
  }

  Color _color(TipoIngreso tipo) {
    switch (tipo) {
      case TipoIngreso.deposito:
        return Colors.blue;
      case TipoIngreso.pago:
        return Colors.green;
      case TipoIngreso.retiro:
        return Colors.red;
      case TipoIngreso.otro:
        return Colors.grey;
    }
  }

  IconData _icon(TipoIngreso tipo) {
    switch (tipo) {
      case TipoIngreso.deposito:
        return Icons.savings;
      case TipoIngreso.pago:
        return Icons.check;
      case TipoIngreso.retiro:
        return Icons.arrow_upward;
      case TipoIngreso.otro:
        return Icons.attach_money;
    }
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: c.withAlpha(38),
      checkmarkColor: c,
      onSelected: (_) => onTap(),
    );
  }
}
