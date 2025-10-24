import 'dart:math' as math;

import 'package:flutter/material.dart';

class TrayDetailDialog extends StatelessWidget {
  final String trayName;
  final List<Map<String, dynamic>> entries;

  const TrayDetailDialog({
    super.key,
    required this.trayName,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? Colors.cyanAccent : const Color(0xFF0EA5C6);
    final background =
        isDark ? const Color(0xFF031521).withOpacity(0.96) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF08263A);

    final maxWidth = math.min(size.width * 0.9, 720.0);
    final maxHeight = math.min(size.height * 0.85, 600.0);
    final availableHeight = math.max(maxHeight - 160, 160.0);
    final listHeight = entries.isEmpty
        ? availableHeight
        : math.min(availableHeight, 56.0 * entries.length + 48.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: maxWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? accent.withOpacity(0.18)
                  : Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${trayName.toUpperCase()} SERIAL NUMBER LIST',
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).maybePop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TrayHeaderRow(isDark: isDark),
            const SizedBox(height: 8),
            SizedBox(
              height: listHeight,
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'No serial numbers available for this rack.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = entries[index];
                          return _TrayDataRow(
                            index: index + 1,
                            serial:
                                (item['SerialNumber'] ?? '').toString().trim(),
                            model: (item['ModelName'] ?? '').toString().trim(),
                            wipGroup:
                                (item['WipGroup'] ?? '').toString().trim(),
                            time: (item['DisplayTime'] ??
                                    item['InStationTime'] ??
                                    '')
                                .toString()
                                .replaceFirst('T', ' '),
                            isDark: isDark,
                            highlight: index.isEven,
                            textColor: textColor,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrayHeaderRow extends StatelessWidget {
  final bool isDark;

  const _TrayHeaderRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.cyanAccent : const Color(0xFF0B3A4F),
      fontSize: 13,
      letterSpacing: 0.3,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE6F5FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              'No.',
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Serial Number',
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Model Name',
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'WIP Group',
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Curing Time',
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrayDataRow extends StatelessWidget {
  final int index;
  final String serial;
  final String model;
  final String wipGroup;
  final String time;
  final bool isDark;
  final bool highlight;
  final Color textColor;

  const _TrayDataRow({
    required this.index,
    required this.serial,
    required this.model,
    required this.wipGroup,
    required this.time,
    required this.isDark,
    required this.highlight,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlight
        ? (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF5FBFF))
        : Colors.transparent;
    final subtitle = isDark ? Colors.white70 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? (isDark
                  ? Colors.cyanAccent.withOpacity(0.08)
                  : Colors.black12)
              : Colors.transparent,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              serial.isEmpty ? '-' : serial,
              style: TextStyle(color: textColor, fontSize: 13.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              model.isEmpty ? '-' : model,
              style: TextStyle(color: subtitle, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                wipGroup.isEmpty ? '-' : wipGroup,
                style: TextStyle(color: subtitle, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                time.isEmpty ? '-' : time,
                style: TextStyle(color: subtitle, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
