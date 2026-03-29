import 'package:flutter/material.dart';
import '../../../models/cliente.dart';

class DashboardUserHeader extends StatelessWidget {
  final Cliente cliente;
  const DashboardUserHeader({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cliente.nombreCompleto.isNotEmpty ? cliente.nombreCompleto : 'Usuario',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (cliente.correo.isNotEmpty)
          Text(
            cliente.correo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
