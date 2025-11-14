import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/station_overview_controller.dart';

class StationOverviewFilterBar extends StatefulWidget {
  const StationOverviewFilterBar({
    super.key,
    required this.controller,
    this.orientation = Axis.vertical,
  });

  final StationOverviewController controller;
  final Axis orientation;

  @override
  State<StationOverviewFilterBar> createState() => _StationOverviewFilterBarState();
}

class _StationOverviewFilterBarState extends State<StationOverviewFilterBar> {
  late final TextEditingController _searchController;
  StreamSubscription<String>? _searchSubscription;

  StationOverviewController get controller => widget.controller;

  bool get _isVertical => widget.orientation == Axis.vertical;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: controller.stationSearch.value);
    _searchSubscription = controller.stationSearch.listen((String value) {
      if (_searchController.text.toUpperCase() == value) return;
      _searchController
        ..text = value
        ..selection = TextSelection.collapsed(offset: value.length);
    });
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets padding = _isVertical
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 24)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 16);

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          color: const Color(0xFF091B3A).withOpacity(0.75),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: padding,
        child: _isVertical ? _buildVerticalLayout(theme) : _buildHorizontalLayout(theme),
      ),
    );
  }

  Widget _buildVerticalLayout(ThemeData theme) {
    final TextStyle? sectionStyle = theme.textTheme.labelMedium?.copyWith(
      color: Colors.cyanAccent,
      letterSpacing: 1.4,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('FILTER OPTIONS', style: sectionStyle),
        const SizedBox(height: 16),
        _buildDropdown(
          theme: theme,
          label: 'Model Serial',
          value: controller.selectedModelSerial.value,
          items: const <String>['ADAPTER', 'SWITCH'],
          onChanged: controller.changeModelSerial,
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          theme: theme,
          label: 'Product',
          value: controller.selectedProduct.value,
          items: <String>['ALL', ...controller.products.map((item) => item.productName)],
          onChanged: controller.changeProduct,
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          theme: theme,
          label: 'Model',
          value: controller.selectedModel.value,
          items: <String>['ALL', ...controller.models],
          onChanged: controller.changeModel,
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          theme: theme,
          label: 'Station Group',
          value: controller.selectedGroup.value,
          items: <String>['ALL', ...controller.availableGroups],
          onChanged: controller.changeGroup,
        ),
        const SizedBox(height: 16),
        _DateRangeButton(controller: controller, theme: theme),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: controller.loadOverview,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('QUERY DATA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.white.withOpacity(0.08)),
        const SizedBox(height: 16),
        Text('SEARCH STATION', style: sectionStyle),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          onChanged: controller.updateStationSearch,
          onSubmitted: controller.updateStationSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: controller.stationSearch.value.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      controller.updateStationSearch('');
                      _searchController.clear();
                    },
                  ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF00BCD4)),
            ),
            hintText: 'Enter station name',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(ThemeData theme) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _buildDropdown(
          theme: theme,
          label: 'Model Serial',
          value: controller.selectedModelSerial.value,
          items: const <String>['ADAPTER', 'SWITCH'],
          onChanged: controller.changeModelSerial,
          width: 200,
        ),
        _buildDropdown(
          theme: theme,
          label: 'Product',
          value: controller.selectedProduct.value,
          items: <String>['ALL', ...controller.products.map((item) => item.productName)],
          onChanged: controller.changeProduct,
          width: 200,
        ),
        _buildDropdown(
          theme: theme,
          label: 'Model',
          value: controller.selectedModel.value,
          items: <String>['ALL', ...controller.models],
          onChanged: controller.changeModel,
          width: 200,
        ),
        _buildDropdown(
          theme: theme,
          label: 'Station Group',
          value: controller.selectedGroup.value,
          items: <String>['ALL', ...controller.availableGroups],
          onChanged: controller.changeGroup,
          width: 200,
        ),
        SizedBox(
          width: 240,
          child: _DateRangeButton(controller: controller, theme: theme),
        ),
        SizedBox(
          width: 220,
          child: TextField(
            controller: _searchController,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            onChanged: controller.updateStationSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              hintText: 'Search station',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF00BCD4)),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: controller.loadOverview,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('QUERY DATA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required ThemeData theme,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    double? width,
  }) {
    final TextStyle? textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      letterSpacing: 0.8,
    );

    final DropdownButtonFormField<String> field = DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      dropdownColor: const Color(0xFF112145),
      icon: const Icon(Icons.expand_more, color: Colors.white70),
      style: textStyle,
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
          borderSide: const BorderSide(color: Color(0xFF00BCD4)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onChanged: (String? val) {
        if (val != null) onChanged(val);
      },
      items: items
          .map(
            (String item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: textStyle),
            ),
          )
          .toList(),
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
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
      return FilledButton.tonalIcon(
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
                    primary: const Color(0xFF00BCD4),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.calendar_month),
        label: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      );
    });
  }

  String _format(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
