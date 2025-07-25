import 'package:flutter/material.dart';

class YieldReportTable extends StatelessWidget {
  final String storageKey;
  final String modelName;
  final List<String> dates;
  final List stations;
  final bool isDark;

  const YieldReportTable({
    super.key,
    required this.storageKey,
    required this.modelName,
    required this.dates,
    required this.stations,
    required this.isDark,
  });

  static const double _stationWidth = 110;
  static const double _cellWidth = 85;
  static const double _cellHeight = 42;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            modelName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.cyanAccent : Colors.blueAccent,
              fontSize: 15,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCell('Station', header: true, alignLeft: true),
                ...stations.map<Widget>(
                  (st) => _buildCell(
                    st['Station'] ?? '',
                    alignLeft: true,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                key: PageStorageKey('${storageKey}_scroll'),
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    Row(
                      children: dates
                          .map((d) => _buildCell(d, header: true))
                          .toList(),
                    ),
                    ...stations.map<Widget>((st) {
                      final values = (st['Data'] as List? ?? [])
                          .map((e) => e.toString())
                          .toList();
                      return Row(
                        children:
                            values.map((v) => _buildCell(v)).toList(),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell(
    String text, {
    bool header = false,
    bool alignLeft = false,
  }) {
    return Container(
      width: alignLeft ? _stationWidth : _cellWidth,
      height: _cellHeight,
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      padding: alignLeft ? const EdgeInsets.only(left: 8) : null,
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey),
        color: header
            ? (isDark ? Colors.teal[900] : Colors.blue[100])
            : Colors.transparent,
      ),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontWeight:
              header || alignLeft ? FontWeight.bold : FontWeight.w500,
          color: isDark ? Colors.yellowAccent : Colors.blueAccent,
          fontSize: 13,
        ),
      ),
    );
  }
}
