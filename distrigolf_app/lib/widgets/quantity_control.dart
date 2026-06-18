import 'package:flutter/material.dart';

class QuantityControl extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
        SizedBox(
          width: 44,
          child: TextField(
            controller: TextEditingController(text: '$quantity'),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.zero,
              isDense: true,
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n > 0) onChanged(n);
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => onChanged(quantity + 1),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
