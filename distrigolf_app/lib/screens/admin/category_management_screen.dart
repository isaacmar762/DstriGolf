import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<String> _lineas = [];
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
      final lineas = await svc.obtenerLineas();
      if (mounted) setState(() => _lineas = lineas);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _crearLinea() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() => _lineas.add(ctrl.text.trim()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Categoría "${ctrl.text.trim()}" creada')),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _crearLinea),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lineas.isEmpty
              ? const Center(child: Text('No hay categorías'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lineas.length,
                    itemBuilder: (_, i) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.category),
                        title: Text(_lineas[i]),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
                ),
    );
  }
}
