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

  @override
  Widget build(BuildContext context) {
    final columns = <DataColumn>[
      DataColumn(label: _headerCell('Station')),
      ...dates.map((d) => DataColumn(label: _headerCell(d))).toList(),
    ];

    final rows = stations.map<DataRow>((st) {
      final values = (st['Data'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      return DataRow(
        cells: [
          DataCell(Text(
            st['Station'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.cyanAccent : Colors.blueAccent,
            ),
          )),
          ...values.map(
            (v) => DataCell(Text(
              v,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.yellowAccent : Colors.blueAccent,
              ),
            )),
          ),
        ],
      );
    }).toList();

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
        SingleChildScrollView(
          key: PageStorageKey('${storageKey}_scroll'),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 42,
            dataRowMinHeight: 42,
            dataRowMaxHeight: 42,
            columns: columns,
            rows: rows,
            headingRowColor: MaterialStateProperty.all(
                isDark ? Colors.teal[900] : Colors.blue[100]),
            dataRowColor: MaterialStateProperty.all(
                isDark ? Colors.blueGrey[900] : Colors.blueGrey[50]),
            dividerThickness: 1,
            columnSpacing: 16,
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.yellowAccent : Colors.blueAccent,
      ),
    );
  }
}
