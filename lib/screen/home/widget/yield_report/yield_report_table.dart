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

  static const double stationWidth = 110;
  static const double cellWidth = 85;
  static const double cellHeight = 42;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: stationWidth + cellWidth * dates.length,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.blueGrey[800] : Colors.blueGrey[100],
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey),
          ),
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
              children: stations
                  .map<Widget>((st) => _cell(st['Station'] ?? '', alignLeft: true))
                  .toList(),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: PageStorageKey('${storageKey}_scroll'),
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: stations.map<Widget>((st) {
                    final values = (st['Data'] as List? ?? [])
                        .map((e) => e.toString())
                        .toList();
                    return Row(
                      children: values.map((v) => _cell(v)).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildCell(
    String text,
    bool isDark, {
    bool header = false,
    bool alignLeft = false,
  }) {
    return Container(
      width: alignLeft ? stationWidth : cellWidth,
      height: cellHeight,
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

  Widget _cell(
    String text, {
    bool header = false,
    bool alignLeft = false,
  }) =>
      buildCell(text, isDark, header: header, alignLeft: alignLeft);
}
