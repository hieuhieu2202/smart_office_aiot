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
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.55),
            const Color(0xFF02132F).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: 1.1,
                ),
          ),
          const Spacer(),
          Text(
            data.subtitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
          ),
        ],
      ),
    );
  }
}
