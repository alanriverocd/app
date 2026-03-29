import 'package:cloud_firestore/cloud_firestore.dart';

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String categoria;
  final bool activo;

  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.precio,
    this.stock = 0,
    this.categoria = 'General',
    this.activo = true,
  });

  factory Producto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Producto(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      categoria: data['categoria'] ?? 'General',
      activo: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'stock': stock,
        'categoria': categoria,
        'activo': activo,
      };

  Producto copyWith({
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    String? categoria,
    bool? activo,
  }) =>
      Producto(
        id: id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        precio: precio ?? this.precio,
        stock: stock ?? this.stock,
        categoria: categoria ?? this.categoria,
        activo: activo ?? this.activo,
      );
}
