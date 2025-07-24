import 'package:flutter/material.dart';
import '../../controller/yield_report_controller.dart';
import '../../../../config/global_color.dart';

class YieldReportTable extends StatelessWidget {
  final YieldReportController controller;
  final bool isDark;
  final ScrollController scrollController;

  const YieldReportTable({
    super.key,
    required this.controller,
    required this.isDark,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
      itemCount: controller.filteredNickNames.length,
      itemBuilder: (context, idx) {
        final nick = controller.filteredNickNames[idx];
        final models = nick['DataModelNames'] as List? ?? [];
        final nickName = nick['NickName'];
        final storageKey = nickName ?? 'nick_$idx';
        return Card(
          margin: const EdgeInsets.only(bottom: 18),
          color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
          elevation: 6,
          shadowColor: isDark ? Colors.black45 : Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ExpansionTile(
            key: PageStorageKey(nickName),
            initiallyExpanded: controller.expandedNickNames.contains(nickName),
            onExpansionChanged: (expanded) {
              if (expanded) {
                controller.expandedNickNames.add(nickName);
              } else {
                controller.expandedNickNames.remove(nickName);
              }
            },
            tilePadding: const EdgeInsets.symmetric(horizontal: 18),
            childrenPadding: const EdgeInsets.only(bottom: 16),
            maintainState: true,
            title: Text(
              nickName ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.lightBlue[100] : Colors.blue[900],
                fontSize: 17,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: _buildNickTable(
                  storageKey,
                  models,
                  controller.dates,
                  isDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNickTable(
    String storageKey,
    List models,
    List dates,

    bool isDark,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (final m in models) {
      final modelName = m['ModelName']?.toString() ?? '';
      final stations = m['DataStations'] as List? ?? [];
      for (final st in stations) {
        rows.add({
          'model': modelName,
          'station': st['Station']?.toString() ?? '',
          'data': (st['Data'] as List? ?? []).map((e) => e.toString()).toList(),
        });
      }
    }

    final shortDates = dates.map((d) => d.toString().split(' ').first).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 3, right: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey[900] : Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.grey.withOpacity(0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderCell(
                  'Model',
                  120,
                  isDark,
                  align: Alignment.centerLeft,
                ),
                ...rows.map(
                  (r) => Container(
                    width: 120,
                    height: 42,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      r['model'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderCell(
                  'Station',
                  110,
                  isDark,
                  align: Alignment.center,
                ),
                ...rows.map(
                  (r) => Container(
                    width: 110,
                    height: 42,
                    alignment: Alignment.center,
                    child: Text(
                      r['station'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                key: PageStorageKey('${storageKey}_scroll'),
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children:
                          shortDates
                              .map((d) => _buildHeaderCell(d, 85, isDark))
                              .toList(),
                    ),
                    ...rows.map((r) {
                      final values = List<String>.from(r['data'] as List);
                      return Row(
                        children:
                            values
                                .map(
                                  (v) => Container(
                                    width: 85,
                                    height: 42,
                                    alignment: Alignment.center,
                                    child: Text(
                                      v,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDark
                                                ? Colors.yellowAccent
                                                : Colors.blueAccent,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    double width,
    bool isDark, {
    Alignment align = Alignment.center,
  }) {
    return Container(
      width: width,
      height: 42,
      alignment: align,
      color: isDark ? Colors.teal[900] : Colors.blue[100],
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.yellowAccent : Colors.blueAccent,
        ),
      ),
    );
  }
}
