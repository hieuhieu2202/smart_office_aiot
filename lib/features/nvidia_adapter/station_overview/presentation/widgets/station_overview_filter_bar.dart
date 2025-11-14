import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/station_overview_controller.dart';

class StationOverviewFilterBar extends StatelessWidget {
  const StationOverviewFilterBar({super.key, required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          gradient: LinearGradient(
            colors: <Color>[
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Wrap(
          spacing: 18,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _buildDropdown<String>(
              context: context,
              theme: theme,
              label: 'Model Serial',
              value: controller.selectedModelSerial.value,
              items: const <String>['ADAPTER', 'SWITCH'],
              onChanged: controller.changeModelSerial,
            ),
            _buildDropdown<String>(
              context: context,
              theme: theme,
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
              theme: theme,
              label: 'Model',
              value: controller.selectedModel.value,
              items: <String>['ALL', ...controller.models],
              onChanged: controller.changeModel,
            ),
            _buildDropdown<String>(
              context: context,
              theme: theme,
              label: 'Group',
              value: controller.selectedGroup.value,
              items: <String>['ALL', ...controller.availableGroups],
              onChanged: controller.changeGroup,
            ),
            _DateRangeButton(controller: controller, theme: theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
  }) {
    final TextStyle? itemStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      letterSpacing: 0.8,
    );
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<T>(
        value: items.contains(value) ? value : items.first,
        dropdownColor: const Color(0xFF112145),
        icon: const Icon(Icons.expand_more, color: Colors.white70),
        style: itemStyle,
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white70,
            letterSpacing: 1.1,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0AA5FF)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onChanged: (T? val) {
          if (val != null) onChanged(val);
        },
        items: items
            .map(
              (T item) => DropdownMenuItem<T>(
                value: item,
                child: Text('$item', style: itemStyle),
              ),
            )
            .toList(),
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
    return Obx(() {
      final DateTimeRange? range = controller.selectedRange.value;
      final String label = range == null
          ? 'Auto refresh (last 24h)'
          : '${_format(range.start)}  →  ${_format(range.end)}';
      return SizedBox(
        width: 250,
        child: FilledButton.tonalIcon(
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
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: const Color(0xFF0AA5FF),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            await controller.updateDateRange(picked);
          },
          onLongPress: () => controller.updateDateRange(null),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.08),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.calendar_month),
          label: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      );
    });
  }

  String _format(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
