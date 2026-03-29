import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/usuarios_provider.dart';
import '../../providers/caja_ahorro_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/usuario.dart';

class PermisosMenuScreen extends StatefulWidget {
  const PermisosMenuScreen({super.key});

  @override
  State<PermisosMenuScreen> createState() => _PermisosMenuScreenState();
}

class _PermisosMenuScreenState extends State<PermisosMenuScreen> {
  Usuario? _usuarioSeleccionado;
  final Map<String, bool> _menusSeleccionados = {};
  bool _guardando = false;

  final List<Map<String, String>> _menusDisponibles = [
    {'id': 'dashboard', 'label': 'Dashboard'},
    {'id': 'mis_pagos', 'label': 'Mis Pagos'},
    {'id': 'mis_compras', 'label': 'Mis Compras'},
    {'id': 'resumen', 'label': 'Resumen'},
    {'id': 'clientes', 'label': 'Clientes'},
    {'id': 'ingresos', 'label': 'Ingresos'},
    {'id': 'graficos', 'label': 'Gráficos'},
    {'id': 'productos', 'label': 'Productos'},
    {'id': 'nueva_venta', 'label': 'Nueva Venta'},
    {'id': 'usuarios', 'label': 'Usuarios'},
  ];

  @override
  Widget build(BuildContext context) {
    final usuariosProvider = context.watch<UsuariosProvider>();
    final cajaAhorroProvider = context.watch<CajaAhorroProvider>();
    final usuarios = usuariosProvider.clientes;
    final clientes = cajaAhorroProvider.clientes;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Menús por Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona un usuario:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<Usuario>(
              value: _usuarioSeleccionado,
              hint: const Text('Usuario'),
              items: usuarios.map((u) => DropdownMenuItem(
                value: u,
                child: Text(u.email),
              )).toList(),
              onChanged: (u) async {
                setState(() {
                  _usuarioSeleccionado = u;
                  _menusSeleccionados.clear();
                });
                if (u != null) {
                  final permisos = await usuariosProvider.getMenusPermitidos(u.uid);
                  setState(() {
                    for (final menu in _menusDisponibles) {
                      _menusSeleccionados[menu['id']!] = permisos.contains(menu['id']);
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            if (_usuarioSeleccionado != null) ...[
              const SizedBox(height: 12),
              Text('Ligar a cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _usuarioSeleccionado!.clienteId,
                hint: const Text('Selecciona cliente'),
                items: clientes.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.nombreCompleto} (${c.correo})'),
                )).toList(),
                onChanged: (clienteId) async {
                  if (clienteId != null) {
                    await usuariosProvider.vincularCliente(_usuarioSeleccionado!.uid, clienteId);
                    setState(() {
                      _usuarioSeleccionado = usuariosProvider.clientes.firstWhere((u) => u.uid == _usuarioSeleccionado!.uid);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: _menusDisponibles.map((menu) {
                    return CheckboxListTile(
                      title: Text(menu['label']!),
                      value: _menusSeleccionados[menu['id']] ?? false,
                      onChanged: (v) {
                        setState(() {
                          _menusSeleccionados[menu['id']!] = v ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: _guardando || _usuarioSeleccionado!.clienteId == null
                      ? null
                      : () async {
                    setState(() { _guardando = true; });
                    await usuariosProvider.setMenusPermitidos(
                      _usuarioSeleccionado!.uid,
                      _menusSeleccionados.entries.where((e) => e.value).map((e) => e.key).toList(),
                    );
                    setState(() { _guardando = false; });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permisos guardados')),
                    );
                  },
                  child: _guardando ? const CircularProgressIndicator() : const Text('Guardar Permisos'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
