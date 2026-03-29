import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/producto.dart';
import '../models/venta.dart';

class VentasProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();
  static const _timeout = Duration(seconds: 10);

  List<Producto> _productos = [];
  List<Venta> _ventas = [];
  bool _loading = false;

  List<Producto> get productos => _productos;
  List<Producto> get productosActivos =>
      _productos.where((p) => p.activo).toList();
  List<Venta> ventasFiltradas(String? uid, {bool isAdmin = false}) =>
      isAdmin || uid == null
          ? _ventas
          : _ventas.where((v) => v.compradorUid == uid).toList();
  bool get loading => _loading;

    double totalVentasHoy(String? uid, {bool isAdmin = false}) {
    final hoy = DateTime.now();
    return (isAdmin || uid == null ? _ventas : _ventas.where((v) => v.compradorUid == uid))
      .where((v) =>
        v.fecha.day == hoy.day &&
        v.fecha.month == hoy.month &&
        v.fecha.year == hoy.year &&
        v.estado == EstadoVenta.completada)
      .fold(0.0, (s, v) => s + v.total);
    }

    double totalVentasMes(String? uid, {bool isAdmin = false}) {
    final now = DateTime.now();
    return (isAdmin || uid == null ? _ventas : _ventas.where((v) => v.compradorUid == uid))
      .where((v) =>
        v.fecha.month == now.month &&
        v.fecha.year == now.year &&
        v.estado == EstadoVenta.completada)
      .fold(0.0, (s, v) => s + v.total);
    }

  int get stockBajoCount =>
      _productos.where((p) => p.activo && p.stock <= 5).length;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      await Future.wait([_loadProductos(), _loadVentas()])
          .timeout(_timeout);
    } catch (_) {
      // Continúa con listas vacías si Firestore no responde
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProductos() async {
    final snap = await _db
        .collection('productos')
        .orderBy('nombre')
        .get()
        .timeout(_timeout);
    _productos = snap.docs.map((d) => Producto.fromFirestore(d)).toList();
  }

  Future<void> _loadVentas() async {
    final snap = await _db
        .collection('ventas')
        .orderBy('fecha', descending: true)
        .limit(200)
        .get()
        .timeout(_timeout);
    _ventas = snap.docs.map((d) => Venta.fromFirestore(d)).toList();
  }

  // ── PRODUCTOS ─────────────────────────────────────────────────────────────

  Future<void> agregarProducto(Producto producto) async {
    final id = _uuid.v4();
    final p = Producto(
      id: id,
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      precio: producto.precio,
      stock: producto.stock,
      categoria: producto.categoria,
    );
    await _db.collection('productos').doc(id).set(p.toFirestore()).timeout(_timeout);
    _productos
      ..add(p)
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    notifyListeners();
  }

  Future<void> actualizarProducto(Producto producto) async {
    await _db
        .collection('productos')
        .doc(producto.id)
        .update(producto.toFirestore())
        .timeout(_timeout);
    final idx = _productos.indexWhere((p) => p.id == producto.id);
    if (idx >= 0) _productos[idx] = producto;
    notifyListeners();
  }

  // ── VENTAS ────────────────────────────────────────────────────────────────

  Future<void> registrarVenta(List<ItemVenta> items,
      {String? clienteNombre, String? compradorUid}) async {
    final id = _uuid.v4();
    final total = items.fold(0.0, (s, i) => s + i.subtotal);
    final venta = Venta(
      id: id,
      items: items,
      total: total,
      fecha: DateTime.now(),
      clienteNombre: clienteNombre,
      compradorUid: compradorUid,
    );

    final batch = _db.batch();
    batch.set(_db.collection('ventas').doc(id), venta.toFirestore());
    for (final item in items) {
      batch.update(
        _db.collection('productos').doc(item.productoId),
        {'stock': FieldValue.increment(-item.cantidad)},
      );
    }
    await batch.commit().timeout(_timeout);

    _ventas.insert(0, venta);
    for (final item in items) {
      final idx = _productos.indexWhere((p) => p.id == item.productoId);
      if (idx >= 0) {
        _productos[idx] =
            _productos[idx].copyWith(stock: _productos[idx].stock - item.cantidad);
      }
    }
    notifyListeners();
  }
}
