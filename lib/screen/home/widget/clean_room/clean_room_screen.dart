import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/area_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/bar_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_data_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_history_chart_widget.dart';

class CleanRoomScreen extends StatelessWidget {
  CleanRoomScreen({super.key});

  final CleanRoomController controller = Get.put(CleanRoomController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B1F44),
            const Color(0xFF0D2E64),
            const Color(0xFF0E3B7D),
            const Color(0xFF0B1F44).withOpacity(.85),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 12),
                _buildFilters(context, theme),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 340,
                        child: _buildSidebar(context, theme),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildOverviewBoard(context, theme, isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(.7),
            Colors.blue.shade600.withOpacity(.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blueAccent.withOpacity(.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.air_rounded, size: 36, color: Colors.cyanAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLEAN ROOM SENSOR MONITOR',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Giám sát cảm biến phòng sạch theo thời gian thực',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _openDetails(theme, controller),
            icon: const Icon(Icons.bar_chart_rounded),
            label: const Text('Details'),
          )
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ThemeData theme) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900.withOpacity(.7),
              Colors.indigo.shade700.withOpacity(.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.blueAccent.withOpacity(.3)),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildDropdown(
              label: 'Customer',
              value: controller.selectedCustomer.value.isEmpty
                  ? null
                  : controller.selectedCustomer.value,
              items: controller.customers,
              onChanged: (value) {
                if (value != null) {
                  controller.selectedCustomer.value = value;
                  controller.fetchFactories();
                }
              },
            ),
            _buildDropdown(
              label: 'Factory',
              value: controller.selectedFactory.value.isEmpty
                  ? null
                  : controller.selectedFactory.value,
              items: controller.factories,
              onChanged: (value) {
                if (value != null) {
                  controller.selectedFactory.value = value;
                  controller.fetchFloors();
                }
              },
            ),
            _buildDropdown(
              label: 'Floor',
              value: controller.selectedFloor.value.isEmpty
                  ? null
                  : controller.selectedFloor.value,
              items: controller.floors,
              onChanged: (value) {
                if (value != null) {
                  controller.selectedFloor.value = value;
                  controller.fetchRooms();
                }
              },
            ),
            _buildDropdown(
              label: 'Room',
              value: controller.selectedRoom.value.isEmpty
                  ? null
                  : controller.selectedRoom.value,
              items: controller.rooms,
              onChanged: (value) {
                if (value != null) {
                  controller.selectedRoom.value = value;
                  controller.fetchData();
                }
              },
            ),
            _buildDateRangePicker(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(color: Colors.white),
                  ),
                ))
            .toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.cyanAccent),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        onChanged: items.isEmpty ? null : onChanged,
        iconEnabledColor: Colors.cyanAccent,
        dropdownColor: Colors.blueGrey.shade900,
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return Obx(
      () {
        final formatter = DateFormat('dd/MM HH:mm');
        final text =
            '${formatter.format(controller.selectedStartDate.value)} - ${formatter.format(controller.selectedEndDate.value)}';
        return ElevatedButton.icon(
          icon: const Icon(Icons.calendar_month),
          label: Text(text),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: now.subtract(const Duration(days: 30)),
              lastDate: now,
              initialDateRange: DateTimeRange(
                start: controller.selectedStartDate.value,
                end: controller.selectedEndDate.value,
              ),
            );
            if (picked != null) {
              controller.applyFilter(
                picked.start,
                picked.end,
                controller.selectedCustomer.value,
                controller.selectedFactory.value,
                controller.selectedFloor.value,
                controller.selectedRoom.value,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, ThemeData theme) {
    return Obx(
      () {
        final overview = controller.sensorOverview;
        final total = _readInt(overview, 'totalSensors');
        final online = _readInt(overview, 'onlineSensors');
        final warning = _readInt(overview, 'warningSensors');
        final offline = _readInt(overview, 'offlineSensors');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(theme, total, online, warning, offline),
            const SizedBox(height: 12),
            Expanded(child: _buildHistoryList(theme)),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
      ThemeData theme, int total, int online, int warning, int offline) {
    final chips = [
      _SummaryItem('TOTAL', total, Icons.layers, Colors.blueAccent),
      _SummaryItem('ONLINE', online, Icons.wifi, Colors.greenAccent),
      _SummaryItem('WARNING', warning, Icons.warning_amber, Colors.orangeAccent),
      _SummaryItem('OFFLINE', offline, Icons.portable_wifi_off, Colors.grey),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800.withOpacity(.7),
            Colors.blue.shade600.withOpacity(.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.lightBlueAccent.withOpacity(.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Tổng quan cảm biến',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chips.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final item = chips[index];
              return _StatusCard(item: item);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _openDetails(theme, controller),
              child: const Text(
                'DETAILS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryList(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.blueGrey.withOpacity(.4),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Lịch sử cảm biến',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(
              () {
                final histories = controller.sensorHistories;
                if (histories.isEmpty) {
                  return const Center(
                      child: Text(
                    'Không có lịch sử',
                    style: TextStyle(color: Colors.white70),
                  ));
                }
                return ListView.separated(
                  itemCount: histories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = histories[index];
                    return _HistoryTile(sensor: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBoard(
      BuildContext context, ThemeData theme, bool isDark) {
    return Obx(
      () {
        final config = controller.configData;
        final sensors = controller.sensorData;
        final positions = (config['data'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            [];

        final gradientStart =
            isDark ? Colors.blueGrey.shade900 : Colors.blue.shade700;
        final gradientEnd = isDark ? Colors.indigo.shade800 : Colors.blue.shade500;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                gradientStart.withOpacity(.8),
                gradientEnd.withOpacity(.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(.2),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: controller.roomImage.value != null
                          ? Image(
                              image: controller.roomImage.value!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [Color(0xFF0E2A55), Color(0xFF061833)],
                                  radius: 1.0,
                                  center: Alignment(.1, -.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Không có sơ đồ phòng',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ),
                            ),
                    ),
                    if (positions.isNotEmpty)
                      ...positions
                          .where((p) =>
                              (p['sensorName'] ?? '').toString().isNotEmpty)
                          .map((pos) {
                        final sensorName = pos['sensorName'].toString();
                        final sensor = sensors.firstWhereOrNull(
                            (element) => element['sensorName'] == sensorName);
                        if (sensor == null) return const SizedBox.shrink();

                        final topPercent = (pos['top'] ?? 0).toDouble();
                        final leftPercent = (pos['left'] ?? 0).toDouble();
                        final top =
                            constraints.maxHeight * (topPercent.clamp(0, 100) / 100);
                        final left = constraints.maxWidth *
                            (leftPercent.clamp(0, 100) / 100);

                        return Positioned(
                          top: top,
                          left: left,
                          child: _buildSensorBubble(pos, sensor),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorBubble(Map<String, dynamic> pos, Map<String, dynamic> sensor) {
    final dataList = (sensor['data'] as List?) ?? [];
    final hasOffline = dataList.any((e) => e['result'] == 'OFFLINE');
    final hasWarning = dataList.any((e) => e['result'] == 'WARNING');
    final status = hasOffline
        ? 'OFFLINE'
        : hasWarning
            ? 'WARNING'
            : 'ONLINE';

    final color = switch (status) {
      'OFFLINE' => Colors.grey,
      'WARNING' => Colors.orangeAccent,
      _ => Colors.greenAccent,
    };

    final size = max((pos['size'] ?? 26).toDouble(), 18.0);
    final lastTime = dataList
        .map((e) => e['timestamp'])
        .whereType<String>()
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (prev, cur) => prev == null || cur.isAfter(prev) ? cur : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(.55), Colors.blueGrey.withOpacity(.45)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withOpacity(.6)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sensors, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensor['sensorName'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((sensor['sensorDesc'] ?? '').toString().isNotEmpty)
                          Text(
                            sensor['sensorDesc'],
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: dataList.take(4).map((item) {
                  final double value = (item['value'] ?? 0).toDouble();
                  final precision = item['precision'] ?? 0;
                  final display = item['paramDisplayName'] ?? item['paramName'];
                  final paramColor = _paramColor(item['paramName']);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        display.toString(),
                        style: TextStyle(color: paramColor ?? Colors.white70, fontSize: 12),
                      ),
                      Text(
                        value.toStringAsFixed(precision),
                        style: TextStyle(
                          color: paramColor ?? color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.white60),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lastTime != null
                          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(lastTime)
                          : '—',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(.65), color.withOpacity(.15)],
            ),
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.35),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
        ),
      ],
    );
  }

  Color? _paramColor(dynamic name) {
    switch (name) {
      case '0.3um':
        return const Color(0xFF058DC7);
      case '0.5um':
        return const Color(0xFF50B432);
      case '1.0um':
        return const Color(0xFFED561B);
      case '5.0um':
        return const Color(0xFFDDDF00);
      default:
        return Colors.cyanAccent;
    }
  }

  void _openDetails(ThemeData theme, CleanRoomController controller) {
    Get.bottomSheet(
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      SizedBox(
        height: Get.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chi tiết cảm biến ${controller.selectedFactory.value}-${controller.selectedFloor.value}-${controller.selectedRoom.value}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close),
                    )
                  ],
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Tổng quan'),
                    Tab(text: 'Biểu đồ'),
                    Tab(text: 'Dữ liệu'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      SensorHistoryChartWidget(),
                      Column(
                        children: [
                          Expanded(child: AreaChartWidget()),
                          const SizedBox(height: 12),
                          Expanded(child: BarChartWidget()),
                        ],
                      ),
                      SensorDataChartWidget(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _readInt(Map map, String key) {
    final lower = key[0].toLowerCase() + key.substring(1);
    return (map[key] ?? map[lower] ?? 0) as int;
  }
}

class _SummaryItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  _SummaryItem(this.title, this.value, this.icon, this.color);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [item.color.withOpacity(.25), Colors.white.withOpacity(.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: item.color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 28),
          const Spacer(),
          Text(
            item.title,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          Text(
            item.value.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.sensor});

  final Map<String, dynamic> sensor;

  @override
  Widget build(BuildContext context) {
    final data = (sensor['data'] as List?) ?? [];
    final hasOffline = data.any((e) => e['result'] == 'OFFLINE');
    final hasWarning = data.any((e) => e['result'] == 'WARNING');
    final status = hasOffline
        ? 'OFFLINE'
        : hasWarning
            ? 'WARNING'
            : 'ONLINE';
    final color = switch (status) {
      'OFFLINE' => Colors.grey,
      'WARNING' => Colors.orangeAccent,
      _ => Colors.green,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(.14),
            Colors.white.withOpacity(.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sensor['sensorName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: data.take(3).map((d) {
              final value = (d['value'] ?? 0).toDouble();
              final precision = d['precision'] ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    d['paramDisplayName'] ?? d['paramName'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    value.toStringAsFixed(precision),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
