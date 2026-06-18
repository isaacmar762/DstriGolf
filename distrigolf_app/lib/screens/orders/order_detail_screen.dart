import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _showSignature = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().cargarPedido(widget.orderId);
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _agregarFirma() async {
    if (_signatureController.isEmpty) return;
    setState(() => _processing = true);
    final signatureData = await _signatureController.toPngBytes();
    if (signatureData != null) {
      final base64Firma = base64Encode(signatureData);
      final orderProvider = context.read<OrderProvider>();
      orderProvider.setFirma(base64Firma);
      await orderProvider.agregarFirmaAPedido(widget.orderId);
    }
    if (mounted) {
      context.read<OrderProvider>().cargarPedido(widget.orderId);
      setState(() {
        _processing = false;
        _showSignature = false;
      });
      _signatureController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firma agregada al pedido')),
      );
    }
  }

  Future<void> _confirmarPedido() async {
    setState(() => _processing = true);
    await context.read<OrderProvider>().confirmarPedidoExistente(widget.orderId);
    if (mounted) {
      context.read<OrderProvider>().cargarPedido(widget.orderId);
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido confirmado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final pedido = orderProvider.pedidoActual;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    if (pedido == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final esBorrador = pedido.estado == 'BORRADOR';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Pedido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        OrderStatusIcon(estado: pedido.estado),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedido #${pedido.id?.substring(0, 8).toUpperCase() ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (pedido.fecha != null)
                                Text(
                                  dateFormat.format(pedido.fecha!),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        OrderStatusBadge(estado: pedido.estado),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cliente',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(pedido.cliente?.nombre ?? 'Cliente #${pedido.clienteId}'),
                    if (pedido.cliente?.direccion != null)
                      Text(pedido.cliente!.direccion!,
                          style: const TextStyle(color: Colors.grey)),
                    if (pedido.cliente?.ciudad != null)
                      Text(pedido.cliente!.ciudad!,
                          style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Productos',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (pedido.items == null || pedido.items!.isEmpty)
                      const Text('Sin productos')
                    else
                      ...pedido.items!.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.producto?.nombre ??
                                          'Producto #${item.productoId}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    Text(
                                      '${item.cantidad} x ${currencyFormat.format(item.precioUnitario)}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.subtotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          currencyFormat.format(pedido.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (pedido.notas != null && pedido.notas!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notas',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(pedido.notas!),
                    ],
                  ),
                ),
              ),
            ],
            if (pedido.firma != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Firma del Cliente',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.memory(
                          base64Decode(pedido.firma!.split(',').last),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (esBorrador) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              if (pedido.firma == null) ...[
                const Text(
                  'Acciones disponibles',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                if (_showSignature) ...[
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Signature(
                      controller: _signatureController,
                      height: 150,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpiar'),
                        onPressed: () => _signatureController.clear(),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _processing ? null : _agregarFirma,
                        icon: _processing
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check, size: 18),
                        label: const Text('Guardar Firma'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showSignature = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Agregar Firma del Cliente'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _processing ? null : _confirmarPedido,
                  icon: _processing
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle),
                  label: const Text('Confirmar Pedido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dashGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


