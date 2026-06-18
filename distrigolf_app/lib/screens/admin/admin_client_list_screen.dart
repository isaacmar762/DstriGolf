import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/supabase_service.dart';
import 'create_client_screen.dart';

class AdminClientListScreen extends StatefulWidget {
  const AdminClientListScreen({super.key});

  @override
  State<AdminClientListScreen> createState() => _AdminClientListScreenState();
}

class _AdminClientListScreenState extends State<AdminClientListScreen> {
  List<Map<String, dynamic>> _clientes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<SupabaseService>();
      final res = await svc.client.from('clientes').select('*, zonas(id, nombre)').order('nombre');
      _clientes = (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error cargando clientes admin: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateClientScreen()),
          );
          if (ok == true) _cargar();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _clientes.isEmpty
                ? const Center(child: Text('No hay clientes'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _clientes.length,
                    itemBuilder: (_, i) {
                      final c = _clientes[i];
                      final zonaNombre = c['zonas']?['nombre'] as String?;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              (c['nombre'] as String)[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          title: Text(c['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            c['codigo'] != null
                                ? 'Cód: ${c['codigo']}${c['dv'] != null ? "-${c['dv']}" : ""}${zonaNombre != null ? " | $zonaNombre" : ""}'
                                : zonaNombre ?? '',
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
