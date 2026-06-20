import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _refCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _lineaCtrl;
  late final TextEditingController _medidaCtrl;
  late final TextEditingController _volumenCtrl;
  late final TextEditingController _gradosCtrl;
  late final TextEditingController _precioMayoristaCtrl;
  late final TextEditingController _precioTatCtrl;

  List<String> _lineasExistentes = [];
  bool _saving = false;
  bool _usarLineaExistente = true;
  String? _lineaSeleccionada;
  double? _precioMayoristaActual;
  double? _precioTatActual;
  bool _cargandoPrecios = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _refCtrl = TextEditingController(text: p.referencia);
    _nombreCtrl = TextEditingController(text: p.nombre);
    _lineaCtrl = TextEditingController(text: p.nombreLinea ?? '');
    _medidaCtrl = TextEditingController(text: p.codMedida ?? '');
    _volumenCtrl = TextEditingController(text: p.volumen?.toString() ?? '');
    _gradosCtrl = TextEditingController(text: p.grados?.toString() ?? '');
    _precioMayoristaCtrl = TextEditingController();
    _precioTatCtrl = TextEditingController();
    _lineaSeleccionada = p.nombreLinea;
    _cargarLineas();
    _cargarPrecios();
  }

  Future<void> _cargarLineas() async {
    final svc = context.read<SupabaseService>();
    try {
      final lineas = await svc.obtenerLineas();
      if (mounted) setState(() => _lineasExistentes = lineas);
    } catch (_) {}
  }

  Future<void> _cargarPrecios() async {
    final svc = context.read<SupabaseService>();
    try {
      final resM = await svc.client
          .from('precios_mayorista')
          .select()
          .eq('producto_id', widget.product.id)
          .maybeSingle();
      final resT = await svc.client
          .from('precios_tat')
          .select()
          .eq('producto_id', widget.product.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          if (resM != null) {
            _precioMayoristaActual = (resM['unitario'] as num?)?.toDouble();
            _precioMayoristaCtrl.text = _precioMayoristaActual?.toString() ?? '';
          }
          if (resT != null) {
            _precioTatActual = (resT['unitario'] as num?)?.toDouble();
            _precioTatCtrl.text = _precioTatActual?.toString() ?? '';
          }
          _cargandoPrecios = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoPrecios = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final svc = context.read<SupabaseService>();
      final nombreLinea =
          _usarLineaExistente ? _lineaSeleccionada : _lineaCtrl.text.trim();

      await svc.actualizarProducto(widget.product.id, {
        'referencia': _refCtrl.text.trim(),
        'nombre': _nombreCtrl.text.trim(),
        'nombre_linea':
            (nombreLinea == null || nombreLinea.isEmpty) ? null : nombreLinea,
        'cod_medida': _medidaCtrl.text.isEmpty ? null : _medidaCtrl.text,
        'volumen': _volumenCtrl.text.isEmpty
            ? null
            : double.tryParse(_volumenCtrl.text),
        'grados': _gradosCtrl.text.isEmpty
            ? null
            : double.tryParse(_gradosCtrl.text),
      });

      if (_precioMayoristaCtrl.text.isNotEmpty) {
        final pMay = double.tryParse(_precioMayoristaCtrl.text);
        if (pMay != null) {
          if (_precioMayoristaActual != null) {
            await svc.client
                .from('precios_mayorista')
                .update({'unitario': pMay, 'bruto': pMay})
                .eq('producto_id', widget.product.id);
          } else {
            await svc.client.from('precios_mayorista').insert({
              'producto_id': widget.product.id,
              'unitario': pMay,
              'bruto': pMay,
            });
          }
        }
      }

      if (_precioTatCtrl.text.isNotEmpty) {
        final pTat = double.tryParse(_precioTatCtrl.text);
        if (pTat != null) {
          if (_precioTatActual != null) {
            await svc.client
                .from('precios_tat')
                .update({'unitario': pTat, 'bruto': pTat})
                .eq('producto_id', widget.product.id);
          } else {
            await svc.client.from('precios_tat').insert({
              'producto_id': widget.product.id,
              'unitario': pTat,
              'bruto': pTat,
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado exitosamente')),
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
      appBar: AppBar(title: const Text('Editar Producto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _refCtrl,
              decoration: const InputDecoration(labelText: 'Referencia *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            const Text('Línea / Categoría',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
                decoration:
                    const InputDecoration(labelText: 'Seleccionar línea'),
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
                    decoration:
                        const InputDecoration(labelText: 'Unidad medida'),
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
            const Text('Precios',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_cargandoPrecios)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioMayoristaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Precio Mayorista',
                        hintText: _precioMayoristaActual?.toString(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _precioTatCtrl,
                      decoration: InputDecoration(
                        labelText: 'Precio TAT',
                        hintText: _precioTatActual?.toString(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
              label: Text(_saving ? 'Guardando...' : 'Actualizar Producto'),
            ),
          ],
        ),
      ),
    );
  }
}
