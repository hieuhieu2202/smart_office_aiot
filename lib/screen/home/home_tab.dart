import 'dart:ui';

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
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _GlassHeader(
                      title: text.welcome_factory,
                      subtitle: 'Thao tác nhanh để bắt đầu công việc',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: LayoutBuilder(
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
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
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

class _GlassHeader extends StatelessWidget {
  const _GlassHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color borderColor = isDark
        ? const Color(0xFF52D3FF).withOpacity(0.58)
        : const Color(0xFF1FA4FF).withOpacity(0.45);
    final Color titleColor = isDark
        ? const Color(0xFFE9F9FF)
        : const Color(0xFF0E365A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.52),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: borderColor.withOpacity(isDark ? 0.32 : 0.20),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
