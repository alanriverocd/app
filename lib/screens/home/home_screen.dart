import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FINATIOL'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${user?.displayName ?? user?.email ?? 'Usuario'}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu dashboard financiero',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              // TODO: Agregar widgets del dashboard financiero
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        size: 80, color: Color(0xFF1B4F72)),
                    SizedBox(height: 16),
                    Text('Dashboard en construccion'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
