import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../config/global_color.dart';
import '../../../../../model/smt/stencil_detail.dart';
import '../../controller/stencil_monitor_controller.dart';
import '../../../../../widget/animation/loading/eva_loading_view.dart';

class StencilMonitorScreen extends StatefulWidget {
  const StencilMonitorScreen({
    super.key,
    this.title,
    this.controllerTag,
  });

  final String? title;
  final String? controllerTag;

  @override
  State<StencilMonitorScreen> createState() => _StencilMonitorScreenState();
}

class _StencilMonitorScreenState extends State<StencilMonitorScreen> {
  late final String _controllerTag;
  late final StencilMonitorController controller;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ?? 'stencil_monitor_default';
    controller = Get.put(StencilMonitorController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    if (Get.isRegistered<StencilMonitorController>(tag: _controllerTag)) {
      Get.delete<StencilMonitorController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final loading = controller.isLoading.value;
      final hasData = controller.stencilData.isNotEmpty;
      final filtered = controller.filteredData;
      final error = controller.error.value;

      return Scaffold(
        backgroundColor:
            isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
        appBar: AppBar(
          title: Text(widget.title ?? 'Stencil Monitor'),
          centerTitle: true,
          backgroundColor:
              isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
          iconTheme: IconThemeData(
            color: isDark
                ? GlobalColors.appBarDarkText
                : GlobalColors.appBarLightText,
          ),
          actions: [
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.fetchData(force: true),
            ),
          ],
        ),
        body: _buildBody(
          context,
          isDark: isDark,
          loading: loading,
          hasData: hasData,
          error: error,
          filtered: filtered,
        ),
      );
    });
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isDark,
    required bool loading,
    required bool hasData,
    required String error,
    required List<StencilDetail> filtered,
  }) {
    if (loading && !hasData) {
      return const Center(child: EvaLoadingView(size: 120));
    }

    if (error.isNotEmpty && !hasData) {
      return _buildFullError(isDark, error);
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchData(force: true),
      color: Theme.of(context).colorScheme.secondary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildFilterCard(isDark),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(isDark, error),
          ],
          const SizedBox(height: 16),
          _buildSummarySection(filtered, isDark),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _buildEmptyState(isDark)
          else
            ...filtered
                .map((item) => _buildStencilCard(item, isDark))
                .toList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFilterCard(bool isDark) {
    final customers = controller.customers.toList(growable: false);
    final floors = controller.floors.toList(growable: false);
    final customerValue = controller.selectedCustomer.value;
    final floorValue = controller.selectedFloor.value;

    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.lightBlue[100]
                        : GlobalColors.appBarLightText,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildDropdown(
                  label: 'Customer',
                  value: customerValue,
                  items: customers,
                  onChanged: controller.selectCustomer,
                  isDark: isDark,
                ),
                _buildDropdown(
                  label: 'Floor',
                  value: floorValue,
                  items: floors,
                  onChanged: controller.selectFloor,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.blueGrey[200] : Colors.blueGrey[700],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : null,
            isExpanded: true,
            icon: Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white70 : Colors.blueGrey[700],
            ),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(List<StencilDetail> data, bool isDark) {
    if (data.isEmpty) {
      return Card(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No stencil data for the selected filters.'),
        ),
      );
    }

    final status = controller.statusBreakdown(data).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final vendors = controller.vendorBreakdown(data).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final active = data.where((e) => e.isActive).length;

    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.lightBlue[100]
                        : GlobalColors.appBarLightText,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatChip(
                  label: 'Total',
                  value: data.length.toString(),
                  icon: Icons.inventory_2_rounded,
                  color: Colors.cyanAccent,
                  isDark: isDark,
                ),
                _buildStatChip(
                  label: 'Active Lines',
                  value: active.toString(),
                  icon: Icons.precision_manufacturing,
                  color: Colors.greenAccent,
                  isDark: isDark,
                ),
                if (status.isNotEmpty)
                  _buildStatChip(
                    label: 'Top Status',
                    value: '${status.first.key} (${status.first.value})',
                    icon: Icons.stacked_bar_chart,
                    color: Colors.orangeAccent,
                    isDark: isDark,
                  ),
                if (vendors.isNotEmpty)
                  _buildStatChip(
                    label: 'Top Vendor',
                    value: '${vendors.first.key} (${vendors.first.value})',
                    icon: Icons.local_shipping,
                    color: Colors.purpleAccent,
                    isDark: isDark,
                  ),
              ],
            ),
            if (status.length > 1) ...[
              const SizedBox(height: 16),
              Text(
                'Status Breakdown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: status
                    .map(
                      (entry) => _smallPill(
                        '${entry.key}: ${entry.value}',
                        isDark,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final baseColor = isDark ? color.withOpacity(0.2) : color.withOpacity(0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.blueGrey[700],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.blueGrey[900],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey[700] : Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white70 : Colors.blueGrey[800],
        ),
      ),
    );
  }

  Widget _buildStencilCard(StencilDetail item, bool isDark) {
    final statusColor = _statusColor(item.statusLabel, isDark);
    final runningHours = item.runningHours;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.stencilSn.isEmpty ? 'Unknown SN' : item.stencilSn,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : GlobalColors.appBarLightText,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${item.location ?? '-'}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.blueGrey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.6)),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _infoTile('Customer', item.customerLabel, isDark),
                _infoTile('Floor', item.floorLabel, isDark),
                _infoTile('Vendor', item.vendorName.isEmpty ? '-' : item.vendorName,
                    isDark),
                _infoTile('Process', item.process ?? '-', isDark),
                _infoTile('Line', item.lineName ?? '-', isDark),
                if (item.totalUseTimes != null)
                  _infoTile('Total Use', item.totalUseTimes.toString(), isDark),
                if (item.standardTimes != null)
                  _infoTile('Standard', item.standardTimes.toString(), isDark),
                if (item.alertTimes != null)
                  _infoTile('Alert', item.alertTimes.toString(), isDark),
                if (item.limitWashTime != null)
                  _infoTile(
                    'Limit Wash',
                    '${item.limitWashTime} min',
                    isDark,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _infoTile(
                  'Check Time',
                  item.checkTime != null
                      ? _dateFormat.format(item.checkTime!.toLocal())
                      : '-',
                  isDark,
                ),
                _infoTile(
                  'Start Time',
                  item.startTime != null
                      ? _dateFormat.format(item.startTime!.toLocal())
                      : '-',
                  isDark,
                ),
                if (runningHours != null)
                  _infoTile(
                    'Running (hrs)',
                    runningHours.toStringAsFixed(2),
                    isDark,
                  ),
                if (item.mfrTime != null)
                  _infoTile(
                    'MFR Time',
                    _dateFormat.format(item.mfrTime!.toLocal()),
                    isDark,
                  ),
                if (item.peEmp != null && item.peEmp!.isNotEmpty)
                  _infoTile('PE', item.peEmp!, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, bool isDark) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.blueGrey[200] : Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.blueGrey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.red[200] : Colors.red[800],
              ),
            ),
          ),
          TextButton(
            onPressed: () => controller.fetchData(force: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullError(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: isDark ? Colors.red[200] : Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Unable to load stencil monitor data.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.blueGrey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => controller.fetchData(force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.blueGrey[700]! : Colors.blueGrey[100]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 48,
            color: isDark ? Colors.white30 : Colors.blueGrey[300],
          ),
          const SizedBox(height: 12),
          const Text(
            'No stencil records match the selected filters.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status, bool isDark) {
    final normalized = status.toUpperCase();
    switch (normalized) {
      case 'PRODUCTION':
        return Colors.greenAccent.shade400;
      case 'TOOLROOM':
        return Colors.lightBlueAccent;
      case 'WAITING':
      case 'PENDING':
        return Colors.orangeAccent;
      case 'WARNING':
      case 'ALERT':
        return Colors.redAccent;
      default:
        return isDark ? Colors.white70 : Colors.blueGrey;
    }
  }
}
