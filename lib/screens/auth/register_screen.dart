import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Email
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Teléfono
  final _telefonoController = TextEditingController();
  final _otpController = TextEditingController();
  bool _faseOtp = false;
  String? _verificationId;

  bool _usarTelefono = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── Email ──────────────────────────────────────────────────────────────────

  Future<void> _registrarConEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential =
          await context.read<AuthProvider>().createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );
      await credential.user?.updateDisplayName(_nameController.text.trim());
      if (mounted) {
        await context.read<AuthProvider>().cargarPerfil();
        context.go('/app/dashboard');
      }
    } on Exception catch (e) {
      if (mounted) {
        _mostrarError(e.toString().replaceFirst('Exception: ', ''));
      }
    } catch (e) {
      if (mounted) _mostrarError('Error al registrarse: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Teléfono: fase 1 — enviar código ───────────────────────────────────────

  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await context.read<AuthProvider>().enviarCodigoSMS(
      telefono: _telefonoController.text.trim(),
      nombre: _nameController.text.trim(),
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _faseOtp = true;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          _mostrarError(error);
        }
      },
    );
  }

  // ── Teléfono: fase 2 — verificar código ────────────────────────────────────

  Future<void> _verificarCodigo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential =
          await context.read<AuthProvider>().verificarCodigoSMS(
                verificationId: _verificationId!,
                smsCode: _otpController.text.trim(),
              );
      await credential.user?.updateDisplayName(_nameController.text.trim());
      if (mounted) {
        await context.read<AuthProvider>().cargarPerfil();
        context.go('/app/dashboard');
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError(e.toString().replaceFirst('Exception: ', ''));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Código incorrecto. Intenta de nuevo.');
      }
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (_faseOtp) {
              setState(() {
                _faseOtp = false;
                _verificationId = null;
                _otpController.clear();
              });
            } else {
              context.go('/auth/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      _faseOtp ? 'Verificar código' : 'Crear cuenta',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_faseOtp)
                      Text(
                        'Enviamos un código a ${_telefonoController.text.trim()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    const SizedBox(height: 28),

                    // ── Toggle email / teléfono (solo fase inicial) ─────────
                    if (!_faseOtp) ...[
                      SegmentedButton<bool>(
                        style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        segments: const [
                          ButtonSegment(
                              value: false,
                              label: Text('Email'),
                              icon: Icon(Icons.email_outlined, size: 18)),
                          ButtonSegment(
                              value: true,
                              label: Text('Teléfono'),
                              icon: Icon(Icons.phone_outlined, size: 18)),
                        ],
                        selected: {_usarTelefono},
                        onSelectionChanged: (s) => setState(() {
                          _usarTelefono = s.first;
                          _formKey.currentState?.reset();
                        }),
                      ),
                      const SizedBox(height: 24),

                      // ── Nombre (siempre visible en fase inicial) ─────────
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Campos email ─────────────────────────────────────
                      if (!_usarTelefono) ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Email inválido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Mínimo 6 caracteres'
                              : null,
                        ),
                      ],

                      // ── Campo teléfono ───────────────────────────────────
                      if (_usarTelefono)
                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono (ej. +52 555 000 0000)',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                            hintText: '+52 555 000 0000',
                          ),
                          validator: (v) => v == null || v.trim().length < 7
                              ? 'Número inválido'
                              : null,
                        ),
                    ],

                    // ── Fase OTP: campo de código ────────────────────────────
                    if (_faseOtp) ...[
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 28,
                            letterSpacing: 12,
                            fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Código de verificación',
                          prefixIcon: Icon(Icons.sms_outlined),
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) => v == null || v.trim().length < 6
                            ? 'Ingresa los 6 dígitos'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  _faseOtp = false;
                                  _verificationId = null;
                                  _otpController.clear();
                                }),
                        child: const Text('Cambiar número'),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Botón principal ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : _faseOtp
                                ? _verificarCodigo
                                : _usarTelefono
                                    ? _enviarCodigo
                                    : _registrarConEmail,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_faseOtp
                                ? 'Verificar'
                                : _usarTelefono
                                    ? 'Enviar código'
                                    : 'Crear cuenta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
