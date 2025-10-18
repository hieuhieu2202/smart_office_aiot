import 'dart:math' as math;

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
            body: Container(
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
                          Colors.grey[100]!.withOpacity(0.9),
                          Colors.blue[100]!.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
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
        final double maxWidthLimit = isDesktop ? 1600 : 900;
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
    final PageController? pageController = isMobile
        ? _pageControllers.putIfAbsent(index, () => PageController())
        : null;
    final double cardPadding = isDesktop
        ? 26
        : isTablet
            ? 22
            : 18;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          project.icon ?? Icons.dashboard,
          size: isDesktop
              ? 40
              : isTablet
                  ? 36
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
                  ? 21
                  : isTablet
                      ? 20
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

    return Card(
      elevation: 3,
      color: isDark
          ? GlobalColors.cardDarkBg
          : Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
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
              _buildWideSubProjectWrap(
                context: context,
                isDark: isDark,
                subProjects: subProjects,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
          ],
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

  Widget _buildWideSubProjectWrap({
    required BuildContext context,
    required bool isDark,
    required List<dynamic> subProjects,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double spacing = isDesktop ? 18 : 16;
    final double tileWidth = isDesktop ? 190 : 176;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
        ? 18
        : isTablet
            ? 16
            : isMobile
                ? 11
                : 14;
    final double horizontalPadding = isDesktop
        ? 14
        : isTablet
            ? 12
            : isMobile
                ? 6
                : 10;
    final double iconSize = isDesktop
        ? 32
        : isTablet
            ? 30
            : isMobile
                ? 27
                : 28;
    final double titleSize = isDesktop
        ? 14
        : isTablet
            ? 12.5
            : isMobile
                ? 10.5
                : 11.5;
    final double statusSize = isDesktop
        ? 12.5
        : isTablet
            ? 11.2
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
