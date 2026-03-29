import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../providers/ventas_provider.dart';
import '../../utils/formatters.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<VentasProvider>();
    final filtrados = ventas.productos
        .where((p) =>
            p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
            p.categoria.toLowerCase().contains(_busqueda.toLowerCase()))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Productos',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto o categoría...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ventas.loading
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? Center(
                        child: Text(
                          _busqueda.isEmpty
                              ? 'Sin productos. Agrega uno con el botón +'
                              : 'Sin resultados',
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
                            _ProductoCard(producto: filtrados[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialogoProducto(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
      ),
    );
  }

  void _dialogoProducto(BuildContext context, {Producto? existente}) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductoDialog(existente: existente),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  const _ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    final stockBajo = producto.stock <= 5;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              Colors.purple.withAlpha(31),
          child: const Icon(Icons.inventory_2,
              color: Colors.purple, size: 20),
        ),
        title: Text(producto.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producto.categoria,
                style: const TextStyle(fontSize: 12)),
            if (producto.descripcion.isNotEmpty)
              Text(producto.descripcion,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currencyFmt.format(producto.precio),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (stockBajo)
                  const Icon(Icons.warning_amber,
                      size: 12, color: Colors.orange),
                const SizedBox(width: 2),
                Text(
                  'Stock: ${producto.stock}',
                  style: TextStyle(
                      fontSize: 11,
                      color: stockBajo ? Colors.orange : Colors.grey),
                ),
              ],
            ),
          ],
        ),
        onTap: () => showDialog(
          context: context,
          builder: (ctx) => _ProductoDialog(existente: producto),
        ),
      ),
    );
  }
}

class _ProductoDialog extends StatefulWidget {
  final Producto? existente;
  const _ProductoDialog({this.existente});

  @override
  State<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<_ProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _desc;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  late final TextEditingController _cat;
  bool _activo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existente;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _desc = TextEditingController(text: p?.descripcion ?? '');
    _precio = TextEditingController(
        text: p != null ? p.precio.toStringAsFixed(2) : '');
    _stock = TextEditingController(
        text: p != null ? p.stock.toString() : '0');
    _cat = TextEditingController(text: p?.categoria ?? 'General');
    _activo = p?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _desc.dispose();
    _precio.dispose();
    _stock.dispose();
    _cat.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ventas = context.read<VentasProvider>();
    try {
      final p = Producto(
        id: widget.existente?.id ?? '',
        nombre: _nombre.text.trim(),
        descripcion: _desc.text.trim(),
        precio: double.parse(_precio.text),
        stock: int.parse(_stock.text),
        categoria: _cat.text.trim().isEmpty ? 'General' : _cat.text.trim(),
        activo: _activo,
      );
      final esNuevo = widget.existente == null;
      if (esNuevo) {
        await ventas.agregarProducto(p);
      } else {
        await ventas.actualizarProducto(p);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(esNuevo
                  ? 'Producto agregado correctamente'
                  : 'Producto actualizado correctamente'),
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
              Expanded(child: Text('No se guardó el producto: $e')),
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
    final esEdicion = widget.existente != null;
    return AlertDialog(
      title: Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_nombre, 'Nombre', required: true),
                const SizedBox(height: 8),
                _field(_desc, 'Descripción'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _field(_precio, 'Precio',
                            required: true,
                            keyboard:
                                const TextInputType.numberWithOptions(
                                    decimal: true))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field(_stock, 'Stock',
                            required: true,
                            keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                _field(_cat, 'Categoría'),
                if (esEdicion) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Producto activo'),
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
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(esEdicion ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false,
      TextInputType keyboard = TextInputType.text}) {
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
