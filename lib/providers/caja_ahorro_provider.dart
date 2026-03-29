import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/cliente.dart';
import '../models/ingreso.dart';
import '../models/pago_semanal.dart';

class CajaAhorroProvider extends ChangeNotifier {
    // Getters públicos para compatibilidad con widgets existentes
    List<Ingreso> get ingresos => _ingresos;
    List<PagoSemanal> get pagos => _pagos;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();
  static const _timeout = Duration(seconds: 10);

  List<Cliente> _clientes = [];
  List<Ingreso> _ingresos = [];
  List<PagoSemanal> _pagos = [];
  bool _loading = false;

  List<Cliente> get clientes => _clientes;
  List<Cliente> get clientesActivos =>
      _clientes.where((c) => c.activo).toList();
    List<Ingreso> ingresosFiltrados(String? clienteId, {bool isAdmin = false}) =>
      isAdmin || clienteId == null
        ? _ingresos
        : _ingresos.where((i) => i.clienteId == clienteId).toList();
    List<PagoSemanal> pagosFiltrados(String? clienteId, {bool isAdmin = false}) =>
      isAdmin || clienteId == null
        ? _pagos
        : _pagos.where((p) => p.clienteId == clienteId).toList();
  bool get loading => _loading;

    double totalCapital(String? clienteId, {bool isAdmin = false}) =>
      (isAdmin || clienteId == null
        ? _ingresos
        : _ingresos.where((i) => i.clienteId == clienteId))
        .where((i) => i.tipo != TipoIngreso.retiro)
        .fold(0, (s, i) => s + i.monto);

    double totalRetiros(String? clienteId, {bool isAdmin = false}) =>
      (isAdmin || clienteId == null
        ? _ingresos
        : _ingresos.where((i) => i.clienteId == clienteId))
        .where((i) => i.tipo == TipoIngreso.retiro)
        .fold(0, (s, i) => s + i.monto);

    double ingresosMes(String? clienteId, {bool isAdmin = false}) {
    final now = DateTime.now();
    return (isAdmin || clienteId == null
        ? _ingresos
        : _ingresos.where((i) => i.clienteId == clienteId))
      .where((i) =>
        i.fecha.month == now.month &&
        i.fecha.year == now.year &&
        i.tipo != TipoIngreso.retiro)
      .fold(0, (s, i) => s + i.monto);
    }

  int get semanaActual {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return ((now.difference(startOfYear).inDays) / 7).ceil();
  }

  List<PagoSemanal> getPagosDeSemana(int semana, int anio) =>
      _pagos.where((p) => p.semana == semana && p.anio == anio).toList();

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      await Future.wait([_loadClientes(), _loadIngresos(), _loadPagos()])
          .timeout(_timeout);
    } catch (_) {
      // Continúa con listas vacías si Firestore no responde
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadClientes() async {
    final snap = await _db
        .collection('clientes')
        .orderBy('nombre')
        .get()
        .timeout(_timeout);
    _clientes = snap.docs.map((d) => Cliente.fromFirestore(d)).toList();
  }

  Future<void> _loadIngresos() async {
    final snap = await _db
        .collection('ingresos')
        .orderBy('fecha', descending: true)
        .limit(200)
        .get()
        .timeout(_timeout);
    _ingresos = snap.docs.map((d) => Ingreso.fromFirestore(d)).toList();
  }

  Future<void> _loadPagos() async {
    final snap = await _db
        .collection('pagos_semanales')
        .orderBy('anio', descending: true)
        .get()
        .timeout(_timeout);
    _pagos = snap.docs.map((d) => PagoSemanal.fromFirestore(d)).toList();
  }

  // ── CLIENTES ─────────────────────────────────────────────────────────────

  Future<void> agregarCliente(Cliente cliente) async {
    final id = _uuid.v4();
    final c = Cliente(
      id: id,
      nombre: cliente.nombre,
      apellido: cliente.apellido,
      telefono: cliente.telefono,
      correo: cliente.correo,
      montoSemana: cliente.montoSemana,
      fechaInicio: cliente.fechaInicio,
    );
    await _db.collection('clientes').doc(id).set(c.toFirestore()).timeout(_timeout);
    _clientes
      ..add(c)
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    notifyListeners();
  }

  Future<void> actualizarCliente(Cliente cliente) async {
    await _db
        .collection('clientes')
        .doc(cliente.id)
        .update(cliente.toFirestore())
        .timeout(_timeout);
    final idx = _clientes.indexWhere((c) => c.id == cliente.id);
    if (idx >= 0) _clientes[idx] = cliente;
    notifyListeners();
  }

  // ── INGRESOS ─────────────────────────────────────────────────────────────

  Future<void> agregarIngreso(Ingreso ingreso) async {
    final id = _uuid.v4();
    final i = Ingreso(
      id: id,
      descripcion: ingreso.descripcion,
      monto: ingreso.monto,
      tipo: ingreso.tipo,
      clienteId: ingreso.clienteId,
      clienteNombre: ingreso.clienteNombre,
      fecha: ingreso.fecha,
    );
    await _db.collection('ingresos').doc(id).set(i.toFirestore()).timeout(_timeout);
    _ingresos.insert(0, i);
    notifyListeners();
  }

  // ── PAGOS SEMANALES ───────────────────────────────────────────────────────

  Future<void> generarPagosSemana(int semana, int anio) async {
    final batch = _db.batch();
    for (final cliente in clientesActivos) {
      final id = '${cliente.id}_${anio}_$semana';
      final pago = PagoSemanal(
        id: id,
        clienteId: cliente.id,
        clienteNombre: cliente.nombreCompleto,
        semana: semana,
        anio: anio,
        montoEsperado: cliente.montoSemana,
      );
      batch.set(
          _db.collection('pagos_semanales').doc(id), pago.toFirestore());
    }
    await batch.commit().timeout(_timeout);
    await _loadPagos();
    notifyListeners();
  }

  Future<void> registrarPago(PagoSemanal pago, double monto) async {
    final estado = monto >= pago.montoEsperado
        ? EstadoPago.pagado
        : monto > 0
            ? EstadoPago.parcial
            : EstadoPago.pendiente;

    final updated = pago.copyWith(
      montoPagado: monto,
      fechaPago: DateTime.now(),
      estado: estado,
    );

    await _db
        .collection('pagos_semanales')
        .doc(pago.id)
        .update(updated.toFirestore())
        .timeout(_timeout);

    if (monto > 0) {
      // Actualizar saldo en Firestore
      await _db.collection('clientes').doc(pago.clienteId).update({
        'saldoAcumulado': FieldValue.increment(monto),
      });
      // Actualizar saldo local
      final ci = _clientes.indexWhere((c) => c.id == pago.clienteId);
      if (ci >= 0) {
        _clientes[ci] = _clientes[ci]
            .copyWith(saldoAcumulado: _clientes[ci].saldoAcumulado + monto);
      }
      // Registrar ingreso automático
      final id = _uuid.v4();
      final ingreso = Ingreso(
        id: id,
        descripcion:
            'Pago semana ${pago.semana}/${pago.anio} – ${pago.clienteNombre}',
        monto: monto,
        tipo: TipoIngreso.pago,
        clienteId: pago.clienteId,
        clienteNombre: pago.clienteNombre,
        fecha: DateTime.now(),
      );
      await _db.collection('ingresos').doc(id).set(ingreso.toFirestore());
      _ingresos.insert(0, ingreso);
    }

    final idx = _pagos.indexWhere((p) => p.id == pago.id);
    if (idx >= 0) _pagos[idx] = updated;
    notifyListeners();
  }
}
