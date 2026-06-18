import 'package:flutter/material.dart';
import '../models/client.dart';

class ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onTap;
  final bool isSelected;

  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isSelected ? Colors.green.shade100 : Colors.grey.shade200,
          child: Text(
            client.nombre.isNotEmpty
                ? client.nombre[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.green : Colors.grey,
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
              Text(client.ciudad!,
                  style: const TextStyle(fontSize: 12)),
            if (client.direccion != null)
              Text(
                client.direccion!,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: Colors.green.withOpacity(0.05),
      ),
    );
  }
}
