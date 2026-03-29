import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/usuarios_provider.dart';
import '../../../providers/caja_ahorro_provider.dart';
import '../../../models/cliente.dart';

class InviteDialog extends StatefulWidget {
  const InviteDialog({super.key});

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  final emailCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final modulosSeleccionados = <String>{};
  bool guardando = false;
  bool porTelefono = false;
  String? emailError;

  @override
  Widget build(BuildContext context) {
    final clientes = context.read<CajaAhorroProvider>().clientes;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, size: 20),
          SizedBox(width: 8),
          Text('Invitar cliente', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12)),
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Email'),
                    icon: Icon(Icons.email_outlined, size: 16)),
                ButtonSegment(
                    value: true,
                    label: Text('Teléfono'),
                    icon: Icon(Icons.phone_outlined, size: 16)),
              ],
              selected: {porTelefono},
              onSelectionChanged: (s) {
                setState(() {
                  porTelefono = s.first;
                  formKey.currentState?.reset();
                  emailError = null;
                });
              },
            ),
            const SizedBox(height: 14),
            if (!porTelefono)
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo del cliente',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  errorText: emailError,
                ),
                validator: (v) {
                  if (v == null || !v.contains('@')) return 'Email inválido';
                  final existe = clientes.any((c) => c.correo.toLowerCase() == v.trim().toLowerCase());
                  if (!existe) return 'El correo no está ligado a ningún cliente registrado';
                  return null;
                },
              )
            else
              TextFormField(
                controller: telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (ej. +52 555 000 0000)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().length < 7
                    ? 'Número inválido'
                    : null,
              ),
            const SizedBox(height: 16),
            const Text('Módulos de acceso:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                FilterChip(
                  label: const Text('Caja de Ahorro'),
                  avatar: const Icon(Icons.savings, size: 16),
                  selected: modulosSeleccionados.contains('caja'),
                  onSelected: (v) => setState(() => v ? modulosSeleccionados.add('caja') : modulosSeleccionados.remove('caja')),
                  showCheckmark: false,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Ventas'),
                  avatar: const Icon(Icons.store, size: 16),
                  selected: modulosSeleccionados.contains('ventas'),
                  onSelected: (v) => setState(() => v ? modulosSeleccionados.add('ventas') : modulosSeleccionados.remove('ventas')),
                  showCheckmark: false,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: guardando
              ? null
              : () async {
                  if (!formKey.currentState!.validate()) return;
                  setState(() => guardando = true);
                  final identificador = porTelefono
                      ? telefonoCtrl.text.trim()
                      : emailCtrl.text.trim().toLowerCase();
                  try {
                    // Buscar cliente correspondiente
                    final cliente = porTelefono
                        ? clientes.firstWhere(
                            (c) => c.telefono == identificador,
                            orElse: () => Cliente(id: '', nombre: '', apellido: '', montoSemana: 0, fechaInicio: DateTime.now()),
                          )
                        : clientes.firstWhere(
                            (c) => c.correo.toLowerCase() == identificador.toLowerCase(),
                            orElse: () => Cliente(id: '', nombre: '', apellido: '', montoSemana: 0, fechaInicio: DateTime.now()),
                          );
                    if (cliente.id.isEmpty) {
                      setState(() => guardando = false);
                      setState(() => emailError = 'El correo/teléfono no está ligado a ningún cliente registrado');
                      return;
                    }
                    await context.read<UsuariosProvider>().preRegistrar(
                      email: porTelefono ? null : identificador,
                      telefono: porTelefono ? identificador : null,
                      modulos: modulosSeleccionados.toList(),
                      clienteId: cliente.id,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Invitación creada para $identificador'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e
                              .toString()
                              .replaceFirst('Exception: ', '')),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } finally {
                    setState(() => guardando = false);
                  }
                },
          child: guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Invitar'),
        ),
      ],
    );
  }
}
