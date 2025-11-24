import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../domain/entities/clean_room_config.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/sensor_overview.dart';
import '../controllers/clean_room_controller.dart';
import '../widgets/sensor_history_card.dart';
import '../widgets/sensor_overview_card.dart';

class CleanRoomMonitorPage extends StatefulWidget {
  const CleanRoomMonitorPage({super.key});

  @override
  State<CleanRoomMonitorPage> createState() => _CleanRoomMonitorPageState();
}

class _CleanRoomMonitorPageState extends State<CleanRoomMonitorPage> {
  late final CleanRoomController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CleanRoomController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<CleanRoomController>()) {
      Get.delete<CleanRoomController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('CLEAN ROOM SENSOR MONITOR'),
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.isRefreshing.value
                  ? null
                  : () => controller.refreshData(),
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value != null) {
            return _ErrorState(
              message: controller.error.value!,
              onRetry: controller.refreshData,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: LayoutBuilder(builder: (context, constraints) {
              const sideWidth = 360.0;
              final bool wide = constraints.maxWidth > 1200;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilters(theme),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: wide ? sideWidth : constraints.maxWidth,
                          child: _buildLeftPanel(theme),
                        ),
                        if (wide) const SizedBox(width: 16),
                        if (wide)
                          Expanded(
                            child: _buildMapPanel(theme),
                          ),
                      ],
                    ),
                  ),
                  if (!wide) ...[
                    const SizedBox(height: 16),
                    _buildMapPanel(theme),
                  ],
                ],
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    InputDecoration decoration(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
        );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 220,
          child: Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedCustomer.value.isEmpty
                    ? null
                    : controller.selectedCustomer.value,
                decoration: decoration('Customer'),
                dropdownColor: Colors.black,
                items: controller.customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => v != null
                    ? controller.onCustomerChanged(v)
                    : null,
              )),
        ),
        SizedBox(
          width: 200,
          child: Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedFactory.value.isEmpty
                    ? null
                    : controller.selectedFactory.value,
                decoration: decoration('Factory'),
                dropdownColor: Colors.black,
                items: controller.factories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => v != null ? controller.onFactoryChanged(v) : null,
              )),
        ),
        SizedBox(
          width: 200,
          child: Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedFloor.value.isEmpty
                    ? null
                    : controller.selectedFloor.value,
                decoration: decoration('Floor'),
                dropdownColor: Colors.black,
                items: controller.floors
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => v != null ? controller.onFloorChanged(v) : null,
              )),
        ),
        SizedBox(
          width: 200,
          child: Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedRoom.value.isEmpty
                    ? null
                    : controller.selectedRoom.value,
                decoration: decoration('Room'),
                dropdownColor: Colors.black,
                items: controller.rooms
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => v != null ? controller.onRoomChanged(v) : null,
              )),
        ),
      ],
    );
  }

  Widget _buildLeftPanel(ThemeData theme) {
    final SensorOverview? overview = controller.sensorOverview.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: const Color(0xFF0E1621),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _metricTile('TOTAL', overview?.totalSensors ?? 0, Colors.blueAccent, Icons.layers)),
                    const SizedBox(width: 8),
                    Expanded(child: _metricTile('ONLINE', overview?.onlineSensors ?? 0, Colors.greenAccent, Icons.online_prediction)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _metricTile('WARNING', overview?.warningSensors ?? 0, Colors.orangeAccent, Icons.warning_amber_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _metricTile('OFFLINE', overview?.offlineSensors ?? 0, Colors.grey, Icons.wifi_off)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('Details'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            color: const Color(0xFF0E1621),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Obx(() {
                final items = controller.sensorHistories;
                if (items.isEmpty) {
                  return const Center(child: Text('No history', style: TextStyle(color: Colors.white70)));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = items[index];
                    final status = controller.statusFor(data);
                    return SensorHistoryCard(data: data, status: status);
                  },
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPanel(ThemeData theme) {
    return Card(
      color: const Color(0xFF0E1621),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Obx(() {
                final CleanRoomConfig? config = controller.configMapping.value;
                final imageUrl = config?.image;
                final brightness = config?.imageBrightness ?? 1.0;
                if (imageUrl == null || imageUrl.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(1 - brightness.clamp(0.0, 1.0)),
                      BlendMode.darken,
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Obx(() {
              final positions = controller.parsePositions();
              final overviewData = controller.sensorOverviewData;
              if (positions.isEmpty || overviewData.isEmpty) {
                return const Center(
                  child: Text(
                    'Loading sensors...',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              return LayoutBuilder(builder: (context, constraints) {
                return Stack(
                  children: positions.map((pos) {
                    final sensor = overviewData
                        .firstWhereOrNull((element) => element.sensorName == pos.sensorName);
                    if (sensor == null) return const SizedBox.shrink();
                    final status = controller.statusFor(sensor);
                    return Positioned(
                      top: constraints.maxHeight * (pos.top / 100),
                      left: constraints.maxWidth * (pos.left / 100),
                      child: SensorOverviewCard(
                        data: sensor,
                        status: status,
                        size: pos.size,
                        speechType: pos.speechType,
                      ),
                    );
                  }).toList(),
                );
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
