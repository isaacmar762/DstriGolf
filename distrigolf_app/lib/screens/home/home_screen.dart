import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../helpers/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../clients/client_list_screen.dart';
import '../products/product_catalog_screen.dart';
import '../orders/order_history_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _DashboardTab(),
    const ClientListScreen(),
    const ProductCatalogScreen(),
    const OrderHistoryScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outlined),
      selectedIcon: Icon(Icons.people),
      label: 'Clientes',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Catálogo',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Pedidos',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final isDesktop = Responsive.isDesktop(context);

    if (auth.esAdmin) {
      return const AdminDashboardScreen();
    }

    return Responsive(
      mobile: _buildMobileLayout(auth, orderProvider),
      tablet: _buildDesktopLayout(auth, orderProvider),
      desktop: _buildDesktopLayout(auth, orderProvider),
    );
  }

  Widget _buildMobileLayout(AuthProvider auth, OrderProvider orderProvider) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _buildDestinations(orderProvider),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToNewOrder(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Pedido'),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(AuthProvider auth, OrderProvider orderProvider) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Icon(Icons.golf_course, size: 36, color: AppTheme.primaryColor),
                  const SizedBox(height: 4),
                  Text(
                    'DistriGolf',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            groupAlignment: -0.3,
            destinations: _buildRailDestinations(orderProvider),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.grey),
                onPressed: () => auth.logout(),
                tooltip: 'Cerrar sesión',
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToNewOrder(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Pedido'),
            )
          : null,
    );
  }

  List<NavigationDestination> _buildDestinations(OrderProvider orderProvider) {
    return _destinations.asMap().entries.map((e) {
      if (e.key == 3) {
        return NavigationDestination(
          icon: Badge(
            isLabelVisible: orderProvider.itemCount > 0,
            label: Text('${orderProvider.itemCount}'),
            child: const Icon(Icons.receipt_long_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: orderProvider.itemCount > 0,
            label: Text('${orderProvider.itemCount}'),
            child: const Icon(Icons.receipt_long),
          ),
          label: 'Pedidos',
        );
      }
      return e.value;
    }).toList();
  }

  List<NavigationRailDestination> _buildRailDestinations(OrderProvider orderProvider) {
    final icons = [
      Icons.dashboard_outlined,
      Icons.people_outlined,
      Icons.inventory_2_outlined,
      Icons.receipt_long_outlined,
    ];
    final selectedIcons = [
      Icons.dashboard,
      Icons.people,
      Icons.inventory_2,
      Icons.receipt_long,
    ];
    final labels = ['Inicio', 'Clientes', 'Catálogo', 'Pedidos'];

    return List.generate(4, (i) {
      return NavigationRailDestination(
        icon: i == 3 && orderProvider.itemCount > 0
            ? Badge(
                isLabelVisible: true,
                label: Text('${orderProvider.itemCount}'),
                child: Icon(icons[i]),
              )
            : Icon(icons[i]),
        selectedIcon: i == 3 && orderProvider.itemCount > 0
            ? Badge(
                isLabelVisible: true,
                label: Text('${orderProvider.itemCount}'),
                child: Icon(selectedIcons[i]),
              )
            : Icon(selectedIcons[i]),
        label: Text(labels[i]),
      );
    });
  }

  void _navigateToNewOrder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientListScreen(isSelecting: true),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => auth.logout(),
              tooltip: 'Cerrar sesión',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(user: user),
            const SizedBox(height: 24),
            Text(
              'Acceso Rápido',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            _QuickActionsGrid(),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isDesktop ? 32 : 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              user?.nombre.isNotEmpty == true
                  ? user!.nombre[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: isDesktop ? 28 : 24,
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
                  user?.nombre ?? 'Usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.esMayorista == true ? 'Vendedor Mayorista' : 'Vendedor TAT',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    final actions = [
      _ActionData('Clientes', Icons.people, AppTheme.dashBlue, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ClientListScreen(isSelecting: true),
        ));
      }),
      _ActionData('Catálogo', Icons.inventory_2, AppTheme.dashGreen, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ProductCatalogScreen(),
        ));
      }),
      _ActionData('Mis Pedidos', Icons.receipt_long, AppTheme.dashPurple, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const OrderHistoryScreen(),
        ));
      }),
      _ActionData('Nuevo Pedido', Icons.add_shopping_cart, AppTheme.dashOrange, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ClientListScreen(isSelecting: true),
        ));
      }),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 4 : (constraints.maxWidth > 400 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isDesktop ? 1.4 : 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) => _ActionCard(data: actions[i]),
        );
      },
    );
  }
}

class _ActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionData(this.label, this.icon, this.color, this.onTap);
}

class _ActionCard extends StatelessWidget {
  final _ActionData data;
  const _ActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, size: 28, color: data.color),
              ),
              const SizedBox(height: 12),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
