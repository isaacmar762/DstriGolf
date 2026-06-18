import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';

class SellerManagementScreen extends StatelessWidget {
  final List<UserModel> vendedores;

  const SellerManagementScreen({super.key, required this.vendedores});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendedores')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Vendedores Registrados',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (vendedores.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No hay vendedores registrados')),
              ),
            )
          else
            ...vendedores.map(
              (v) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: v.activo
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Icon(
                      v.activo ? Icons.person : Icons.person_outline,
                      color: v.activo ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(v.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.email),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: v.esMayorista
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              v.esMayorista ? 'Mayorista' : 'TAT',
                              style: TextStyle(
                                fontSize: 11,
                                color: v.esMayorista
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: v.activo
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              v.activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 11,
                                color: v.activo ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      switch (value) {
                        case 'toggle':
                          final supabase = Provider.of<SupabaseService>(
                              context, listen: false);
                          supabase.activarVendedor(v.id, !v.activo);
                          break;
                        case 'zonas':
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Asignación de zonas - Próximamente')),
                          );
                          break;
                        case 'clientes':
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Asignación de clientes - Próximamente')),
                          );
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(v.activo ? 'Desactivar' : 'Activar'),
                      ),
                      const PopupMenuItem(
                        value: 'zonas',
                        child: Text('Asignar Zonas'),
                      ),
                      const PopupMenuItem(
                        value: 'clientes',
                        child: Text('Asignar Clientes'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
