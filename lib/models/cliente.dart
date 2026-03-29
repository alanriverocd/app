import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String correo;
  final double montoSemana;
  final double saldoAcumulado;
  final DateTime fechaInicio;
  final bool activo;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.telefono = '',
    this.correo = '',
    required this.montoSemana,
    this.saldoAcumulado = 0,
    required this.fechaInicio,
    this.activo = true,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Cliente.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Cliente(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      telefono: data['telefono'] ?? '',
      correo: data['correo'] ?? '',
      montoSemana: (data['montoSemana'] ?? 0).toDouble(),
      saldoAcumulado: (data['saldoAcumulado'] ?? 0).toDouble(),
      fechaInicio: data['fechaInicio'] != null
          ? (data['fechaInicio'] as Timestamp).toDate()
          : DateTime.now(),
      activo: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'correo': correo,
        'montoSemana': montoSemana,
        'saldoAcumulado': saldoAcumulado,
        'fechaInicio': Timestamp.fromDate(fechaInicio),
        'activo': activo,
      };

  Cliente copyWith({
    String? nombre,
    String? apellido,
    String? telefono,
    String? correo,
    double? montoSemana,
    double? saldoAcumulado,
    bool? activo,
  }) =>
      Cliente(
        id: id,
        nombre: nombre ?? this.nombre,
        apellido: apellido ?? this.apellido,
        telefono: telefono ?? this.telefono,
        correo: correo ?? this.correo,
        montoSemana: montoSemana ?? this.montoSemana,
        saldoAcumulado: saldoAcumulado ?? this.saldoAcumulado,
        fechaInicio: fechaInicio,
        activo: activo ?? this.activo,
      );
}
