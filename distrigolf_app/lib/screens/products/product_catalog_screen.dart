import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../models/price.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/quantity_control.dart';
import '../orders/cart_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final tipoVendedor = auth.user?.tipoVendedor ?? 'MAYORISTA';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        actions: [
          if (orderProvider.itemCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${orderProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              productProvider.setBusqueda('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => productProvider.setBusqueda(v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Todas',
                        selected: productProvider.lineaSeleccionada == null,
                        onTap: () => productProvider.setLinea(null),
                      ),
                      ...productProvider.lineas.map(
                        (linea) => _FilterChip(
                          label: linea,
                          selected:
                              productProvider.lineaSeleccionada == linea,
                          onTap: () => productProvider.setLinea(linea),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: productProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.productos.isEmpty
                    ? const Center(child: Text('No hay productos'))
                    : RefreshIndicator(
                        onRefresh: () => productProvider.cargarProductos(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: productProvider.productos.length,
                          itemBuilder: (_, i) => _ProductCard(
                            product: productProvider.productos[i],
                            tipoVendedor: tipoVendedor,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : null,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryColor,
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ProductModel product;
  final String tipoVendedor;

  const _ProductCard({
    required this.product,
    required this.tipoVendedor,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.product.nombreLinea?.substring(0, 2).toUpperCase() ?? '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Ref: ${widget.product.referencia}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.product.nombreLinea ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FutureBuilder<PriceModel?>(
              future: context
                  .read<ProductProvider>()
                  .obtenerPrecio(widget.product.id, widget.tipoVendedor),
              builder: (_, snap) {
                if (!snap.hasData) return const Text('...');
                final price = snap.data!;
                final enCarrito = context.watch<OrderProvider>().carrito
                    .where((c) => c.product.id == widget.product.id);

                if (enCarrito.isNotEmpty) {
                  final cartItem = enCarrito.first;
                  return _QuantityControl(
                    quantity: cartItem.quantity,
                    price: price,
                    onChanged: (qty) {
                      context.read<OrderProvider>().actualizarCantidad(
                          widget.product.id, qty);
                    },
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price.unitario.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          final qty =
                              int.tryParse(_qtyController.text) ?? 1;
                          context
                              .read<OrderProvider>()
                              .agregarAlCarrito(widget.product, price);
                          if (qty > 1) {
                            context
                                .read<OrderProvider>()
                                .actualizarCantidad(widget.product.id, qty);
                          }
                          _qtyController.text = '1';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${widget.product.nombre} agregado'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('+'),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      height: 28,
                      child: TextField(
                        controller: _qtyController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          hintText: '1',
                          hintStyle: const TextStyle(fontSize: 11),
                        ),
                        style: const TextStyle(fontSize: 11),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null && n < 1) _qtyController.text = '1';
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final PriceModel price;
  final ValueChanged<int> onChanged;

  const _QuantityControl({
    required this.quantity,
    required this.price,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${(price.unitario * quantity).toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        QuantityControl(
          quantity: quantity,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
