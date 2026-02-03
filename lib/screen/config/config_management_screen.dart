import 'package:flutter/material.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';

class ConfigManagementScreen extends StatefulWidget {
  const ConfigManagementScreen({super.key});

  @override
  State<ConfigManagementScreen> createState() => _ConfigManagementScreenState();
}

class _ConfigManagementScreenState extends State<ConfigManagementScreen> {
  // Controllers for configuration fields (UI only).
  final TextEditingController _factoryController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _stationController = TextEditingController();

  bool _isActive = true;

  @override
  void dispose() {
    _factoryController.dispose();
    _floorController.dispose();
    _productNameController.dispose();
    _modelController.dispose();
    _stationController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _isDark ? GlobalColors.labelDark : GlobalColors.labelLight,
      ),
      filled: true,
      fillColor: _isDark ? GlobalColors.inputDarkFill : GlobalColors.inputLightFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _isDark ? GlobalColors.borderDark : GlobalColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _isDark ? GlobalColors.borderDark : GlobalColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _isDark
              ? GlobalColors.primaryButtonDark
              : GlobalColors.primaryButtonLight,
          width: 1.4,
        ),
      ),
    );
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color:
                _isDark
                    ? GlobalColors.appBarDarkText
                    : GlobalColors.appBarLightText,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Cấu hình hệ thống',
          style: GlobalTextStyles.bodyMedium(isDark: _isDark).copyWith(
            color:
                _isDark
                    ? GlobalColors.appBarDarkText
                    : GlobalColors.appBarLightText,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Configuration information card.
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: _isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin cấu hình',
                        style: GlobalTextStyles.bodyMedium(isDark: _isDark)
                            .copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _factoryController,
                        style: GlobalTextStyles.bodySmall(isDark: _isDark).copyWith(
                          fontSize: 14,
                          color:
                              _isDark
                                  ? GlobalColors.darkPrimaryText
                                  : GlobalColors.lightPrimaryText,
                        ),
                        decoration: _buildInputDecoration(label: 'Factory'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _floorController,
                        style: GlobalTextStyles.bodySmall(isDark: _isDark).copyWith(
                          fontSize: 14,
                          color:
                              _isDark
                                  ? GlobalColors.darkPrimaryText
                                  : GlobalColors.lightPrimaryText,
                        ),
                        decoration: _buildInputDecoration(label: 'Floor'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _productNameController,
                        style: GlobalTextStyles.bodySmall(isDark: _isDark).copyWith(
                          fontSize: 14,
                          color:
                              _isDark
                                  ? GlobalColors.darkPrimaryText
                                  : GlobalColors.lightPrimaryText,
                        ),
                        decoration: _buildInputDecoration(label: 'ProductName'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _modelController,
                        style: GlobalTextStyles.bodySmall(isDark: _isDark).copyWith(
                          fontSize: 14,
                          color:
                              _isDark
                                  ? GlobalColors.darkPrimaryText
                                  : GlobalColors.lightPrimaryText,
                        ),
                        decoration: _buildInputDecoration(label: 'Model'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _stationController,
                        style: GlobalTextStyles.bodySmall(isDark: _isDark).copyWith(
                          fontSize: 14,
                          color:
                              _isDark
                                  ? GlobalColors.darkPrimaryText
                                  : GlobalColors.lightPrimaryText,
                        ),
                        decoration: _buildInputDecoration(label: 'Station'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Activation switch row.
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kích hoạt',
                        style: GlobalTextStyles.bodyMedium(isDark: _isDark)
                            .copyWith(fontSize: 16),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: accent,
                        inactiveThumbColor: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons.
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: handle save configuration
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Lưu cấu hình',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: handle cancel
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            _isDark
                                ? GlobalColors.darkPrimaryText
                                : GlobalColors.lightPrimaryText,
                        side: BorderSide(color: accent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
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
