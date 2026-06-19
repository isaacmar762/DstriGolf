import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_badge.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<OrderProvider>().cargarPedidos(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: orderProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      orderProvider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : orderProvider.pedidos.isEmpty
                  ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay pedidos aún',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      context.read<OrderProvider>().cargarPedidos(
                            context.read<AuthProvider>().user!.id,
                          ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.pedidos.length,
                    itemBuilder: (_, i) {
                      final pedido = orderProvider.pedidos[i];
                      return Card(
                        child: ListTile(
                          leading: OrderStatusIcon(estado: pedido.estado),
                          title: Text(
                            pedido.cliente?.nombre ?? 'Cliente #${pedido.clienteId}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (pedido.fecha != null)
                                Text(
                                  dateFormat.format(pedido.fecha!),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              Text(
                                currencyFormat.format(pedido.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          trailing: OrderStatusBadge(estado: pedido.estado),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailScreen(orderId: pedido.id!),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


