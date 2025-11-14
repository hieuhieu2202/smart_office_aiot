import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/station_overview_controller.dart';

class StationOverviewFilterBar extends StatelessWidget {
  const StationOverviewFilterBar({super.key, required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _buildDropdown<String>(
            context: context,
            label: 'Model Serial',
            value: controller.selectedModelSerial.value,
            items: const <String>['ADAPTER', 'SWITCH'],
            onChanged: controller.changeModelSerial,
          ),
          _buildDropdown<String>(
            context: context,
            label: 'Product',
            value: controller.selectedProduct.value,
            items: <String>[
              'ALL',
              ...controller.products.map((item) => item.productName),
            ],
            onChanged: controller.changeProduct,
          ),
          _buildDropdown<String>(
            context: context,
            label: 'Model',
            value: controller.selectedModel.value,
            items: <String>['ALL', ...controller.models],
            onChanged: controller.changeModel,
          ),
          _buildDropdown<String>(
            context: context,
            label: 'Group',
            value: controller.selectedGroup.value,
            items: <String>['ALL', ...controller.availableGroups],
            onChanged: controller.changeGroup,
          ),
          _DateRangeButton(controller: controller, theme: theme),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            onChanged: (T? val) {
              if (val != null) onChanged(val);
            },
            items: items
                .map(
                  (T item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text('$item'),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({
    required this.controller,
    required this.theme,
  });

  final StationOverviewController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = theme.colorScheme;
    return Obx(() {
      final DateTimeRange? range = controller.selectedRange;
      final String label = range == null
          ? 'Auto refresh (last 24h)'
          : '${_format(range.start)} - ${_format(range.end)}';
      return OutlinedButton.icon(
        onPressed: () async {
          final DateTime now = DateTime.now();
          final DateTimeRange initialRange = range ??
              DateTimeRange(
                start: now.subtract(const Duration(hours: 24)),
                end: now,
              );
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            initialDateRange: initialRange,
            firstDate: now.subtract(const Duration(days: 30)),
            lastDate: now.add(const Duration(days: 1)),
            helpText: 'Select custom range',
          );
          await controller.updateDateRange(picked);
        },
        onLongPress: () => controller.updateDateRange(null),
        icon: Icon(
          Icons.calendar_month,
          color: colors.primary,
        ),
        label: Text(label),
      );
    });
  }

  String _format(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
