import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../widgets/quantity_control.dart';
import '../clients/client_list_screen.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          if (!orderProvider.carritoVacio)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Limpiar carrito'),
                    content: const Text(
                        '¿Estás seguro de limpiar todos los productos?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          orderProvider.limpiarCarrito();
                          Navigator.pop(context);
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: orderProvider.carritoVacio
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Carrito vacío',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Agrega productos del catálogo',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                if (orderProvider.clienteSeleccionado != null)
                  Container(
                    width: double.infinity,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cliente: ${orderProvider.clienteSeleccionado!.nombre}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ClientListScreen(isSelecting: true),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.carrito.length,
                    itemBuilder: (_, i) {
                      final item = orderProvider.carrito[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.nombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${currencyFormat.format(item.price.unitario)} c/u',
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  QuantityControl(
                                    quantity: item.quantity,
                                    onChanged: (qty) => orderProvider
                                        .actualizarCantidad(item.product.id, qty),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    onPressed: () {
                                      orderProvider
                                          .actualizarCantidad(item.product.id, 0);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${item.product.nombre} eliminado'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    constraints: const BoxConstraints(
                                        minWidth: 28, minHeight: 28),
                                    padding: EdgeInsets.zero,
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      currencyFormat.format(item.subtotal),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total',
                                  style: TextStyle(color: Colors.grey)),
                              Text(
                                currencyFormat.format(orderProvider.totalCarrito),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: orderProvider.tieneCliente
                              ? () {
                                  if (orderProvider.carritoVacio) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const OrderConfirmationScreen(),
                                    ),
                                  );
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Selecciona un cliente primero'),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Continuar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
