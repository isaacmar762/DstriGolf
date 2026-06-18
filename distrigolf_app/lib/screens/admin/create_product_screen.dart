import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _lineaCtrl = TextEditingController(text: '');
  final _medidaCtrl = TextEditingController();
  final _volumenCtrl = TextEditingController();
  final _gradosCtrl = TextEditingController();
  final _precioMayoristaCtrl = TextEditingController();
  final _precioTatCtrl = TextEditingController();

  List<String> _lineasExistentes = [];
  File? _imagenSeleccionada;
  bool _saving = false;
  bool _usarLineaExistente = true;
  String? _lineaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarLineas();
  }

  Future<void> _cargarLineas() async {
    final svc = context.read<SupabaseService>();
    try {
      final lineas = await svc.obtenerLineas();
      if (mounted) setState(() => _lineasExistentes = lineas);
    } catch (_) {}
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (picked != null) {
      setState(() => _imagenSeleccionada = File(picked.path));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final svc = context.read<SupabaseService>();

      final nombreLinea = _usarLineaExistente ? _lineaSeleccionada : _lineaCtrl.text.trim();

      final productoId = await svc.client.from('productos').insert({
        'referencia': _refCtrl.text.trim(),
        'nombre': _nombreCtrl.text.trim(),
        'nombre_linea': (nombreLinea == null || nombreLinea.isEmpty) ? null : nombreLinea,
        'cod_medida': _medidaCtrl.text.isEmpty ? null : _medidaCtrl.text,
        'volumen': _volumenCtrl.text.isEmpty ? null : double.tryParse(_volumenCtrl.text),
        'grados': _gradosCtrl.text.isEmpty ? null : double.tryParse(_gradosCtrl.text),
        'activo': true,
      }).select('id').single();

      final newId = productoId['id'] as int;

      if (_imagenSeleccionada != null) {
        final bytes = await _imagenSeleccionada!.readAsBytes();
        final ext = _imagenSeleccionada!.path.split('.').last;
        final path = 'productos/$newId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        final url = await svc.uploadImagen('productos', path, bytes);
        await svc.actualizarProducto(newId, {'imagen_url': url});
      }

      if (_precioMayoristaCtrl.text.isNotEmpty) {
        final pMay = double.tryParse(_precioMayoristaCtrl.text);
        if (pMay != null) {
          await svc.client.from('precios_mayorista').insert({
            'producto_id': newId,
            'unitario': pMay,
            'bruto': pMay,
          });
        }
      }

      if (_precioTatCtrl.text.isNotEmpty) {
        final pTat = double.tryParse(_precioTatCtrl.text);
        if (pTat != null) {
          await svc.client.from('precios_tat').insert({
            'producto_id': newId,
            'unitario': pTat,
            'bruto': pTat,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto creado exitosamente')),
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
    _refCtrl.dispose();
    _nombreCtrl.dispose();
    _lineaCtrl.dispose();
    _medidaCtrl.dispose();
    _volumenCtrl.dispose();
    _gradosCtrl.dispose();
    _precioMayoristaCtrl.dispose();
    _precioTatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Producto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _refCtrl,
              decoration: const InputDecoration(labelText: 'Referencia *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            const Text('Línea / Categoría', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Usar línea existente'),
              value: _usarLineaExistente,
              onChanged: (v) => setState(() => _usarLineaExistente = v),
              dense: true,
            ),
            if (_usarLineaExistente)
              DropdownButtonFormField<String>(
                value: _lineaSeleccionada,
                decoration: const InputDecoration(labelText: 'Seleccionar línea'),
                items: _lineasExistentes
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _lineaSeleccionada = v),
              )
            else
              TextFormField(
                controller: _lineaCtrl,
                decoration: const InputDecoration(labelText: 'Nueva línea'),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _medidaCtrl,
                    decoration: const InputDecoration(labelText: 'Unidad medida'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _volumenCtrl,
                    decoration: const InputDecoration(labelText: 'Volumen'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gradosCtrl,
              decoration: const InputDecoration(labelText: 'Grados'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Precios', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precioMayoristaCtrl,
                    decoration: const InputDecoration(labelText: 'Precio Mayorista'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _precioTatCtrl,
                    decoration: const InputDecoration(labelText: 'Precio TAT'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Imagen', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _seleccionarImagen,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imagenSeleccionada != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('Tocar para agregar imagen', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _guardar,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar Producto'),
            ),
          ],
        ),
      ),
    );
  }
}
