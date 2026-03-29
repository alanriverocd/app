import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../providers/caja_ahorro_provider.dart';
import '../../utils/formatters.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaAhorroProvider>();
    final filtrados = caja.clientes
        .where((c) =>
            c.nombreCompleto
                .toLowerCase()
                .contains(_busqueda.toLowerCase()) ||
            c.correo.toLowerCase().contains(_busqueda.toLowerCase()))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          // ── Header con búsqueda ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clientes',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          // ── Lista ────────────────────────────────────────────────────
          Expanded(
            child: caja.loading
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? Center(
                        child: Text(
                          _busqueda.isEmpty
                              ? 'Sin clientes. Agrega uno con el botón +'
                              : 'Sin resultados',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtrados.length,
                        itemBuilder: (ctx, i) =>
                            _ClienteCard(cliente: filtrados[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogCliente(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Cliente'),
      ),
    );
  }

  void _mostrarDialogCliente(BuildContext context,
      {Cliente? clienteExistente}) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _ClienteDialog(clienteExistente: clienteExistente),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  const _ClienteCard({required this.cliente});

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              cliente.activo ? Colors.blue.withAlpha(38) : Colors.grey.withAlpha(38),
          child: Text(
            cliente.nombre.isNotEmpty
                ? cliente.nombre[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cliente.activo ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        title: Text(cliente.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cliente.telefono.isNotEmpty)
              Text(cliente.telefono,
                  style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 11, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Desde ${dateFmt.format(cliente.fechaInicio)}',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currencyFmt.format(cliente.saldoAcumulado),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green)),
            Text('Cuota: ${currencyFmt.format(cliente.montoSemana)}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        onTap: () => showDialog(
          context: context,
          builder: (ctx) =>
              _ClienteDialog(clienteExistente: cliente),
        ),
      ),
    );
  }
}

class _ClienteDialog extends StatefulWidget {
  final Cliente? clienteExistente;
  const _ClienteDialog({this.clienteExistente});

  @override
  State<_ClienteDialog> createState() => _ClienteDialogState();
}

class _ClienteDialogState extends State<_ClienteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _telefono;
  late final TextEditingController _correo;
  late final TextEditingController _monto;
  bool _activo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.clienteExistente;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _apellido = TextEditingController(text: c?.apellido ?? '');
    _telefono = TextEditingController(text: c?.telefono ?? '');
    _correo = TextEditingController(text: c?.correo ?? '');
    _monto = TextEditingController(
        text: c != null ? c.montoSemana.toStringAsFixed(2) : '');
    _activo = c?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _correo.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final caja = context.read<CajaAhorroProvider>();
    try {
      final cliente = Cliente(
        id: widget.clienteExistente?.id ?? '',
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        telefono: _telefono.text.trim(),
        correo: _correo.text.trim(),
        montoSemana: double.parse(_monto.text),
        saldoAcumulado:
            widget.clienteExistente?.saldoAcumulado ?? 0,
        fechaInicio:
            widget.clienteExistente?.fechaInicio ?? DateTime.now(),
        activo: _activo,
      );
      final esNuevo = widget.clienteExistente == null;
      if (esNuevo) {
        await caja.agregarCliente(cliente);
      } else {
        await caja.actualizarCliente(cliente);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(esNuevo
                  ? 'Cliente registrado correctamente'
                  : 'Cliente actualizado correctamente'),
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('No se pudo guardar el cliente: $e')),
            ]),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.clienteExistente != null;
    return AlertDialog(
      title: Text(esEdicion ? 'Editar Cliente' : 'Nuevo Cliente'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _field(_nombre, 'Nombre', required: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field(_apellido, 'Apellido', required: true)),
                  ],
                ),
                const SizedBox(height: 8),
                _field(_telefono, 'Teléfono',
                    keyboard: TextInputType.phone),
                const SizedBox(height: 8),
                _field(_correo, 'Correo',
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 8),
                _field(_monto, 'Cuota semanal (\$)',
                    required: true,
                    keyboard: const TextInputType.numberWithOptions(
                        decimal: true)),
                if (esEdicion) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Cliente activo'),
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _guardar,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2))
              : Text(esEdicion ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Requerido' : null
          : null,
    );
  }
}
