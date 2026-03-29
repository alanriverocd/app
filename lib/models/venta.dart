import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoVenta { completada, pendiente, cancelada }

class ItemVenta {
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;

  const ItemVenta({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  factory ItemVenta.fromMap(Map<String, dynamic> map) => ItemVenta(
        productoId: map['productoId'] ?? '',
        productoNombre: map['productoNombre'] ?? '',
        cantidad: map['cantidad'] ?? 1,
        precioUnitario: (map['precioUnitario'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'productoNombre': productoNombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
      };
}

class Venta {
  final String id;
  final List<ItemVenta> items;
  final double total;
  final DateTime fecha;
  final String? clienteNombre;
  final String? compradorUid;
  final EstadoVenta estado;

  const Venta({
    required this.id,
    required this.items,
    required this.total,
    required this.fecha,
    this.clienteNombre,
    this.compradorUid,
    this.estado = EstadoVenta.completada,
  });

  factory Venta.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Venta(
      id: doc.id,
      items: (data['items'] as List? ?? [])
          .map((e) => ItemVenta.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (data['total'] ?? 0).toDouble(),
      fecha: data['fecha'] != null
          ? (data['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      clienteNombre: data['clienteNombre'],
      compradorUid: data['compradorUid'],
      estado: _estadoVentaFromString(data['estado'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'fecha': Timestamp.fromDate(fecha),
        'clienteNombre': clienteNombre,
        'compradorUid': compradorUid,
        'estado': _estadoVentaToString(estado),
      };
}

EstadoVenta _estadoVentaFromString(String? s) {
  switch (s) {
    case 'completada':
      return EstadoVenta.completada;
    case 'pendiente':
      return EstadoVenta.pendiente;
    case 'cancelada':
      return EstadoVenta.cancelada;
    default:
      return EstadoVenta.completada;
  }
}

String _estadoVentaToString(EstadoVenta e) {
  switch (e) {
    case EstadoVenta.completada:
      return 'completada';
    case EstadoVenta.pendiente:
      return 'pendiente';
    case EstadoVenta.cancelada:
      return 'cancelada';
  }
}
