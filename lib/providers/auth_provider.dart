import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _timeout = Duration(seconds: 10);


  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Usuario? _perfil;
  bool _perfilCargado = false;
  List<String> get menusPermitidos => perfil?.menusPermitidos ?? [];
  Usuario? get perfil => _perfil;
  bool get perfilCargado => _perfilCargado;
  bool get isAdmin => _perfil?.esAdmin ?? false;
  bool get tieneCaja => _perfil?.tieneCaja ?? false;
  bool get tieneVentas => _perfil?.tieneVentas ?? false;
  String? get clienteId => _perfil?.clienteId;

  /// Carga el perfil desde Firestore. Si no existe, crea uno.
  /// El primer usuario en registrarse sin admins previos se convierte en admin.
  Future<void> cargarPerfil() async {
    final user = _auth.currentUser;
    if (user == null) {
      _perfil = null;
      _perfilCargado = true;
      notifyListeners();
      return;
    }
    try {
      final doc = await _db
          .collection('usuarios')
          .doc(user.uid)
          .get()
          .timeout(_timeout);

      if (doc.exists) {
        _perfil = Usuario.fromFirestore(doc);
        // Si el usuario no tiene clienteId, intentar vincularlo automáticamente por email
        if (_perfil != null && _perfil!.clienteId == null && _perfil!.email.isNotEmpty) {
          final clientesSnap = await _db
              .collection('clientes')
              .where('correo', isEqualTo: _perfil!.email)
              .limit(1)
              .get()
              .timeout(_timeout);
          if (clientesSnap.docs.isNotEmpty) {
            final clienteDoc = clientesSnap.docs.first;
            final clienteId = clienteDoc.id;
            // Actualizar el usuario en Firestore y localmente
            await _db.collection('usuarios').doc(user.uid).update({'clienteId': clienteId});
            _perfil = _perfil!.copyWith(clienteId: clienteId);
          }
        }
      } else {
        // Buscar pre-registro: primero por email, luego por teléfono
        QueryDocumentSnapshot<Map<String, dynamic>>? preRegDoc;

        if (user.email != null && user.email!.isNotEmpty) {
          final emailSnap = await _db
              .collection('usuarios')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get()
              .timeout(_timeout);
          if (emailSnap.docs.isNotEmpty) preRegDoc = emailSnap.docs.first;
        }

        if (preRegDoc == null &&
            user.phoneNumber != null &&
            user.phoneNumber!.isNotEmpty) {
          final phoneSnap = await _db
              .collection('usuarios')
              .where('telefono', isEqualTo: user.phoneNumber)
              .limit(1)
              .get()
              .timeout(_timeout);
          if (phoneSnap.docs.isNotEmpty) preRegDoc = phoneSnap.docs.first;
        }

        if (preRegDoc != null) {
          // Pre-registro encontrado: vincular con el uid real
          final data = preRegDoc.data();
          _perfil = Usuario(
            uid: user.uid,
            nombre: user.displayName ?? (data['nombre'] as String? ?? ''),
            email: user.email ?? (data['email'] as String? ?? ''),
            telefono:
                user.phoneNumber ?? (data['telefono'] as String? ?? ''),
            rol: _rolFromString(data['rol'] as String?),
            modulos: List<String>.from(data['modulos'] ?? []),
            clienteId: data['clienteId'] as String?,
            preRegistrado: false,
          );
          // Crear doc con uid real
          await _db
              .collection('usuarios')
              .doc(user.uid)
              .set(_perfil!.toFirestore())
              .timeout(_timeout);
          // Eliminar doc provisional si es distinto
          if (preRegDoc.id != user.uid) {
            await _db
                .collection('usuarios')
                .doc(preRegDoc.id)
                .delete()
                .timeout(_timeout);
          }
        } else {
          // Sin pre-registro: si no hay admins, este usuario es el primero → admin
          final adminsSnap = await _db
              .collection('usuarios')
              .where('rol', isEqualTo: 'admin')
              .limit(1)
              .get()
              .timeout(_timeout);
          final esAdmin = adminsSnap.docs.isEmpty;
          _perfil = Usuario(
            uid: user.uid,
            nombre: user.displayName ?? user.email ?? '',
            email: user.email ?? '',
            telefono: user.phoneNumber ?? '',
            rol: esAdmin ? RolUsuario.admin : RolUsuario.cliente,
            modulos: esAdmin ? ['caja', 'ventas'] : [],
          );
          await _db
              .collection('usuarios')
              .doc(user.uid)
              .set(_perfil!.toFirestore())
              .timeout(_timeout);
        }
      }
    } catch (_) {
      // Error de red: continúa sin perfil (modo degradado)
    }
    _perfilCargado = true;
    notifyListeners();
  }

  void limpiarPerfil() {
    _perfil = null;
    _perfilCargado = false;
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _perfilCargado = false;
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cargarPerfil();
    return credential;
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _perfilCargado = false;

    // 1. Crear la cuenta de Firebase Auth primero (ahora estamos autenticados)
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      // 2. Ya autenticados: verificar si hay admins en el sistema
      final adminsSnap = await _db
          .collection('usuarios')
          .where('rol', isEqualTo: 'admin')
          .limit(1)
          .get()
          .timeout(_timeout);

      if (adminsSnap.docs.isNotEmpty) {
        // Ya hay admin: verificar que el email esté pre-registrado
        final preReg = await _db
            .collection('usuarios')
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get()
            .timeout(_timeout);

        if (preReg.docs.isEmpty) {
          // No autorizado: eliminar la cuenta recién creada y lanzar error
          await credential.user?.delete();
          throw Exception(
              'Tu correo no está autorizado. Pide al administrador que te registre en el sistema.');
        }
      }
    } catch (e) {
      // Si es nuestro propio error, re-lanzarlo
      if (e is Exception) rethrow;
      // Error de red u otro: continuar (cargarPerfil lo manejará)
    }

    await cargarPerfil();
    return credential;
  }

  Future<void> signOut() async {
    limpiarPerfil();
    await _auth.signOut();
    notifyListeners();
  }

  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // ── Autenticación por teléfono (SMS OTP) ───────────────────────────────────

  String? _pendingNombre;

  /// Envía el código SMS al número indicado.
  Future<void> enviarCodigoSMS({
    required String telefono,
    required String nombre,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    _pendingNombre = nombre;
    _perfilCargado = false;
    await _auth.verifyPhoneNumber(
      phoneNumber: telefono,
      verificationCompleted: (credential) async {
        // Verificación automática (Android)
        final cred = await _auth.signInWithCredential(credential);
        await cred.user?.updateDisplayName(_pendingNombre ?? '');
        _pendingNombre = null;
        await cargarPerfil();
      },
      verificationFailed: (e) {
        _pendingNombre = null;
        onError(e.message ?? 'Error de verificación');
      },
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verifica el código OTP y autentica al usuario.
  /// Si el sistema ya tiene admins y el teléfono no está pre-registrado,
  /// elimina la cuenta y lanza error.
  Future<UserCredential> verificarCodigoSMS({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    _perfilCargado = false;
    final result = await _auth.signInWithCredential(credential);

    try {
      final adminsSnap = await _db
          .collection('usuarios')
          .where('rol', isEqualTo: 'admin')
          .limit(1)
          .get()
          .timeout(_timeout);

      if (adminsSnap.docs.isNotEmpty) {
        final telefono = result.user?.phoneNumber ?? '';
        final preReg = await _db
            .collection('usuarios')
            .where('telefono', isEqualTo: telefono)
            .limit(1)
            .get()
            .timeout(_timeout);

        if (preReg.docs.isEmpty) {
          await result.user?.delete();
          throw Exception(
              'Tu número no está autorizado. Pide al administrador que te registre en el sistema.');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    await cargarPerfil();
    return result;
  }
}

RolUsuario _rolFromString(String? s) {
  switch (s) {
    case 'admin':
      return RolUsuario.admin;
    default:
      return RolUsuario.cliente;
  }
}
