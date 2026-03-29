import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoPago { pagado, pendiente, parcial }

class PagoSemanal {
  final String id;
  final String clienteId;
  final String clienteNombre;
  final int semana;
  final int anio;
  final double montoEsperado;
  final double montoPagado;
  final DateTime? fechaPago;
  final EstadoPago estado;

  const PagoSemanal({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.semana,
    required this.anio,
    required this.montoEsperado,
    this.montoPagado = 0,
    this.fechaPago,
    this.estado = EstadoPago.pendiente,
  });

  factory PagoSemanal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PagoSemanal(
      id: doc.id,
      clienteId: data['clienteId'] ?? '',
      clienteNombre: data['clienteNombre'] ?? '',
      semana: data['semana'] ?? 0,
      anio: data['anio'] ?? DateTime.now().year,
      montoEsperado: (data['montoEsperado'] ?? 0).toDouble(),
      montoPagado: (data['montoPagado'] ?? 0).toDouble(),
      fechaPago: data['fechaPago'] != null
          ? (data['fechaPago'] as Timestamp).toDate()
          : null,
      estado: _estadoPagoFromString(data['estado'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'semana': semana,
        'anio': anio,
        'montoEsperado': montoEsperado,
        'montoPagado': montoPagado,
        'fechaPago': fechaPago != null ? Timestamp.fromDate(fechaPago!) : null,
        'estado': _estadoPagoToString(estado),
      };

  PagoSemanal copyWith({
    double? montoPagado,
    DateTime? fechaPago,
    EstadoPago? estado,
  }) =>
      PagoSemanal(
        id: id,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        semana: semana,
        anio: anio,
        montoEsperado: montoEsperado,
        montoPagado: montoPagado ?? this.montoPagado,
        fechaPago: fechaPago ?? this.fechaPago,
        estado: estado ?? this.estado,
      );
}

EstadoPago _estadoPagoFromString(String? s) {
  switch (s) {
    case 'pagado':
      return EstadoPago.pagado;
    case 'parcial':
      return EstadoPago.parcial;
    default:
      return EstadoPago.pendiente;
  }
}

String _estadoPagoToString(EstadoPago e) {
  switch (e) {
    case EstadoPago.pagado:
      return 'pagado';
    case EstadoPago.parcial:
      return 'parcial';
    case EstadoPago.pendiente:
      return 'pendiente';
  }
}
