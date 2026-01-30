import 'package:flutter/material.dart';

import '../../domain/entities/resistor_machine_entities.dart';

class ResistorStatusTable extends StatelessWidget {
  const ResistorStatusTable({
    super.key,
    required this.records,
    required this.onTap,
    this.isLoading = false,
  });

  final List<ResistorMachineStatus> records;
  final ValueChanged<ResistorMachineStatus> onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (records.isEmpty) {
      return const Center(
        child: Text(
          'No status data',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        if (isMobile) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final item = records[index];
              return _StatusCard(item: item, onTap: onTap);
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: records.length,
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              Colors.white.withOpacity(0.08),
            ),
            dataRowColor: MaterialStateProperty.all(
              Colors.white.withOpacity(0.02),
            ),
            columns: const [
              DataColumn(
                label: Text('ID', style: TextStyle(color: Colors.white70)),
              ),
              DataColumn(
                label:
                    Text('SERIAL NUMBER', style: TextStyle(color: Colors.white70)),
              ),
              DataColumn(
                label:
                    Text('MACHINE', style: TextStyle(color: Colors.white70)),
              ),
              DataColumn(
                label:
                    Text('STATION', style: TextStyle(color: Colors.white70)),
              ),
              DataColumn(
                label:
                    Text('IN STATION TIME', style: TextStyle(color: Colors.white70)),
              ),
            ],
            rows: records
                .map(
                  (item) => DataRow(
                    cells: [
                      DataCell(
                        Text('${item.id}',
                            style: const TextStyle(color: Colors.white)),
                      ),
                      DataCell(
                        Text(item.serialNumber,
                            style: const TextStyle(color: Colors.cyanAccent)),
                        onTap: () => onTap(item),
                      ),
                      DataCell(
                        Text(item.machineName,
                            style: const TextStyle(color: Colors.white70)),
                      ),
                      DataCell(
                        Text('${item.stationSequence}',
                            style: const TextStyle(color: Colors.white70)),
                      ),
                      DataCell(
                        Text(
                          item.inStationTime.toLocal().toString(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.item, required this.onTap});

  final ResistorMachineStatus item;
  final ValueChanged<ResistorMachineStatus> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(item),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF021024).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Serial: ${item.serialNumber}',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            Text('Machine: ${item.machineName}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Station: ${item.stationSequence}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              'In station: ${item.inStationTime.toLocal()}',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
