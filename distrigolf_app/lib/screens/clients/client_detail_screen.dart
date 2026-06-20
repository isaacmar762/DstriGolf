import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/client_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../admin/edit_client_screen.dart';
import '../products/product_catalog_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().seleccionarCliente(widget.clientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<ClientProvider>();
    final client = clientProvider.clienteSeleccionado;

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cliente')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(client.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditClientScreen(client: client),
                ),
              );
              if (ok == true) {
                context
                    .read<ClientProvider>()
                    .seleccionarCliente(client.id);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            client.nombre[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.nombre,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (client.codigo != null)
                                Text(
                                  'Código: ${client.codigo}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'Dirección',
                      value: client.direccion ?? 'Sin dirección',
                    ),
                    _InfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: client.email ?? 'Sin email',
                    ),
                    _InfoRow(
                      icon: Icons.location_city,
                      label: 'Ciudad',
                      value: client.ciudad ?? 'Sin ciudad',
                    ),
                    if (client.zonaNombre != null)
                      _InfoRow(
                        icon: Icons.map,
                        label: 'Zona',
                        value: client.zonaNombre!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final orderProvider = context.read<OrderProvider>();
                  orderProvider.seleccionarCliente(client);
                  context.read<ProductProvider>().cargarProductos();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductCatalogScreen()));
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Nuevo Pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
