import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/model/AppModel.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import '../../util/dashboard_labels.dart';

class ModuleDetailScreen extends StatelessWidget {
  final AppProject module;
  final bool isDark;
  const ModuleDetailScreen({super.key, required this.module, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        title: Text(getModuleLabel(context, module.name)),
        elevation: 0,
      ),
      backgroundColor: isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: GridView.builder(
          itemCount: module.subProjects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, idx) {
            final sub = module.subProjects[idx];
            return Card(
              elevation: 2,
              color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Get.snackbar(getModuleLabel(context, module.name), '${getCardLabel(context, sub.name)} - ${getStatusText(context, sub.status)}');
                  // TODO: Điều hướng vào màn hình chi tiết subproject nếu muốn
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(sub.icon, size: 38, color: isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight),
                      const SizedBox(height: 10),
                      Text(
                        getCardLabel(context, sub.name),
                        style: GlobalTextStyles.bodyMedium(isDark: isDark),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sub.status.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? GlobalColors.primaryButtonDark.withOpacity(0.11)
                                : GlobalColors.primaryButtonLight.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            getStatusText(context, sub.status),
                            style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
