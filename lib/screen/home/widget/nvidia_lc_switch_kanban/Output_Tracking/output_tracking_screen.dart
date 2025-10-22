import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../controller/nvidia_lc_switch_kanban_controller.dart';
import 'filter_panel.dart';
import 'table.dart';

class OutputTrackingScreen extends StatefulWidget {
  const OutputTrackingScreen({super.key});

  @override
  State<OutputTrackingScreen> createState() => _OutputTrackingScreenState();
}

class _OutputTrackingScreenState extends State<OutputTrackingScreen> {
  late final KanbanController _controller;
  late DateTime _selectedDate;
  late String _selectedShift;
  late List<String> _selectedModels;

  static const List<String> _shiftOptions = ['Day', 'Night', 'All'];

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<KanbanController>()
        ? Get.find<KanbanController>()
        : Get.put(KanbanController());
    _selectedDate = _controller.date.value;
    _selectedShift = _controller.shift.value;
    _selectedModels = _controller.groups.toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openModelPicker() async {
    await _controller.ensureModels(force: true);
    final allModels = _controller.allModels.toList();
    if (allModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No model available for the current filter.')),
      );
      return;
    }

    final result = await showOtModelPicker(
      context: context,
      allModels: allModels,
      initialSelection: _selectedModels.toSet(),
    );

    if (result != null) {
      setState(() {
        _selectedModels = result.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    }
  }

  void _onShiftChanged(String? newShift) {
    if (newShift == null) return;
    setState(() => _selectedShift = newShift);
  }

  void _onQuery() {
    final groups = _selectedModels.isEmpty ? _controller.groups.toList() : _selectedModels;
    _controller.updateFilter(
      newDate: _selectedDate,
      newShift: _selectedShift,
      newGroups: groups,
    );
  }

  void _onExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export Excel đang được phát triển.')),
    );
  }

  double _computeTableHeight(BuildContext context, bool isMobile, bool isTablet) {
    final size = MediaQuery.of(context).size;
    final reserved = isMobile
        ? 320.0
        : isTablet
            ? 360.0
            : 380.0;
    final base = size.height - reserved;
    final fallback = size.height * (isMobile ? 0.78 : 0.68);
    final candidate = base.isFinite && base > 200 ? base : fallback;
    final maxHeight = size.height * 0.92;
    return candidate
        .clamp(320.0, math.max(320.0, maxHeight))
        .toDouble();
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizing) {
        final isMobile = sizing.deviceScreenType == DeviceScreenType.mobile;
        final isTablet = sizing.deviceScreenType == DeviceScreenType.tablet;
        final horizontalPadding = isMobile ? 12.0 : 20.0;
        final title = 'NVIDIA ${_controller.modelSerial.value} Output Tracking';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            actions: [
              Obx(() {
                final busy = _controller.isLoading.value;
                return IconButton(
                  tooltip: 'Reload',
                  onPressed: busy ? null : _controller.loadAll,
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                );
              }),
            ],
          ),
          body: SafeArea(
            child: Obx(() {
              final isLoading = _controller.isLoading.value;
              final error = _controller.error.value;
              final output = _controller.outputTracking.value;
              final hours = _controller.hours;
              final data = output?.data ?? const [];
              final orderedGroups = <String>[];
              final seenGroups = <String>{};
              for (final row in data) {
                final name = row.groupName.trim();
                if (name.isEmpty) continue;
                if (seenGroups.add(name)) orderedGroups.add(name);
              }
              final modelsForDisplay = output?.model ?? _controller.groups.toList();

              return RefreshIndicator(
                onRefresh: _controller.loadAll,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: OtSearchMenu(
                          dateText: _formatDate(_selectedDate),
                          shift: _selectedShift,
                          shiftOptions: _shiftOptions,
                          selectedModelCount: _selectedModels.length,
                          isBusy: isLoading,
                          isLoadingModels: _controller.isLoadingModels.value,
                          onPickDate: _pickDate,
                          onShiftChanged: _onShiftChanged,
                          onSelectModels: _openModelPicker,
                          onExport: _onExport,
                          onQuery: _onQuery,
                        ),
                      ),
                    ),
                    if (isLoading && output == null)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null && error.isNotEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StateBox(
                          icon: Icons.error_outline,
                          title: 'Load failed',
                          subtitle: error,
                          actionText: 'Retry',
                          onPressed: _controller.loadAll,
                        ),
                      )
                    else if (orderedGroups.isEmpty || hours.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StateBox(
                          icon: Icons.inbox_outlined,
                          title: 'No data',
                          subtitle: 'Hãy kiểm tra lại bộ lọc và thử lại.',
                          actionText: 'Reload',
                          onPressed: _controller.loadAll,
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 12,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25),
                                    Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.12),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: SizedBox(
                                height: _computeTableHeight(context, isMobile, isTablet),
                                child: OtTable(
                                  hours: hours,
                                  groups: orderedGroups,
                                  models: modelsForDisplay,
                                  modelNameByGroup: _controller.modelNameByGroup,
                                  passByGroup: _controller.passSeriesByGroup,
                                  yrByGroup: _controller.yrSeriesByGroup,
                                  rrByGroup: _controller.rrSeriesByGroup,
                                  wipByGroup: _controller.wipByGroup,
                                  totalPassByGroup: _controller.totalPassByGroup,
                                  totalFailByGroup: _controller.totalFailByGroup,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(title, style: theme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: theme.bodySmall),
            const SizedBox(height: 18),
            FilledButton(onPressed: onPressed, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}

class OtSearchMenu extends StatelessWidget {
  const OtSearchMenu({
    super.key,
    required this.dateText,
    required this.shift,
    required this.shiftOptions,
    required this.selectedModelCount,
    required this.isBusy,
    required this.isLoadingModels,
    required this.onPickDate,
    required this.onShiftChanged,
    required this.onSelectModels,
    required this.onExport,
    required this.onQuery,
  });

  final String dateText;
  final String shift;
  final List<String> shiftOptions;
  final int selectedModelCount;
  final bool isBusy;
  final bool isLoadingModels;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onShiftChanged;
  final VoidCallback onSelectModels;
  final VoidCallback onExport;
  final VoidCallback onQuery;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final fieldWidth = isNarrow ? constraints.maxWidth : 240.0;
        final compactWidth = isNarrow ? constraints.maxWidth : 200.0;

        final labelStyle = Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600);

        Widget buildDateField() {
          return SizedBox(
            width: fieldWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date', style: labelStyle),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onPickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(dateText),
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildShiftField() {
          return SizedBox(
            width: compactWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shift', style: labelStyle),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: shiftOptions.contains(shift) ? shift : shiftOptions.first,
                  items: [
                    for (final item in shiftOptions)
                      DropdownMenuItem(value: item, child: Text(item.toUpperCase())),
                  ],
                  onChanged: isBusy ? null : onShiftChanged,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
            ),
          );
        }

        Widget buildModelButton() {
          final buttonLabel = selectedModelCount > 0
              ? 'Selected: $selectedModelCount'
              : 'Select Models';
          return SizedBox(
            width: fieldWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Models', style: labelStyle),
                const SizedBox(height: 6),
                FilledButton.tonalIcon(
                  onPressed: isLoadingModels || isBusy ? null : onSelectModels,
                  icon: isLoadingModels
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.inventory_2_outlined),
                  label: Text(buttonLabel),
                ),
              ],
            ),
          );
        }

        Widget buildActions() {
          final exportButton = FilledButton.icon(
            onPressed: isBusy ? null : onExport,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('EXPORT EXCEL'),
          );

          final queryButton = FilledButton.icon(
            onPressed: isBusy ? null : onQuery,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.search),
            label: isBusy
                ? const Text('LOADING...')
                : const Text('QUERY'),
          );

          if (isNarrow) {
            return SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  exportButton,
                  const SizedBox(height: 10),
                  queryButton,
                ],
              ),
            );
          }

          return SizedBox(
            width: 340,
            child: Row(
              children: [
                Expanded(child: exportButton),
                const SizedBox(width: 12),
                Expanded(child: queryButton),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(isNarrow ? 12 : 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Wrap(
            spacing: isNarrow ? 12 : 20,
            runSpacing: isNarrow ? 14 : 18,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              buildDateField(),
              buildShiftField(),
              buildModelButton(),
              buildActions(),
            ],
          ),
        );
      },
    );
  }
}
