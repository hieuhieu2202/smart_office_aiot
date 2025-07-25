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

  static const double stationWidth = 120;
  static const double cellWidth = 90;
  static const double cellHeight = 42;

  @override
  Widget build(BuildContext context) {
    final tableWidth = stationWidth + cellWidth * dates.length;

    return Align(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: tableWidth.toDouble(),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final available = constraints.maxWidth;
                    double cw = cellWidth;
                    if (dates.length * cellWidth < available) {
                      cw = available / dates.length;
                    }
                    final contentWidth = cw * dates.length;
                    final bool canCenter = contentWidth <= available;
                    return SingleChildScrollView(
                      key: PageStorageKey('${storageKey}_scroll'),
                      controller: ScrollController(keepScrollOffset: false),
                      scrollDirection: Axis.horizontal,
                      physics: canCenter ? const NeverScrollableScrollPhysics() : null,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Align(
                          alignment: canCenter ? Alignment.center : Alignment.centerLeft,
                          child: SizedBox(
                            width: contentWidth.toDouble(),
                            child: Column(
                              children: stations.map<Widget>((st) {
                                final values = (st['Data'] as List? ?? [])
                                    .map((e) => e.toString())
                                    .toList();
                                return Row(
                                  children: values
                                      .map((v) => _cell(v, width: cw))
                                      .toList(),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildCell(
    String text,
    bool isDark, {
    bool header = false,
    bool alignLeft = false,
    double? width,
  }) {
    return Container(
      width: width ?? (alignLeft ? stationWidth : cellWidth),
      height: cellHeight,
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      padding: alignLeft ? const EdgeInsets.only(left: 8) : null,
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey),
        color: header
            ? (isDark ? Colors.teal[900] : Colors.blue[100])
            : Colors.transparent,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
      ),
    );
  }

  Widget _cell(
    String text, {
    bool header = false,
    bool alignLeft = false,
    double? width,
  }) =>
      buildCell(text, isDark,
          header: header, alignLeft: alignLeft, width: width);
}
