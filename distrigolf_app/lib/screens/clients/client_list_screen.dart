import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/order_provider.dart';
import '../products/product_catalog_screen.dart';
import 'client_detail_screen.dart';
import 'create_client_seller_screen.dart';

class ClientListScreen extends StatefulWidget {
  final bool isSelecting;

  const ClientListScreen({super.key, this.isSelecting = false});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<ClientProvider>().cargarClientes(auth.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<ClientProvider>();
    final isSelecting = widget.isSelecting;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelecting ? 'Seleccionar Cliente' : 'Clientes'),
        actions: [
          if (isSelecting)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
        ],
      ),
      floatingActionButton: isSelecting
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateClientSellerScreen()),
                );
                if (ok == true) {
                  final auth = context.read<AuthProvider>();
                  if (auth.user != null) {
                    context
                        .read<ClientProvider>()
                        .cargarClientes(auth.user!.id);
                  }
                }
              },
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          clientProvider.setBusqueda('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => clientProvider.setBusqueda(v),
            ),
          ),
          Expanded(
            child: clientProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : clientProvider.clientes.isEmpty
                    ? const Center(
                        child: Text('No se encontraron clientes'),
                      )
                    : ListView.builder(
                        itemCount: clientProvider.clientes.length,
                        itemBuilder: (_, i) =>
                            _ClientTile(client: clientProvider.clientes[i], isSelecting: isSelecting),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final ClientModel client;
  final bool isSelecting;

  const _ClientTile({required this.client, this.isSelecting = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            client.nombre.isNotEmpty
                ? client.nombre[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        title: Text(
          client.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.ciudad != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(client.ciudad!, style: const TextStyle(fontSize: 12)),
                ],
              ),
            if (client.direccion != null)
              Text(
                client.direccion!,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: isSelecting
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: isSelecting
            ? () {
                context.read<OrderProvider>().seleccionarCliente(client);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductCatalogScreen()));
              }
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientDetailScreen(clientId: client.id),
                  ),
                ),
      ),
    );
  }
}
