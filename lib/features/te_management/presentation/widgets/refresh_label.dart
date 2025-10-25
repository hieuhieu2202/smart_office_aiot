import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TERefreshLabel extends StatelessWidget {
  const TERefreshLabel({
    super.key,
    required this.lastUpdated,
    required this.isRefreshing,
  });

  final DateTime lastUpdated;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('HH:mm:ss').format(lastUpdated);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10213A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F3A5F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, color: Color(0xFF9AB3CF), size: 16),
          const SizedBox(width: 6),
          Text(
            'Updated $timeText',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isRefreshing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF22D3EE)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
