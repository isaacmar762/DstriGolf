import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import 'create_product_screen.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  List<ProductModel> _productos = [];
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
      final res = await svc.client.from('productos').select().order('nombre');
      _productos = (res as List).map((e) => ProductModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error cargando productos admin: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleActivo(ProductModel p) async {
    try {
      final svc = context.read<SupabaseService>();
      await svc.client.from('productos').update({'activo': false}).eq('id', p.id);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductScreen()),
          );
          if (ok == true) _cargar();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _productos.isEmpty
                ? const Center(child: Text('No hay productos'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _productos.length,
                    itemBuilder: (_, i) {
                      final p = _productos[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                p.referencia,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Ref: ${p.referencia} | ${p.nombreLinea ?? "Sin línea"}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _toggleActivo(p),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
