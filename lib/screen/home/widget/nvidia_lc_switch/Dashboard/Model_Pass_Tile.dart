import 'package:flutter/material.dart';

class ModelPassTile extends StatelessWidget {
  final String modelName;
  final int qty;
  final int colorIndex;

  const ModelPassTile({
    super.key,
    required this.modelName,
    required this.qty,
    this.colorIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? Colors.white : const Color(0xFF103248);

    final chipColors = [
      isDark ? const Color(0xFF57B7FF) : const Color(0xFF3DA5FF),
      isDark ? const Color(0xFF6E62C7) : const Color(0xFF7A6AE0),
    ];
    final chip = chipColors[colorIndex % chipColors.length];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            modelName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: nameColor, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: chip,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: chip.withOpacity(.25), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Text(
            '$qty',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
