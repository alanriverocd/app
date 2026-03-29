import 'package:cloud_firestore/cloud_firestore.dart';

enum RolUsuario { admin, cliente }

class Usuario {
  final String uid;
  final String nombre;
  final String email;
  final RolUsuario rol;
  final List<String> modulos; // 'caja', 'ventas'
  final String? clienteId; // liga al registro de caja de ahorro
  final bool preRegistrado; // true si el admin lo pre-registró pero aún no creó cuenta
  final String telefono;
  final List<String> menusPermitidos;

  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.modulos,
    this.clienteId,
    this.preRegistrado = false,
    this.telefono = '',
    this.menusPermitidos = const [],
  });

  bool get esAdmin => rol == RolUsuario.admin;
  bool get tieneCaja => esAdmin || modulos.contains('caja');
  bool get tieneVentas => esAdmin || modulos.contains('ventas');

  String get rolLabel => esAdmin ? 'Administrador' : 'Cliente';

  factory Usuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Usuario(
      uid: doc.id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      telefono: data['telefono'] as String? ?? '',
      rol: _rolFromString(data['rol'] as String?),
      modulos: List<String>.from(data['modulos'] ?? []),
      clienteId: data['clienteId'],
      preRegistrado: data['preRegistrado'] == true,
      menusPermitidos: data['menusPermitidos'] != null ? List<String>.from(data['menusPermitidos']) : const [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'rol': rol == RolUsuario.admin ? 'admin' : 'cliente',
        'modulos': modulos,
        'clienteId': clienteId,
        'preRegistrado': preRegistrado,
        'menusPermitidos': menusPermitidos,
      };

  Usuario copyWith({
    String? nombre,
    String? email,
    String? telefono,
    RolUsuario? rol,
    List<String>? modulos,
    Object? clienteId = _sentinel,
    bool? preRegistrado,
    List<String>? menusPermitidos,
  }) =>
      Usuario(
        uid: uid,
        nombre: nombre ?? this.nombre,
        email: email ?? this.email,
        telefono: telefono ?? this.telefono,
        rol: rol ?? this.rol,
        modulos: modulos ?? List.from(this.modulos),
        clienteId:
            clienteId == _sentinel ? this.clienteId : clienteId as String?,
        preRegistrado: preRegistrado ?? this.preRegistrado,
        menusPermitidos: menusPermitidos ?? List.from(this.menusPermitidos),
      );
}

const _sentinel = Object();

RolUsuario _rolFromString(String? s) {
  switch (s) {
    case 'admin':
      return RolUsuario.admin;
    default:
      return RolUsuario.cliente;
  }
}
