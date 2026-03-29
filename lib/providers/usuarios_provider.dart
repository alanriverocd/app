import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/email_service.dart';

class UsuariosProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _timeout = Duration(seconds: 10);

  List<Usuario> _usuarios = [];
  bool _loading = false;

  List<Usuario> get usuarios => _usuarios;
  bool get loading => _loading;
  List<Usuario> get admins => _usuarios.where((u) => u.esAdmin).toList();
  List<Usuario> get clientes => _usuarios.where((u) => !u.esAdmin).toList();

  /// Obtiene los menús permitidos para un usuario desde Firestore
  Future<List<String>> getMenusPermitidos(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    final data = doc.data();
    if (data == null || data['menusPermitidos'] == null) return [];
    return List<String>.from(data['menusPermitidos']);
  }
  /// Guarda los menús permitidos para un usuario en Firestore
  Future<void> setMenusPermitidos(String uid, List<String> menus) async {
    await _db.collection('usuarios').doc(uid).update({
      'menusPermitidos': menus,
    });
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('usuarios')
          .orderBy('nombre')
          .get()
          .timeout(_timeout);
      _usuarios = snap.docs.map((d) => Usuario.fromFirestore(d)).toList();
    } catch (_) {
      // Continúa con lista vacía si hay error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> actualizarUsuario(Usuario usuario) async {
    await _db
        .collection('usuarios')
        .doc(usuario.uid)
        .update(usuario.toFirestore())
        .timeout(_timeout);
    final idx = _usuarios.indexWhere((u) => u.uid == usuario.uid);
    if (idx >= 0) _usuarios[idx] = usuario;
    notifyListeners();
  }

  Future<void> asignarRol(String uid, RolUsuario rol) async {
    final idx = _usuarios.indexWhere((u) => u.uid == uid);
    if (idx < 0) return;
    final actualizado = _usuarios[idx].copyWith(rol: rol);
    await actualizarUsuario(actualizado);
  }

  Future<void> asignarModulos(String uid, List<String> modulos) async {
    final idx = _usuarios.indexWhere((u) => u.uid == uid);
    if (idx < 0) return;
    final actualizado = _usuarios[idx].copyWith(modulos: modulos);
    await actualizarUsuario(actualizado);
  }

  Future<void> vincularCliente(String uid, String? clienteId) async {
    final idx = _usuarios.indexWhere((u) => u.uid == uid);
    if (idx < 0) return;
    final actualizado = _usuarios[idx].copyWith(clienteId: clienteId);
    await actualizarUsuario(actualizado);
  }

  /// Pre-registra un cliente por email o teléfono antes de que se cree su cuenta.
  /// Crea un documento en `usuarios` con ID provisional.
  Future<void> preRegistrar({
    String? email,
    String? telefono,
    required List<String> modulos,
    String? clienteId,
  }) async {
    assert(email != null || telefono != null,
        'Se debe proporcionar email o teléfono');

    // Verificar duplicados
    if (email != null && email.isNotEmpty) {
      final existing = await _db
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(_timeout);
      if (existing.docs.isNotEmpty) {
        throw Exception('El correo $email ya está registrado en el sistema.');
      }
    }
    if (telefono != null && telefono.isNotEmpty) {
      final existing = await _db
          .collection('usuarios')
          .where('telefono', isEqualTo: telefono)
          .limit(1)
          .get()
          .timeout(_timeout);
      if (existing.docs.isNotEmpty) {
        throw Exception(
            'El teléfono $telefono ya está registrado en el sistema.');
      }
    }

    final docRef = _db.collection('usuarios').doc();
    final data = {
      'email': email ?? '',
      'telefono': telefono ?? '',
      'nombre': '',
      'rol': 'cliente',
      'modulos': modulos,
      'clienteId': clienteId,
      'preRegistrado': true,
    };
    await docRef.set(data).timeout(_timeout);

    // Agregar a la lista local como usuario pendiente
    final usuario = Usuario(
      uid: docRef.id,
      nombre: '',
      email: email ?? '',
      telefono: telefono ?? '',
      rol: RolUsuario.cliente,
      modulos: modulos,
      clienteId: clienteId,
      preRegistrado: true,
    );
    _usuarios.add(usuario);
    _usuarios.sort((a, b) {
      final aKey = a.email.isNotEmpty ? a.email : a.telefono;
      final bKey = b.email.isNotEmpty ? b.email : b.telefono;
      return aKey.compareTo(bKey);
    });
    notifyListeners();

    // Enviar correo de invitación si se registró por email
    if (email != null && email.isNotEmpty) {
      try {
        await EmailService.enviarInvitacion(emailDestino: email);
      } catch (e) {
        throw Exception('No se pudo enviar el correo de invitación: ${e.toString()}');
      }
    }
  }

  /// Elimina un usuario pre-registrado (que aún no ha creado su cuenta)
  Future<void> eliminarPreRegistro(String uid) async {
    await _db.collection('usuarios').doc(uid).delete().timeout(_timeout);
    _usuarios.removeWhere((u) => u.uid == uid);
    notifyListeners();
  }
}
