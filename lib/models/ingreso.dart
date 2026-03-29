import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoIngreso { deposito, pago, retiro, otro }

extension TipoIngresoExtension on TipoIngreso {
  String get label {
    switch (this) {
      case TipoIngreso.deposito:
        return 'Depósito';
      case TipoIngreso.pago:
        return 'Pago';
      case TipoIngreso.retiro:
        return 'Retiro';
      case TipoIngreso.otro:
        return 'Otro';
    }
  }
}

class Ingreso {
  final String id;
  final String descripcion;
  final double monto;
  final TipoIngreso tipo;
  final String? clienteId;
  final String? clienteNombre;
  final DateTime fecha;

  const Ingreso({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.tipo,
    this.clienteId,
    this.clienteNombre,
    required this.fecha,
  });

  factory Ingreso.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Ingreso(
      id: doc.id,
      descripcion: data['descripcion'] ?? '',
      monto: (data['monto'] ?? 0).toDouble(),
      tipo: _tipoIngresoFromString(data['tipo'] as String?),
      clienteId: data['clienteId'],
      clienteNombre: data['clienteNombre'],
      fecha: data['fecha'] != null
          ? (data['fecha'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'descripcion': descripcion,
        'monto': monto,
        'tipo': _tipoIngresoToString(tipo),
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'fecha': Timestamp.fromDate(fecha),
      };
}

TipoIngreso _tipoIngresoFromString(String? s) {
  switch (s) {
    case 'deposito':
      return TipoIngreso.deposito;
    case 'pago':
      return TipoIngreso.pago;
    case 'retiro':
      return TipoIngreso.retiro;
    default:
      return TipoIngreso.otro;
  }
}

String _tipoIngresoToString(TipoIngreso t) {
  switch (t) {
    case TipoIngreso.deposito:
      return 'deposito';
    case TipoIngreso.pago:
      return 'pago';
    case TipoIngreso.retiro:
      return 'retiro';
    case TipoIngreso.otro:
      return 'otro';
  }
}
