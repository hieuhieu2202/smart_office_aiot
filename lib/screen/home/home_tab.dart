import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:smart_factory/screen/home/widget/project_list_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/screen/home/controller/home_controller.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';
import 'package:smart_factory/service/update_service.dart';
import '../../routes/screen_factory.dart';
import '../../util/dashboard_labels.dart';
import '../../widget/custom_app_bar.dart';
import '../setting/controller/setting_controller.dart';
import '../../screen/home/controller/ai_controller.dart';
import '../../screen/home/widget/ai_chat/chatbot_fab.dart';
import '../../screen/home/widget/neon_network_background.dart';

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

  // ================== AI CHAT: KHAI BÁO CONTROLLER ==================
  // NOTE: đây là state riêng cho chat-bubble ở HomeTab
  final AiController _ai = AiController();

  // ================================================================

  // Map để lưu PageController cho từng module
  final Map<int, PageController> _pageControllers = {};
  final Map<int, int> _currentPageIndexes = {};
  final Map<int, PageController> _widePageControllers = {};
  final Map<int, int> _wideCurrentPageIndexes = {};

  bool _isCheckingUpdate = false;
  bool _hasPromptedUpdate = false;

  // Helper: chia subProjects thành các "trang", mỗi trang tối đa 4 cái
  List<List<T>> chunk<T>(List<T> list, int size) {
    List<List<T>> chunks = [];
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
    for (final controller in _widePageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S text = S.of(context);
    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;
      return ResponsiveBuilder(
        builder: (context, sizingInfo) {
          final DeviceScreenType deviceType = sizingInfo.deviceScreenType;
          final bool isMobile = deviceType == DeviceScreenType.mobile;
          final bool isTablet = deviceType == DeviceScreenType.tablet;
          final bool isDesktop = deviceType == DeviceScreenType.desktop;
          final double horizontalPadding = isMobile
              ? 16
              : isTablet
                  ? 32
                  : 64;
          final double verticalPadding = isMobile ? 20 : 32;
          final EdgeInsets contentPadding = EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          );

          return Scaffold(
            appBar: CustomAppBar(
              title: Text(text.welcome_factory),
              isDark: isDark,
              accent: GlobalColors.accentByIsDark(isDark),
              titleAlign: TextAlign.left,
            ),
            body: NeonNetworkBackdrop(
              isDark: isDark,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isMobile
                    ? _buildMobileList(
                        isDark: isDark,
                        text: text,
                        padding: contentPadding,
                      )
                    : _buildAdaptiveGrid(
                        isDark: isDark,
                        text: text,
                        padding: contentPadding,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
              ),
            ),
            // ================== AI CHAT: NÚT TRÒN NỔI (BUBBLE) ==================
            // NOTE 1: Dùng ChatbotFab (mặc định là extended). Nếu bạn muốn NÚT TRÒN NHỎ:
            //   - Xem bên dưới "PHIÊN BẢN MINI" (đã comment).
            floatingActionButton: ChatbotFab(controller: _ai),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

            // --- PHIÊN BẢN MINI (nút tròn nhỏ) ---
            // floatingActionButton: FloatingActionButton.small(
            //   onPressed: () => AiChatSheet.show(context, _ai),
            //   child: const Icon(Icons.smart_toy_outlined),
            // ),
            // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            // ================================================================
          );
        },
      );
    });
  }

  Widget _buildMobileList({
    required bool isDark,
    required S text,
    required EdgeInsets padding,
  }) {
    return ListView.separated(
      key: const ValueKey('home-mobile'),
      padding: padding,
      physics: const BouncingScrollPhysics(),
      itemCount: homeController.projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, idx) {
        final project = homeController.projects[idx];
        return _buildProjectCard(
          context: context,
          isDark: isDark,
          text: text,
          project: project,
          index: idx,
          isMobile: true,
          isTablet: false,
          isDesktop: false,
        );
      },
    );
  }

  Widget _buildAdaptiveGrid({
    required bool isDark,
    required S text,
    required EdgeInsets padding,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth =
            math.max(0, constraints.maxWidth - padding.horizontal).toDouble();
        final double maxWidthLimit = isDesktop ? 1920 : 900;
        final double contentWidth =
            math.min(availableWidth, maxWidthLimit).toDouble();
        final double rawWidth = contentWidth > 0 ? contentWidth : availableWidth;
        final double effectiveWidth =
            rawWidth > 0 ? rawWidth : maxWidthLimit;
        final double spacing = isDesktop ? 24 : 20;

        return SingleChildScrollView(
          key: const ValueKey('home-wide'),
          padding: padding,
          physics: const BouncingScrollPhysics(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: effectiveWidth,
                minWidth: (isTablet || isDesktop)
                    ? effectiveWidth
                    : 0.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int idx = 0; idx < homeController.projects.length; idx++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: idx == homeController.projects.length - 1
                            ? 0
                            : spacing,
                      ),
                      child: _buildProjectCard(
                        context: context,
                        isDark: isDark,
                        text: text,
                        project: homeController.projects[idx],
                        index: idx,
                        isMobile: false,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectCard({
    required BuildContext context,
    required bool isDark,
    required S text,
    required dynamic project,
    required int index,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final subProjects = project.subProjects as List<dynamic>;
    final List<List<dynamic>> pages = isMobile ? chunk(subProjects, 4) : [];
    final List<List<dynamic>> widePages = (!isMobile && subProjects.isNotEmpty)
        ? chunk(subProjects, 8)
        : [];
    final PageController? pageController = isMobile
        ? _pageControllers.putIfAbsent(index, () => PageController())
        : null;
    final bool enableWidePager = isDesktop && subProjects.length > 8;
    final PageController? wideController = enableWidePager
        ? _widePageControllers.putIfAbsent(index, () => PageController())
        : null;
    final double cardPadding = isDesktop
        ? 23
        : isTablet
            ? 20
            : 18;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          project.icon ?? Icons.dashboard,
          size: isDesktop
              ? 35
              : isTablet
                  ? 33
                  : 36,
          color: isDark
              ? GlobalColors.primaryButtonDark
              : GlobalColors.primaryButtonLight,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            getModuleLabel(context, project.name),
            style: GlobalTextStyles.bodyLarge(
              isDark: isDark,
            ).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop
                  ? 18.5
                  : isTablet
                      ? 17.5
                      : 19,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? GlobalColors.primaryButtonDark.withOpacity(0.16)
                : GlobalColors.primaryButtonLight.withOpacity(0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getStatusText(context, project.status),
            style: GlobalTextStyles.bodySmall(
              isDark: isDark,
            ).copyWith(
              color: isDark
                  ? GlobalColors.primaryButtonDark
                  : GlobalColors.primaryButtonLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final borderRadius = BorderRadius.circular(20);
    final Color surfaceColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.45);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.18);

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.32 : 0.16),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 1.1),
              color: surfaceColor,
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 18),
                  if (subProjects.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          text.no_id,
                          style: GlobalTextStyles.bodySmall(
                            isDark: isDark,
                          ),
                        ),
                      ),
                    )
                  else if (isMobile)
                    _buildMobileSubProjectPager(
                      context: context,
                      isDark: isDark,
                      index: index,
                      pages: pages,
                      pageController: pageController!,
                    )
                  else
                    _buildWideSubProjectArea(
                      context: context,
                      isDark: isDark,
                      subProjects: subProjects,
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                      index: index,
                      pages: widePages,
                      pageController: wideController,
                      enablePager: enableWidePager,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSubProjectPager({
    required BuildContext context,
    required bool isDark,
    required int index,
    required List<List<dynamic>> pages,
    required PageController pageController,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 122,
          child: PageView.builder(
            controller: pageController,
            itemCount: pages.length,
            onPageChanged: (page) {
              setState(() {
                _currentPageIndexes[index] = page;
              });
            },
            itemBuilder: (context, pageIdx) {
              final pageSubs = pages[pageIdx];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (slot) {
                  if (slot >= pageSubs.length) {
                    return const Expanded(child: SizedBox());
                  }
                  final sub = pageSubs[slot];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _buildSubProjectTile(
                        context: context,
                        isDark: isDark,
                        sub: sub,
                        isMobile: true,
                        isTablet: false,
                        isDesktop: false,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: pageController,
          count: pages.length,
          effect: WormEffect(
            dotColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            activeDotColor: isDark
                ? GlobalColors.primaryButtonDark
                : GlobalColors.primaryButtonLight,
            dotHeight: 8,
            dotWidth: 8,
            spacing: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildWideSubProjectArea({
    required BuildContext context,
    required bool isDark,
    required List<dynamic> subProjects,
    required bool isTablet,
    required bool isDesktop,
    required int index,
    required List<List<dynamic>> pages,
    required PageController? pageController,
    required bool enablePager,
  }) {
    if (!enablePager || pageController == null || pages.isEmpty) {
      return _buildWideSubProjectRow(
        context: context,
        isDark: isDark,
        subProjects: subProjects,
        isTablet: isTablet,
        isDesktop: isDesktop,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = isDesktop ? 18 : 15;
        final double tileWidth = isDesktop ? 180 : 163;
        final int visibleCount = math.min(8, subProjects.length);
        final double requiredWidth = visibleCount * tileWidth +
            (visibleCount > 1 ? (visibleCount - 1) * spacing : 0);

        if (!constraints.hasBoundedWidth ||
            constraints.maxWidth >= requiredWidth) {
          return _buildWideSubProjectPager(
            context: context,
            isDark: isDark,
            pages: pages,
            controller: pageController,
            index: index,
            isTablet: isTablet,
            isDesktop: isDesktop,
          );
        }

        return _buildWideSubProjectRow(
          context: context,
          isDark: isDark,
          subProjects: subProjects,
          isTablet: isTablet,
          isDesktop: isDesktop,
        );
      },
    );
  }

  Widget _buildWideSubProjectRow({
    required BuildContext context,
    required bool isDark,
    required List<dynamic> subProjects,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double spacing = isDesktop ? 18 : 15;
    final double tileWidth = isDesktop ? 180 : 163;
    final double tileHeight = isDesktop ? 138 : 130;

    return LayoutBuilder(
      builder: (context, constraints) {
        final int visibleCount = math.min(8, subProjects.length);
        final double desiredWidth = visibleCount * tileWidth +
            (visibleCount > 1 ? (visibleCount - 1) * spacing : 0);
        final double viewportWidth = constraints.maxWidth.isFinite
            ? math.min(constraints.maxWidth, desiredWidth)
            : desiredWidth;

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: tileHeight,
            width: viewportWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (int i = 0; i < subProjects.length; i++) ...[
                    SizedBox(
                      width: tileWidth,
                      child: _buildSubProjectTile(
                        context: context,
                        isDark: isDark,
                        sub: subProjects[i],
                        isMobile: false,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    ),
                    if (i != subProjects.length - 1) SizedBox(width: spacing),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideSubProjectPager({
    required BuildContext context,
    required bool isDark,
    required List<List<dynamic>> pages,
    required PageController controller,
    required int index,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double spacing = isDesktop ? 18 : 15;
    final double tileWidth = isDesktop ? 180 : 163;
    final double tileHeight = isDesktop ? 138 : 130;
    final int currentPage = _wideCurrentPageIndexes[index] ?? 0;

    return Column(
      children: [
        SizedBox(
          height: tileHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double viewportWidth = constraints.maxWidth;

              return Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: controller,
                    physics: const PageScrollPhysics(),
                    itemCount: pages.length,
                    onPageChanged: (page) {
                      setState(() {
                        _wideCurrentPageIndexes[index] = page;
                      });
                    },
                    itemBuilder: (context, pageIdx) {
                      final pageSubs = pages[pageIdx];
                      final double rowWidth = pageSubs.length * tileWidth +
                          (pageSubs.length > 1
                              ? (pageSubs.length - 1) * spacing
                              : 0);
                      final double effectiveWidth = viewportWidth.isFinite
                          ? math.min(viewportWidth, rowWidth)
                          : rowWidth;

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: effectiveWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              for (int i = 0; i < pageSubs.length; i++) ...[
                                SizedBox(
                                  width: tileWidth,
                                  child: _buildSubProjectTile(
                                    context: context,
                                    isDark: isDark,
                                    sub: pageSubs[i],
                                    isMobile: false,
                                    isTablet: isTablet,
                                    isDesktop: isDesktop,
                                  ),
                                ),
                                if (i != pageSubs.length - 1)
                                  SizedBox(width: spacing),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (pages.length > 1)
                    Positioned(
                      left: 0,
                      child: _buildPagerButton(
                        icon: Icons.chevron_left,
                        enabled: currentPage > 0,
                        isDark: isDark,
                        onPressed: currentPage > 0
                            ? () {
                                final target = currentPage - 1;
                                controller.animateToPage(
                                  target,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            : null,
                      ),
                    ),
                  if (pages.length > 1)
                    Positioned(
                      right: 0,
                      child: _buildPagerButton(
                        icon: Icons.chevron_right,
                        enabled: currentPage < pages.length - 1,
                        isDark: isDark,
                        onPressed: currentPage < pages.length - 1
                            ? () {
                                final target = currentPage + 1;
                                controller.animateToPage(
                                  target,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (pages.length > 1) ...[
          const SizedBox(height: 12),
          SmoothPageIndicator(
            controller: controller,
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
          ),
        ],
      ],
    );
  }

  Widget _buildPagerButton({
    required IconData icon,
    required bool enabled,
    required bool isDark,
    required VoidCallback? onPressed,
  }) {
    final Color backgroundColor = isDark
        ? GlobalColors.cardDarkBg.withOpacity(0.95)
        : Colors.white.withOpacity(0.9);
    final Color iconColor = enabled
        ? (isDark
            ? GlobalColors.primaryButtonDark
            : GlobalColors.primaryButtonLight)
        : Colors.grey;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: 36,
            width: 36,
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubProjectTile({
    required BuildContext context,
    required bool isDark,
    required dynamic sub,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double verticalPadding = isDesktop
        ? 15.5
        : isTablet
            ? 13.8
            : isMobile
                ? 11
                : 15;
    final double horizontalPadding = isDesktop
        ? 12.1
        : isTablet
            ? 10.5
            : isMobile
                ? 6
                : 11;
    final double iconSize = isDesktop
        ? 28.5
        : isTablet
            ? 26.0
            : isMobile
                ? 27
                : 29;
    final double titleSize = isDesktop
        ? 12.1
        : isTablet
            ? 11.0
            : isMobile
                ? 10.5
                : 12.0;
    final double statusSize = isDesktop
        ? 11.0
        : isTablet
            ? 9.9
            : 10.2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? GlobalColors.cardDarkBg.withOpacity(0.94)
            : Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark
              ? GlobalColors.primaryButtonDark.withOpacity(0.14)
              : GlobalColors.primaryButtonLight.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.06) : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (sub.subProjects.isNotEmpty) {
            Get.to(
              () => ProjectListPage(
                project: sub,
              ),
            );
          } else {
            Get.to(
              () => buildProjectScreen(sub),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sub.icon ?? Icons.widgets,
              size: iconSize,
              color: isDark
                  ? GlobalColors.primaryButtonDark
                  : GlobalColors.primaryButtonLight,
            ),
            const SizedBox(height: 6),
            Text(
              getCardLabel(context, sub.name),
              style: GlobalTextStyles.bodySmall(
                isDark: isDark,
              ).copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? GlobalColors.darkPrimaryText
                    : GlobalColors.lightPrimaryText,
                fontSize: titleSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (sub.status.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                getStatusText(context, sub.status),
                style: GlobalTextStyles.bodySmall(
                  isDark: isDark,
                ).copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: statusSize,
                  color: isDark
                      ? GlobalColors.primaryButtonDark
                      : GlobalColors.primaryButtonLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
