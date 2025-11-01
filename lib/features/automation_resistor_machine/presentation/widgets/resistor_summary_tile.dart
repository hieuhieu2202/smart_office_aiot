import 'package:flutter/material.dart';

import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorSummaryTile extends StatelessWidget {
  const ResistorSummaryTile({
    super.key,
    required this.data,
  });

  final ResistorSummaryTileData data;

  @override
  Widget build(BuildContext context) {
    final color = Color(data.color);
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
          ),
          const Spacer(),
          Text(
            data.subtitle,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white60,
                ),
          )
        ],
      ),
    );
  }
}
