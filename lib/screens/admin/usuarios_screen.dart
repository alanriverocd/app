import 'widgets/invite_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caja_ahorro_provider.dart';

import '../../models/cliente.dart';
import '../../providers/usuarios_provider.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuariosProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UsuariosProvider>();
    final myUid = context.read<AuthProvider>().currentUser?.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialogoPreRegistrar(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Invitar cliente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Usuarios',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text('Administración de accesos',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pre-registra clientes por email para que puedan crear su cuenta. '
                      'Solo correos autorizados pueden registrarse.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (prov.loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator()))
          else if (prov.usuarios.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('Sin usuarios registrados',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            for (final u in prov.usuarios)
              _UsuarioCard(usuario: u, esMiUsuario: u.uid == myUid),
        ],
      ),
    ),
  );
  }

  Future<void> _dialogoPreRegistrar(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const InviteDialog(),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final Usuario usuario;
  final bool esMiUsuario;

  const _UsuarioCard({required this.usuario, required this.esMiUsuario});

  @override
  Widget build(BuildContext context) {
    final caja = Provider.of<CajaAhorroProvider>(context, listen: false);
    String displayName = usuario.nombre;
    if ((displayName.isEmpty || displayName == usuario.email) && usuario.clienteId != null) {
      final cliente = caja.clientes.firstWhere(
        (c) => c.id == usuario.clienteId,
        orElse: () => Cliente(
          id: '',
          nombre: '',
          apellido: '',
          montoSemana: 0,
          fechaInicio: DateTime.now(),
        ),
      );
      if (cliente.id.isNotEmpty) {
        displayName = cliente.nombreCompleto;
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esMiUsuario
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    backgroundColor: usuario.preRegistrado
                      ? Colors.orange.withAlpha(31)
                      : usuario.esAdmin
                        ? Colors.purple.withAlpha(31)
                        : Colors.blue.withAlpha(31),
                  child: Icon(
                    usuario.preRegistrado
                        ? Icons.hourglass_empty
                        : usuario.esAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person,
                    color: usuario.preRegistrado
                        ? Colors.orange
                        : usuario.esAdmin
                            ? Colors.purple
                            : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName.isNotEmpty ? displayName : usuario.email,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (esMiUsuario) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Tú',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                          usuario.email.isNotEmpty
                              ? usuario.email
                              : usuario.telefono,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (usuario.preRegistrado) ...[  
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withAlpha(128)),
                    ),
                    child: const Text('Pendiente',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    tooltip: 'Cancelar invitación',
                    onPressed: () =>
                        _eliminarInvitacion(context, usuario),
                  ),
                ] else
                  _RolBadge(rol: usuario.rol),
              ],
            ),
            if (!usuario.preRegistrado) ...[  
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Selector de rol ───────────────────────────────────────
            Row(
              children: [
                const Text('Rol:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 12),
                _RolSelector(usuario: usuario),
              ],
            ),
            const SizedBox(height: 10),

            // ── Módulos ───────────────────────────────────────────────
            if (!usuario.esAdmin) ...[
              const Text('Módulos de acceso:',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _ModuloChip(
                    label: 'Caja de Ahorro',
                    icon: Icons.savings,
                    activo: usuario.modulos.contains('caja'),
                    onChanged: (v) => _toggleModulo(context, usuario, 'caja', v),
                  ),
                  const SizedBox(width: 8),
                  _ModuloChip(
                    label: 'Ventas',
                    icon: Icons.store,
                    activo: usuario.modulos.contains('ventas'),
                    onChanged: (v) =>
                        _toggleModulo(context, usuario, 'ventas', v),
                  ),
                ],
              ),
              // ── Vincular cliente (si tiene caja) ───────────────────
              if (usuario.modulos.contains('caja')) ...[
                const SizedBox(height: 10),
                _VincularClienteRow(usuario: usuario),
              ],
            ] else
              Text(
                'Los administradores tienen acceso completo a todos los módulos.',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],  // cierre if (!usuario.preRegistrado)
          ],
        ),
      ),
    );
  }

  void _eliminarInvitacion(BuildContext context, Usuario u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar invitación'),
        content: Text('¿Eliminar la invitación para ${u.email}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<UsuariosProvider>()
                  .eliminarPreRegistro(u.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Invitación de ${u.email} cancelada'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _toggleModulo(
      BuildContext context, Usuario u, String modulo, bool activo) {
    final modulos = List<String>.from(u.modulos);
    if (activo) {
      modulos.add(modulo);
    } else {
      modulos.remove(modulo);
    }
    context.read<UsuariosProvider>().asignarModulos(u.uid, modulos).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Módulos actualizados para ${u.nombre}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
  }
}

class _RolSelector extends StatelessWidget {
  final Usuario usuario;
  const _RolSelector({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RolUsuario>(
      style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 12)),
      segments: const [
        ButtonSegment(
            value: RolUsuario.admin,
            label: Text('Admin'),
            icon: Icon(Icons.admin_panel_settings, size: 16)),
        ButtonSegment(
            value: RolUsuario.cliente,
            label: Text('Cliente'),
            icon: Icon(Icons.person, size: 16)),
      ],
      selected: {usuario.rol},
      onSelectionChanged: (sel) {
        final nuevoRol = sel.first;
        context
            .read<UsuariosProvider>()
            .asignarRol(usuario.uid, nuevoRol)
            .then((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Rol cambiado a ${nuevoRol == RolUsuario.admin ? "Administrador" : "Cliente"}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ));
          }
        });
      },
    );
  }
}

class _ModuloChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool activo;
  final ValueChanged<bool> onChanged;

  const _ModuloChip({
    required this.label,
    required this.icon,
    required this.activo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? Theme.of(context).colorScheme.primary : Colors.grey;
    return FilterChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      selected: activo,
      onSelected: onChanged,
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _VincularClienteRow extends StatelessWidget {
  final Usuario usuario;
  const _VincularClienteRow({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final clientes = context.read<CajaAhorroProvider>().clientes;

    return Row(
      children: [
        const Icon(Icons.link, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        const Text('Registro en caja:',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: usuario.clienteId,
              isDense: true,
              hint: const Text('Sin vincular',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin vincular',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                ...clientes.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.nombreCompleto,
                          style: const TextStyle(fontSize: 12)),
                    )),
              ],
              onChanged: (clienteId) {
                context
                    .read<UsuariosProvider>()
                    .vincularCliente(usuario.uid, clienteId)
                    .then((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(clienteId == null
                          ? 'Vínculo removido'
                          : 'Cliente vinculado correctamente'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RolBadge extends StatelessWidget {
  final RolUsuario rol;
  const _RolBadge({required this.rol});

  @override
  Widget build(BuildContext context) {
    final esAdmin = rol == RolUsuario.admin;
    final color = esAdmin ? Colors.purple : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        esAdmin ? 'Admin' : 'Cliente',
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
