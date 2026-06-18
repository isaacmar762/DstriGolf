import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _ventas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() => _loading = true);
    try {
      final supabase =
          Provider.of<SupabaseService>(context, listen: false);
      _ventas = await supabase.obtenerReporteVentas();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalVentas =
        _ventas.fold<double>(0, (sum, v) => sum + (v['total'] as num).toDouble());
    final ventasHoy = _ventas
        .where((v) {
          final fecha = DateTime.tryParse(v['fecha'] as String? ?? '');
          if (fecha == null) return false;
          final now = DateTime.now();
          return fecha.year == now.year &&
              fecha.month == now.month &&
              fecha.day == now.day;
        })
        .fold<double>(0, (sum, v) => sum + (v['total'] as num).toDouble());

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: RefreshIndicator(
        onRefresh: _cargarReportes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _ReportCard(
                    title: 'Total Ventas',
                    value: '\$${totalVentas.toStringAsFixed(0)}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReportCard(
                    title: 'Ventas Hoy',
                    value: '\$${ventasHoy.toStringAsFixed(0)}',
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ReportCard(
                    title: 'Pedidos Total',
                    value: '${_ventas.length}',
                    icon: Icons.receipt_long,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReportCard(
                    title: 'Promedio',
                    value: _ventas.isNotEmpty
                        ? '\$${(totalVentas / _ventas.length).toStringAsFixed(0)}'
                        : '\$0',
                    icon: Icons.analytics,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Últimas Ventas',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_ventas.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No hay ventas registradas')),
                ),
              )
            else
              ..._ventas.take(20).map(
                    (v) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.receipt,
                              color: AppTheme.primaryColor),
                        ),
                        title: Text(
                          v['vendedor_nombre'] ?? 'Vendedor',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          v['cliente_nombre'] ?? 'Cliente',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '\$${(v['total'] as num).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
