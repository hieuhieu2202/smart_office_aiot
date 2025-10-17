import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/model/AppModel.dart';
import 'package:smart_factory/screen/home/controller/home_controller.dart';
import 'package:smart_factory/screen/home/widget/project_list_page.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';
import 'package:smart_factory/service/update_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../routes/screen_factory.dart';
import '../../screen/home/controller/ai_controller.dart';
import '../../screen/home/widget/ai_chat/chatbot_fab.dart';
import '../../util/dashboard_labels.dart';
import '../../widget/custom_app_bar.dart';
import '../setting/controller/setting_controller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final HomeController homeController = Get.find<HomeController>();
  final LoginController loginController = Get.find<LoginController>();
  final SettingController settingController = Get.find<SettingController>();
  final UpdateService _updateService = const UpdateService();

  final AiController _ai = AiController();

  final Map<int, PageController> _pageControllers = {};
  final Map<int, int> _currentPageIndexes = {};

  bool _isCheckingUpdate = false;
  bool _hasPromptedUpdate = false;

  List<List<T>> chunk<T>(List<T> list, int size) {
    final List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  Future<void> _maybeCheckForUpdates() async {
    if (!mounted || _hasPromptedUpdate || _isCheckingUpdate) {
      return;
    }

    _isCheckingUpdate = true;
    try {
      var summary = settingController.versionSummary.value;
      summary ??= await _updateService.fetchVersionSummary();
      if (!mounted) return;

      final result = await _updateService.checkAndPrompt(
        context,
        initialSummary: summary,
      );

      if (!mounted) return;

      final effectiveSummary = result ?? summary;
      if (effectiveSummary != null) {
        settingController.applyVersionSummary(effectiveSummary);
      }

      _hasPromptedUpdate = true;
    } on UpdateCheckException catch (error) {
      debugPrint(
        'Không thể kiểm tra cập nhật ở màn hình Home: ${error.message}',
      );
    } catch (error) {
      debugPrint('Không thể kiểm tra cập nhật ở màn hình Home: $error');
    } finally {
      _isCheckingUpdate = false;
    }
  }

  double _horizontalPadding(ResponsiveBreakpointsData data) {
    if (data.smallerThan(TABLET)) {
      return 16;
    }
    if (data.smallerThan(DESKTOP)) {
      return 32;
    }
    return 64;
  }

  double _verticalPadding(ResponsiveBreakpointsData data) {
    if (data.smallerThan(TABLET)) {
      return 20;
    }
    if (data.smallerThan(DESKTOP)) {
      return 28;
    }
    return 36;
  }

  double _cardSpacing(bool isDesktop) => isDesktop ? 32 : 24;

  int _columnsFor(double maxWidth, bool isDesktop) {
    if (isDesktop) {
      return maxWidth >= 1500 ? 4 : 3;
    }
    return 2;
  }

  double _cardWidth(double maxWidth, int columns, double spacing) {
    if (columns <= 1) {
      return maxWidth;
    }
    final totalSpacing = spacing * (columns - 1);
    return (maxWidth - totalSpacing) / columns;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeCheckForUpdates();
    });
    _ai.setContext({'factory': 'F16', 'floor': '3F'});
  }

  @override
  void dispose() {
    for (final controller in _pageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S text = S.of(context);
    final breakpoints = ResponsiveBreakpoints.of(context);
    final bool isMobile = breakpoints.smallerThan(TABLET);
    final bool isTablet = breakpoints.between(TABLET, DESKTOP);
    final bool isDesktop = breakpoints.largerOrEqualTo(DESKTOP);
    final double horizontalPadding = _horizontalPadding(breakpoints);
    final double verticalPadding = _verticalPadding(breakpoints);

    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;
      return Scaffold(
        appBar: CustomAppBar(
          title: Text(text.welcome_factory),
          isDark: isDark,
          accent: GlobalColors.accentByIsDark(isDark),
          titleAlign: TextAlign.left,
        ),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      GlobalColors.bodyDarkBg,
                      Colors.blueGrey[900]!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : LinearGradient(
                    colors: [
                      Colors.blue[50]!.withOpacity(0.9),
                      Colors.grey[100]!.withOpacity(0.88),
                      Colors.blue[100]!.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final projects = homeController.projects;
              final double availableWidth = constraints.maxWidth;
              final double maxContentWidth = math.min(
                availableWidth,
                isDesktop
                    ? 1600
                    : isTablet
                        ? 1100
                        : availableWidth,
              );
              final EdgeInsets contentPadding = EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              );

              final Widget view = isMobile
                  ? ListView.separated(
                      key: const ValueKey('home-mobile'),
                      padding: contentPadding,
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => SizedBox(
                        height: _cardSpacing(false),
                      ),
                      itemBuilder: (context, idx) {
                        return _buildProjectCard(
                          context: context,
                          project: projects[idx],
                          projectIndex: idx,
                          isDark: isDark,
                          isMobile: true,
                          isTablet: false,
                          isDesktop: false,
                        );
                      },
                    )
                  : SingleChildScrollView(
                      key: const ValueKey('home-expanded'),
                      padding: contentPadding,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Builder(
                            builder: (context) {
                              final int columns = _columnsFor(
                                maxContentWidth,
                                isDesktop,
                              );
                              final double spacing = _cardSpacing(isDesktop);
                              final double cardWidth = _cardWidth(
                                maxContentWidth,
                                columns,
                                spacing,
                              );

                              return Wrap(
                                alignment: WrapAlignment.start,
                                runAlignment: WrapAlignment.start,
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  for (int idx = 0;
                                      idx < projects.length;
                                      idx++)
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildProjectCard(
                                        context: context,
                                        project: projects[idx],
                                        projectIndex: idx,
                                        isDark: isDark,
                                        isMobile: false,
                                        isTablet: isTablet,
                                        isDesktop: isDesktop,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: view,
              );
            },
          ),
        ),
        floatingActionButton: ChatbotFab(controller: _ai),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    });
  }

  Widget _buildProjectCard({
    required BuildContext context,
    required AppProject project,
    required int projectIndex,
    required bool isDark,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final subProjects = project.subProjects;
    final bool showPagedView = isMobile && subProjects.isNotEmpty;
    final double cardPadding = isDesktop
        ? 28
        : isTablet
            ? 24
            : 20;
    final double headerSpacing = isDesktop
        ? 24
        : isTablet
            ? 22
            : 18;
    final double iconSize = isDesktop
        ? 44
        : isTablet
            ? 40
            : 36;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isDark
            ? LinearGradient(
                colors: [
                  GlobalColors.cardDarkBg.withOpacity(0.97),
                  Colors.blueGrey[800]!.withOpacity(0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.88),
                  Colors.blue[50]!.withOpacity(0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.32 : 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.blueGrey.withOpacity(0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: (isDark
                              ? GlobalColors.primaryButtonDark
                              : GlobalColors.primaryButtonLight)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      project.icon ?? Icons.dashboard,
                      size: iconSize,
                      color: isDark
                          ? GlobalColors.primaryButtonDark
                          : GlobalColors.primaryButtonLight,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AutoSizeText(
                      getModuleLabel(context, project.name),
                      style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop
                            ? 22
                            : isTablet
                                ? 20
                                : 18,
                      ),
                      maxLines: 2,
                      minFontSize: 16,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 12,
                      vertical: isDesktop ? 8 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? GlobalColors.primaryButtonDark
                              : GlobalColors.primaryButtonLight)
                          .withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AutoSizeText(
                      getStatusText(context, project.status),
                      style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                        color: isDark
                            ? GlobalColors.primaryButtonDark
                            : GlobalColors.primaryButtonLight,
                        fontWeight: FontWeight.w700,
                      ),
                      minFontSize: 10,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: headerSpacing),
              if (subProjects.isEmpty)
                _buildEmptyState(context, isDark)
              else if (showPagedView)
                _buildPagedSubProjects(
                  context: context,
                  projectIndex: projectIndex,
                  pages: chunk(subProjects, 4),
                  isDark: isDark,
                )
              else
                _buildGridSubProjects(
                  context: context,
                  subProjects: subProjects,
                  isDark: isDark,
                  isDesktop: isDesktop,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final S text = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          text.no_id,
          style: GlobalTextStyles.bodySmall(isDark: isDark),
        ),
      ),
    );
  }

  Widget _buildPagedSubProjects({
    required BuildContext context,
    required int projectIndex,
    required List<List<AppProject>> pages,
    required bool isDark,
  }) {
    final pageController = _pageControllers.putIfAbsent(
      projectIndex,
      () => PageController(),
    );

    return Column(
      children: [
        SizedBox(
          height: 138,
          child: PageView.builder(
            controller: pageController,
            itemCount: pages.length,
            onPageChanged: (page) {
              setState(() {
                _currentPageIndexes[projectIndex] = page;
              });
            },
            itemBuilder: (context, pageIdx) {
              final pageSubs = pages[pageIdx];
              return Row(
                children: List.generate(4, (i) {
                  if (i >= pageSubs.length) {
                    return const Expanded(child: SizedBox.shrink());
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildSubProjectTile(
                        context: context,
                        sub: pageSubs[i],
                        isDark: isDark,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SmoothPageIndicator(
          controller: pageController,
          count: pages.length,
          effect: WormEffect(
            dotColor: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade400,
            activeDotColor: isDark
                ? GlobalColors.primaryButtonDark
                : GlobalColors.primaryButtonLight,
            dotHeight: 8,
            dotWidth: 8,
            spacing: 8,
          ),
          onDotClicked: (index) {
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGridSubProjects({
    required BuildContext context,
    required List<AppProject> subProjects,
    required bool isDark,
    required bool isDesktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = isDesktop ? 4 : 3;
        final double spacing = isDesktop ? 24 : 18;
        final double availableWidth = constraints.maxWidth;
        final double usableWidth = math.max(
          availableWidth - spacing * (crossAxisCount - 1),
          0,
        );
        final double tileWidth = crossAxisCount > 0
            ? usableWidth / crossAxisCount
            : availableWidth;
        final double minTileHeight = isDesktop ? 188 : 176;
        final double aspectRatio = tileWidth > 0
            ? tileWidth / minTileHeight
            : 1.2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subProjects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return _buildSubProjectTile(
              context: context,
              sub: subProjects[index],
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildSubProjectTile({
    required BuildContext context,
    required AppProject sub,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (sub.subProjects.isNotEmpty) {
            Get.to(() => ProjectListPage(project: sub));
          } else {
            Get.to(() => buildProjectScreen(sub));
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? GlobalColors.cardDarkBg.withOpacity(0.94)
                : Colors.white.withOpacity(0.96),
            border: Border.all(
              color: isDark
                  ? GlobalColors.primaryButtonDark.withOpacity(0.16)
                  : GlobalColors.primaryButtonLight.withOpacity(0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.28)
                    : Colors.black12,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Icon(
                    sub.icon ?? Icons.widgets,
                    size: 30,
                    color: isDark
                        ? GlobalColors.primaryButtonDark
                        : GlobalColors.primaryButtonLight,
                  ),
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  getCardLabel(context, sub.name),
                  style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? GlobalColors.darkPrimaryText
                        : GlobalColors.lightPrimaryText,
                  ),
                  textAlign: TextAlign.center,
                  minFontSize: 9,
                  maxLines: 2,
                ),
                if (sub.status.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AutoSizeText(
                    getStatusText(context, sub.status),
                    style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? GlobalColors.primaryButtonDark
                          : GlobalColors.primaryButtonLight,
                    ),
                    textAlign: TextAlign.center,
                    minFontSize: 8,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
