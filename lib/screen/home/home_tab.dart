import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/routes/screen_factory.dart';
import 'package:smart_factory/screen/home/controller/ai_controller.dart';
import 'package:smart_factory/screen/home/controller/home_controller.dart';
import 'package:smart_factory/screen/home/widget/ai_chat/chatbot_fab.dart';
import 'package:smart_factory/screen/home/widget/feature_card.dart';
import 'package:smart_factory/screen/home/widget/neon_network_background.dart';
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
    final HomeController homeController = Get.find<HomeController>();
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
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
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
                      'Select a feature to continue',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: homeController.projects.length,
                        itemBuilder: (BuildContext context, int index) {
                          final project = homeController.projects[index];
                          return FeatureCard(
                            title: project.name,
                            icon: project.icon ?? Icons.widgets_rounded,
                            onTap: () => Get.to(() => buildProjectScreen(project)),
                          );
                        },
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
