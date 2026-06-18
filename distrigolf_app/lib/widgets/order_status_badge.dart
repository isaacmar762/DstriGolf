import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String estado;

  const OrderStatusBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 12,
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderStatusIcon extends StatelessWidget {
  final String estado;

  const OrderStatusIcon({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(estado);
    return CircleAvatar(
      backgroundColor: config.color.withOpacity(0.1),
      child: Icon(config.icon, color: config.color, size: 20),
    );
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  _StatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}

_StatusConfig _getConfig(String estado) {
  switch (estado) {
    case 'BORRADOR':
      return _StatusConfig(
        label: 'Borrador',
        color: Colors.grey,
        icon: Icons.edit_note,
      );
    case 'CONFIRMADO':
      return _StatusConfig(
        label: 'Confirmado',
        color: Colors.orange,
        icon: Icons.check_circle,
      );
    case 'SINCRONIZADO':
      return _StatusConfig(
        label: 'Sincronizado',
        color: Colors.blue,
        icon: Icons.cloud_done,
      );
    case 'ENTREGADO':
      return _StatusConfig(
        label: 'Entregado',
        color: Colors.green,
        icon: Icons.check_circle,
      );
    default:
      return _StatusConfig(
        label: estado,
        color: Colors.grey,
        icon: Icons.help,
      );
  }
}
