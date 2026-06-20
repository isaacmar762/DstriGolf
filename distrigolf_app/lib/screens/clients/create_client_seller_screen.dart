import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class CreateClientSellerScreen extends StatefulWidget {
  const CreateClientSellerScreen({super.key});

  @override
  State<CreateClientSellerScreen> createState() =>
      _CreateClientSellerScreenState();
}

class _CreateClientSellerScreenState extends State<CreateClientSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _dvCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  List<Map<String, dynamic>> _zonas = [];
  int? _zonaId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cargarZonas();
  }

  Future<void> _cargarZonas() async {
    final svc = context.read<SupabaseService>();
    try {
      final zonas = await svc.obtenerZonas();
      if (mounted) setState(() => _zonas = zonas);
    } catch (_) {}
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final svc = context.read<SupabaseService>();
      final auth = context.read<AuthProvider>();
      await svc.crearClienteConVendedor(
        {
          'codigo': _codigoCtrl.text.isEmpty ? null : _codigoCtrl.text,
          'dv': _dvCtrl.text.isEmpty ? null : _dvCtrl.text,
          'nombre': _nombreCtrl.text.trim(),
          'direccion':
              _direccionCtrl.text.isEmpty ? null : _direccionCtrl.text,
          'email': _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
          'ciudad': _ciudadCtrl.text.isEmpty ? null : _ciudadCtrl.text,
          'zona_id': _zonaId,
          'activo': true,
        },
        auth.user!.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente creado exitosamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _dvCtrl.dispose();
    _direccionCtrl.dispose();
    _emailCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _codigoCtrl,
                    decoration: const InputDecoration(labelText: 'Código'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dvCtrl,
                    decoration: const InputDecoration(labelText: 'DV'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ciudadCtrl,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _zonaId,
              decoration: const InputDecoration(labelText: 'Zona'),
              items: _zonas
                  .map((z) => DropdownMenuItem(
                        value: z['id'] as int,
                        child: Text(z['nombre'] as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _zonaId = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _guardar,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar Cliente'),
            ),
          ],
        ),
      ),
    );
  }
}
