import 'package:flutter/material.dart';

class LcrChartCard extends StatelessWidget {
  const LcrChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height,
  });

  final String title;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF041C3B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66031A35),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 12),
          if (height != null)
            Expanded(child: child)
          else
            child,
        ],
      ),
    );
  }
}
