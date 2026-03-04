import 'package:flutter/material.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/screen/config/config_management_screen.dart';

class ConfigListScreen extends StatefulWidget {
  const ConfigListScreen({super.key});

  @override
  State<ConfigListScreen> createState() => _ConfigListScreenState();
}

class _ConfigListScreenState extends State<ConfigListScreen> {
  final List<_ConfigItem> _mockConfigs = [
    const _ConfigItem(
      factory: 'Factory A',
      floor: '1F',
      productName: 'Product Alpha',
      model: 'Model-X',
      station: 'Station 01',
      isActive: true,
    ),
    const _ConfigItem(
      factory: 'Factory B',
      floor: '2F',
      productName: 'Product Beta',
      model: 'Model-Y',
      station: 'Station 02',
      isActive: false,
    ),
    const _ConfigItem(
      factory: 'Factory C',
      floor: '3F',
      productName: 'Product Gamma',
      model: 'Model-Z',
      station: 'Station 03',
      isActive: true,
    ),
  ];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  void _openConfigManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ConfigManagementScreen(),
      ),
    );
  }

  Future<void> _showDeleteDialog(_ConfigItem item) async {
    final accent =
        _isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight;

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              _isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Xác nhận xoá',
            style: GlobalTextStyles.bodyMedium(isDark: _isDark),
          ),
          content: Text(
            'Bạn có chắc muốn xoá cấu hình cho ${item.factory}?',
            style: GlobalTextStyles.bodySmall(isDark: _isDark).copyWith(
              fontSize: 14,
              color:
                  _isDark
                      ? GlobalColors.darkSecondaryText
                      : GlobalColors.lightSecondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Hủy',
                style: TextStyle(color: accent),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: implement delete action later.
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        _isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight;

    return Scaffold(
      backgroundColor: _isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
      appBar: AppBar(
        backgroundColor:
            _isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        elevation: 0,
        title: Text(
          'Danh sách cấu hình',
          style: GlobalTextStyles.bodyMedium(isDark: _isDark).copyWith(
            color:
                _isDark
                    ? GlobalColors.appBarDarkText
                    : GlobalColors.appBarLightText,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openConfigManagement,
            icon: Icon(
              Icons.add_circle_outline,
              color:
                  _isDark
                      ? GlobalColors.appBarDarkText
                      : GlobalColors.appBarLightText,
            ),
            tooltip: 'Thêm cấu hình',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: _mockConfigs.length,
        itemBuilder: (context, index) {
          final item = _mockConfigs[index];
          return _ConfigCard(
            item: item,
            isDark: _isDark,
            accent: accent,
            onTap: _openConfigManagement,
            onDelete: () => _showDeleteDialog(item),
          );
        },
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.item,
    required this.isDark,
    required this.accent,
    required this.onTap,
    required this.onDelete,
  });

  final _ConfigItem item;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color get _badgeColor =>
      item.isActive
          ? accent
          : (isDark
              ? GlobalColors.darkSecondaryText
              : GlobalColors.lightSecondaryText);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.factory,
                      style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.isActive ? 'ACTIVE' : 'INACTIVE',
                      style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                        color: _badgeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ConfigRow(label: 'Floor', value: item.floor, isDark: isDark),
              _ConfigRow(
                label: 'ProductName',
                value: item.productName,
                isDark: isDark,
              ),
              _ConfigRow(label: 'Model', value: item.model, isDark: isDark),
              _ConfigRow(label: 'Station', value: item.station, isDark: isDark),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onTap,
                    icon: Icon(Icons.edit, color: accent),
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? GlobalColors.labelDark : GlobalColors.labelLight;
    final valueColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                color: labelColor,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigItem {
  const _ConfigItem({
    required this.factory,
    required this.floor,
    required this.productName,
    required this.model,
    required this.station,
    required this.isActive,
  });

  final String factory;
  final String floor;
  final String productName;
  final String model;
  final String station;
  final bool isActive;
}
