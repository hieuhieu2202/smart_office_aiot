import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/camera/camera_menu_screen.dart';
import 'package:smart_factory/screen/home/controller/ai_controller.dart';
import 'package:smart_factory/screen/home/widget/ai_chat/chatbot_fab.dart';
import 'package:smart_factory/screen/home/widget/neon_network_background.dart';
import 'package:smart_factory/screen/home/widget/qr/qr_scan_screen.dart';
import 'package:smart_factory/screen/home/widget/small_feature_card.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final AiController _aiController = AiController();

  @override
  void initState() {
    super.initState();
    _aiController.setContext({'factory': 'F16', 'floor': '3F'});
  }

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    final S text = S.of(context);

    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;
      final ThemeData theme = Theme.of(context);

      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            NeonNetworkBackdrop(
              isDark: isDark,
              child: const SizedBox.expand(),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      text.welcome_factory,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thao tác nhanh để bắt đầu công việc',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.82),
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final double cardHeight =
                            (constraints.maxWidth - 14) / 2 * 0.85;
                        return GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio:
                              constraints.maxWidth / (2 * cardHeight + 14),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: <Widget>[
                            SmallFeatureCard(
                              title: 'Capture',
                              icon: Icons.camera_alt_rounded,
                              onTap: () => Get.to(() => const CameraMenuScreen()),
                            ),
                            SmallFeatureCard(
                              title: 'QR Scan',
                              icon: Icons.qr_code_scanner_rounded,
                              onTap: () => Get.to(() => const QRScanScreen()),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.white.withOpacity(0.38),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.12)
                                : Colors.white.withOpacity(0.55),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Dashboard content placeholder',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: ChatbotFab(controller: _aiController),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    });
  }
}
