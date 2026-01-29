import 'package:flutter/material.dart';
import '../../domain/entities/rack_entities.dart';

/// Rack Panel Card - Displays individual rack with slots
class RackPanelCard extends StatelessWidget {
  final RackDetail rack;
  final bool showAnimation;

  const RackPanelCard({
    super.key,
    required this.rack,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = _isOffline();
    final rackColor = _getRackStatusColor();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: const Color(0xFF22365b),
          width: 1,
        ),
      ),
      color: const Color(0xFF22365b).withValues(alpha: 0.31),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isOffline, rackColor),
          _buildBody(context, isOffline),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isOffline, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF22365b)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rack name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rack.rackName,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '[ ${rack.modelName} ]',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.circle,
                color: statusColor,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total pass counter
          Center(
            child: Text(
              '${rack.totalPass} PCS',
              style: TextStyle(
                color: isOffline ? Colors.grey : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                shadows: isOffline
                    ? null
                    : [
                        const Shadow(
                          color: Color(0xFF93bbff),
                          blurRadius: 10,
                        ),
                      ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // UT
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UT',
                  style: TextStyle(
                    color: isOffline ? Colors.grey : const Color(0xFF64B5F6),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${rack.ut.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isOffline ? Colors.grey : const Color(0xFF64B5F6),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // YR Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rack.yr / 100,
                  minHeight: 22,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getYRColor(rack.yr),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rack.modelName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Y.R | ${rack.yr.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isOffline) {
    if (rack.slotDetails.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No slots',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: rack.slotDetails.asMap().entries.map((entry) {
          final slot = entry.value;
          final isLast = entry.key == rack.slotDetails.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: _buildSlot(slot, isOffline),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlot(SlotDetail slot, bool isOffline) {
    final slotColor = _getSlotStatusColor(slot);
    final yr = slot.yr.clamp(0, 100);

    return InkWell(
      onTap: () {
        // TODO: Show slot details modal
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey.shade900,
        ),
        child: Stack(
          children: [
            // Progress bar background
            FractionallySizedBox(
              widthFactor: yr / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: slotColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Slot label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'SLOT ${slot.slotNumber}  [ ${slot.slotName} ]',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (yr > 0)
                    Text(
                      '${slot.totalPass}/${slot.totalPass + slot.fail} | ${yr.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isOffline() {
    final status = rack.status.toUpperCase();
    return status.contains('OFFLINE') ||
        status.contains('NO CONNECT') ||
        status.contains('DISCONNECT') ||
        rack.totalPass == 0;
  }

  Color _getRackStatusColor() {
    if (_isOffline()) return Colors.grey;
    if (rack.yr >= 97) return const Color(0xFF00c853); // Green
    if (rack.yr >= 90) return const Color(0xFFffc107); // Yellow
    return const Color(0xFFff3b30); // Red
  }

  Color _getYRColor(double yr) {
    if (yr >= 97) return const Color(0xFF00c853); // Green
    if (yr >= 90) return const Color(0xFFffc107); // Yellow
    if (yr >= 70) return const Color(0xFFff9800); // Orange
    return const Color(0xFFff3b30); // Red
  }

  Color _getSlotStatusColor(SlotDetail slot) {
    final status = slot.status.toUpperCase();

    if (status.contains('OFFLINE') || slot.yr == 0) {
      return const Color(0xFF9e9e9e); // Grey
    }
    if (status.contains('PASS')) {
      return const Color(0xFF00c853); // Green
    }
    if (status.contains('FAIL')) {
      return const Color(0xFFff3b30); // Red
    }
    if (status.contains('TESTING')) {
      return const Color(0xFF1e88e5); // Blue
    }
    if (status.contains('WAITING')) {
      return const Color(0xFFffc107); // Yellow
    }
    if (status.contains('HOLD')) {
      return const Color(0xFF9c27b0); // Purple
    }

    // Default based on YR
    if (slot.yr >= 97) return const Color(0xFF00c853);
    if (slot.yr >= 90) return const Color(0xFFffc107);
    return const Color(0xFFff3b30);
  }
}

