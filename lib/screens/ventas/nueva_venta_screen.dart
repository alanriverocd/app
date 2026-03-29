import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../utils/formatters.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final Map<String, int> _carrito = {}; // productoId -> cantidad
  final TextEditingController _clienteCtrl = TextEditingController();
  bool _guardando = false;
  String _busqueda = '';

  @override
  void dispose() {
    _clienteCtrl.dispose();
    super.dispose();
  }

  double get _total {
    final ventas = context.read<VentasProvider>();
    double sum = 0;
    for (final entry in _carrito.entries) {
      final producto = ventas.productos
          .firstWhere((p) => p.id == entry.key, orElse: () {
        return const Producto(
            id: '', nombre: '', precio: 0);
      });
      sum += producto.precio * entry.value;
    }
    return sum;
  }

  List<ItemVenta> _buildItems(VentasProvider ventas) {
    return _carrito.entries
        .map((e) {
          final p =
              ventas.productos.firstWhere((pr) => pr.id == e.key, orElse: () {
            return const Producto(id: '', nombre: '', precio: 0);
          });
          return ItemVenta(
            productoId: p.id,
            productoNombre: p.nombre,
            cantidad: e.value,
            precioUnitario: p.precio,
          );
        })
        .where((i) => i.productoId.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<VentasProvider>();
    final productosFiltrados = ventas.productosActivos
        .where((p) =>
            p.nombre.toLowerCase().contains(_busqueda.toLowerCase()))
        .toList();
    final carritoVacio = _carrito.isEmpty;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva Venta',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
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
            child: Row(
              children: [
                // ── Lista de productos ──────────────────────────────────
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: productosFiltrados.length,
                    itemBuilder: (ctx, i) {
                      final p = productosFiltrados[i];
                      final enCarrito = _carrito[p.id] ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          title: Text(p.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${p.categoria} · Stock: ${p.stock}',
                              style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currencyFmt.format(p.precio),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              const SizedBox(width: 8),
                              if (enCarrito > 0) ...[
                                IconButton(
                                  icon:
                                      const Icon(Icons.remove, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 28, minHeight: 28),
                                  onPressed: () => setState(() {
                                    _carrito[p.id] = enCarrito - 1;
                                    if (_carrito[p.id]! <= 0) {
                                      _carrito.remove(p.id);
                                    }
                                  }),
                                ),
                                Text('$enCarrito',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                onPressed: p.stock > enCarrito
                                    ? () => setState(() {
                                          _carrito[p.id] =
                                              (enCarrito) + 1;
                                        })
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Carrito / Resumen ───────────────────────────────────
                if (MediaQuery.sizeOf(context).width >= 700)
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant)),
                    ),
                    child: _ResumenCarrito(
                      carrito: _carrito,
                      productos: ventas.productos,
                      clienteCtrl: _clienteCtrl,
                      total: _total,
                      onConfirmar: carritoVacio ? null : _confirmar,
                      guardando: _guardando,
                    ),
                  ),
              ],
            ),
          ),

          // ── Barra inferior en móvil ───────────────────────────────────
          if (MediaQuery.sizeOf(context).width < 700)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                    top: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${_carrito.values.fold(0, (s, v) => s + v)} items'),
                        Text(currencyFmt.format(_total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: carritoVacio ? null : () => _mostrarResumenMobile(context, ventas),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Confirmar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _mostrarResumenMobile(
      BuildContext context, VentasProvider ventas) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ResumenCarrito(
          carrito: _carrito,
          productos: ventas.productos,
          clienteCtrl: _clienteCtrl,
          total: _total,
          onConfirmar: _confirmar,
          guardando: _guardando,
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    final ventas = context.read<VentasProvider>();
    final items = _buildItems(ventas);
    if (items.isEmpty) return;

    setState(() => _guardando = true);
    try {
      final auth = context.read<AuthProvider>();
      await ventas.registrarVenta(
        items,
        clienteNombre: _clienteCtrl.text.trim().isEmpty
            ? null
            : _clienteCtrl.text.trim(),
        compradorUid: auth.currentUser?.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada correctamente')),
        );
        setState(() => _carrito.clear());
        context.go('/app/ventas/resumen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _ResumenCarrito extends StatelessWidget {
  final Map<String, int> carrito;
  final List<Producto> productos;
  final TextEditingController clienteCtrl;
  final double total;
  final VoidCallback? onConfirmar;
  final bool guardando;

  const _ResumenCarrito({
    required this.carrito,
    required this.productos,
    required this.clienteCtrl,
    required this.total,
    required this.onConfirmar,
    required this.guardando,
  });

  @override
  Widget build(BuildContext context) {
    final items = carrito.entries.map((e) {
      final p = productos.firstWhere((pr) => pr.id == e.key,
          orElse: () => const Producto(id: '', nombre: '', precio: 0));
      return (p, e.value);
    }).where((t) => t.$1.id.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Resumen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Agrega productos al carrito')),
            )
          else
            ...items.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${t.$1.nombre} x${t.$2}',
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Text(
                          currencyFmt.format(t.$1.precio * t.$2),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(currencyFmt.format(total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: clienteCtrl,
            decoration: InputDecoration(
              labelText: 'Cliente (opcional)',
              hintText: 'Nombre del cliente',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              isDense: true,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: items.isEmpty || guardando ? null : onConfirmar,
            icon: guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar Venta'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
