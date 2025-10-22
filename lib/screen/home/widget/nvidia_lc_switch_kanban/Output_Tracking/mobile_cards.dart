import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cells.dart';
import 'output_tracking_view_state.dart';
import 'series_utils.dart';

class OtMobileRowCard extends StatelessWidget {
  const OtMobileRowCard({
    super.key,
    required this.row,
    required this.hours,
    this.onStationTap,
    this.onSectionTap,
  });

  final OtRowView row;
  final List<String> hours;
  final VoidCallback? onStationTap;
  final void Function(String section)? onSectionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardColor = Color(0xFF0F233F);
    const borderColor = Color(0xFF1E3F66);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
          color: Colors.white70,
        );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(.7)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.station, style: titleStyle),
            const SizedBox(height: 4),
            Text(row.model, style: subtitleStyle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statChip('WIP', row.wip, const Color(0xFF42A0FF)),
                _statChip(
                  'PASS',
                  row.totalPass,
                  const Color(0xFF38D893),
                  onTap: onStationTap,
                ),
                _statChip(
                  'FAIL',
                  row.totalFail,
                  const Color(0xFFFF6B6B),
                  onTap: onStationTap,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                for (var i = 0; i < hours.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == hours.length - 1 ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            formatHourRange(hours[i]),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TripleCell(
                            pass: row.metrics.length > i ? row.metrics[i].pass : 0,
                            yr: row.metrics.length > i ? row.metrics[i].yr : 0,
                            rr: row.metrics.length > i ? row.metrics[i].rr : 0,
                            compact: false,
                            onTapYr: onSectionTap != null &&
                                    row.metrics.length > i &&
                                    row.metrics[i].yr > 0
                                ? () => onSectionTap!(hours[i])
                                : null,
                            onTapRr: onSectionTap != null &&
                                    row.metrics.length > i &&
                                    row.metrics[i].pass > 0 &&
                                    row.metrics[i].rr > 0
                                ? () => onSectionTap!(hours[i])
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int value, Color color, {VoidCallback? onTap}) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.55)),
        color: color.withOpacity(.18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: .25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return chip;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}
