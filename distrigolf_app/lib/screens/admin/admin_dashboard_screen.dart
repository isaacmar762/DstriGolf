import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../helpers/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/user.dart';
import 'seller_management_screen.dart';
import 'reports_screen.dart';
import 'admin_product_list_screen.dart';
import 'admin_client_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<UserModel> _vendedores = [];
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarVendedores();
  }

  Future<void> _cargarVendedores() async {
    setState(() => _loading = true);
    try {
      final supabase = Provider.of<SupabaseService>(context, listen: false);
      _vendedores = await supabase.obtenerVendedores();
    } catch (e) {
      debugPrint('Error al cargar vendedores: $e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDesktop = Responsive.isDesktop(context);
    final pendientes = _vendedores.where((v) => !v.activo).length;
    final activos = _vendedores.where((v) => v.activo).length;

    final pages = [
      _buildDashboard(auth, pendientes, activos),
      const ReportsScreen(),
      SellerManagementScreen(vendedores: _vendedores),
      const AdminProductListScreen(),
      const AdminClientListScreen(),
    ];

    return Responsive(
      mobile: _buildMobileLayout(auth, pages),
      tablet: _buildDesktopLayout(auth, pages),
      desktop: _buildDesktopLayout(auth, pages),
    );
  }

  Widget _buildMobileLayout(AuthProvider auth, List<Widget> pages) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reportes'),
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Vendedores'),
          NavigationDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: 'Catálogo'),
          NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'Clientes'),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AuthProvider auth, List<Widget> pages) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Icon(Icons.admin_panel_settings, size: 36, color: AppTheme.primaryColor),
                  const SizedBox(height: 4),
                  const Text(
                    'Admin',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            groupAlignment: -0.3,
            destinations: [
              const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
              const NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Reportes')),
              const NavigationRailDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: Text('Vendedores')),
              const NavigationRailDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: Text('Catálogo')),
              const NavigationRailDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: Text('Clientes')),
            ],
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
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildDashboard(AuthProvider auth, int pendientes, int activos) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarVendedores,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _HeaderCard(pendientes: pendientes, activos: activos),
            const SizedBox(height: 24),
            Text(
              'Resumen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildKPIGrid(activos, pendientes),
            const SizedBox(height: 24),
            Text(
              'Vendedores Pendientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (pendientes == 0)
              _buildEmptyState()
            else
              ..._vendedores.where((v) => !v.activo).map(
                (v) => _PendingSellerCard(
                  vendedor: v,
                  onActivate: () async {
                    final supabase = Provider.of<SupabaseService>(context, listen: false);
                    await supabase.activarVendedor(v.id, true);
                    _cargarVendedores();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid(int activos, int pendientes) {
    final kpis = [
      _KPI('Vendedores Activos', activos.toString(), Icons.person, AppTheme.dashGreen),
      _KPI('Pendientes', pendientes.toString(), Icons.pending, AppTheme.dashOrange),
      _KPI('Total', _vendedores.length.toString(), Icons.group, AppTheme.dashBlue),
      _KPI('Reportes', '📊', Icons.bar_chart, AppTheme.dashPurple),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: kpis.length,
          itemBuilder: (_, i) => _KPICard(kpi: kpis[i]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green.shade300),
              const SizedBox(height: 12),
              const Text(
                'No hay vendedores pendientes',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int pendientes;
  final int activos;
  const _HeaderCard({required this.pendientes, required this.activos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Panel de Administración',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Gestiona vendedores y revisa reportes de ventas',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _KPI {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _KPI(this.label, this.value, this.icon, this.color);
}

class _KPICard extends StatelessWidget {
  final _KPI kpi;
  const _KPICard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kpi.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(kpi.icon, size: 20, color: kpi.color),
                ),
              ],
            ),
            const Spacer(),
            Text(
              kpi.value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: kpi.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kpi.label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSellerCard extends StatelessWidget {
  final UserModel vendedor;
  final VoidCallback onActivate;
  const _PendingSellerCard({required this.vendedor, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Text(
            vendedor.nombre[0].toUpperCase(),
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(vendedor.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(vendedor.email, style: const TextStyle(fontSize: 12)),
        trailing: ElevatedButton.icon(
          onPressed: onActivate,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Activar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dashGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
