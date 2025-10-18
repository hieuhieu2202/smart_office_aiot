import 'package:auto_size_text/auto_size_text.dart';
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
          final DeviceScreenType type = sizingInfo.deviceScreenType;
          final bool isMobile = type == DeviceScreenType.mobile;
          final bool isTablet = type == DeviceScreenType.tablet;
          final bool isDesktop = type == DeviceScreenType.desktop;
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
          final int crossAxisCount = isMobile
              ? 1
              : isTablet
                  ? 2
                  : sizingInfo.screenSize.width >= 1600
                      ? 4
                      : 3;

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
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isMobile
                    ? _buildMobileList(
                        isDark: isDark,
                        text: text,
                        padding: contentPadding,
                      )
                    : _buildWideGrid(
                        isDark: isDark,
                        text: text,
                        padding: contentPadding,
                        crossAxisCount: crossAxisCount,
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
      key: const ValueKey('mobile-list'),
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

  Widget _buildWideGrid({
    required bool isDark,
    required S text,
    required EdgeInsets padding,
    required int crossAxisCount,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double spacing = isDesktop ? 32 : 24;
    final double aspectRatio = isDesktop ? 1.4 : 1.25;
    return GridView.builder(
      key: ValueKey('grid-$crossAxisCount'),
      padding: padding,
      physics: const BouncingScrollPhysics(),
      itemCount: homeController.projects.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, idx) {
        final project = homeController.projects[idx];
        return _buildProjectCard(
          context: context,
          isDark: isDark,
          text: text,
          project: project,
          index: idx,
          isMobile: false,
          isTablet: isTablet,
          isDesktop: isDesktop,
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
    final subProjects = project.subProjects;
    final pages = chunk(subProjects, 4);
    final initialPage = _currentPageIndexes[index] ?? 0;
    final pageController = _pageControllers.putIfAbsent(
      index,
      () => PageController(initialPage: initialPage),
    );
    final double headerSpacing = isMobile ? 18 : 22;
    final double iconSize = isMobile ? 36 : 42;
    final double cardPadding = isDesktop
        ? 26
        : isTablet
            ? 22
            : 18;

    return Card(
      elevation: isDesktop ? 6 : 4,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.35)
          : Colors.blueGrey.withOpacity(0.18),
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark
              ? GlobalColors.cardDarkBg.withOpacity(isMobile ? 0.98 : 0.94)
              : Colors.white.withOpacity(isDesktop ? 0.78 : 0.9),
          border: Border.all(
            color: isDark
                ? GlobalColors.primaryButtonDark.withOpacity(0.16)
                : GlobalColors.primaryButtonLight.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.28)
                  : Colors.blueGrey.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: iconSize,
                  width: iconSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: (isDark
                            ? GlobalColors.primaryButtonDark
                            : GlobalColors.primaryButtonLight)
                        .withOpacity(0.12),
                  ),
                  child: FittedBox(
                    child: Icon(
                      project.icon ?? Icons.dashboard,
                      color: isDark
                          ? GlobalColors.primaryButtonDark
                          : GlobalColors.primaryButtonLight,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        getModuleLabel(context, project.name),
                        style: GlobalTextStyles.bodyLarge(
                          isDark: isDark,
                        ).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                        maxLines: 1,
                        minFontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? GlobalColors.primaryButtonDark
                                  .withOpacity(0.16)
                              : GlobalColors.primaryButtonLight
                                  .withOpacity(0.11),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AutoSizeText(
                          getStatusText(context, project.status),
                          style: GlobalTextStyles.bodySmall(
                            isDark: isDark,
                          ).copyWith(
                            color: isDark
                                ? GlobalColors.primaryButtonDark
                                : GlobalColors.primaryButtonLight,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          minFontSize: 11,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: headerSpacing),
            subProjects.isEmpty
                ? Padding(
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
                : isMobile
                    ? Column(
                        children: [
                          SizedBox(
                            height: isMobile ? 130 : 140,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(4, (i) {
                                    if (i >= pageSubs.length) {
                                      return const Expanded(
                                        child: SizedBox.shrink(),
                                      );
                                    }
                                    final sub = pageSubs[i];
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
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
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final int wrapCount = isDesktop
                              ? (constraints.maxWidth >= 1400 ? 4 : 3)
                              : 2;
                          final double spacing = isDesktop ? 20 : 16;
                          final double tileWidth = (constraints.maxWidth -
                                  spacing * (wrapCount - 1)) /
                              wrapCount;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: subProjects.map<Widget>((sub) {
                              return SizedBox(
                                width: tileWidth.clamp(180.0, 320.0),
                                child: _buildSubProjectTile(
                                  context: context,
                                  isDark: isDark,
                                  sub: sub,
                                  isMobile: false,
                                  isTablet: isTablet,
                                  isDesktop: isDesktop,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
          ],
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
        ? 18
        : isTablet
            ? 16
            : 12;
    final double horizontalPadding = isDesktop
        ? 14
        : isTablet
            ? 12
            : 8;
    final double iconSize = isDesktop
        ? 36
        : isTablet
            ? 32
            : 28;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? GlobalColors.cardDarkBg.withOpacity(0.94)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? GlobalColors.primaryButtonDark.withOpacity(0.14)
              : GlobalColors.primaryButtonLight.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.18)
                : Colors.blueGrey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (sub.subProjects.isNotEmpty) {
              Get.to(
                () => ProjectListPage(
                  project: sub,
                ),
              );
            } else {
              Get.to(() => buildProjectScreen(sub));
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                sub.icon ?? Icons.widgets,
                size: iconSize,
                color: isDark
                    ? GlobalColors.primaryButtonDark
                    : GlobalColors.primaryButtonLight,
              ),
              const SizedBox(height: 8),
              AutoSizeText(
                getCardLabel(context, sub.name),
                style: GlobalTextStyles.bodySmall(
                  isDark: isDark,
                ).copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? GlobalColors.darkPrimaryText
                      : GlobalColors.lightPrimaryText,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                minFontSize: 11,
              ),
              if (sub.status.isNotEmpty) ...[
                const SizedBox(height: 4),
                AutoSizeText(
                  getStatusText(context, sub.status),
                  style: GlobalTextStyles.bodySmall(
                    isDark: isDark,
                  ).copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? GlobalColors.primaryButtonDark
                        : GlobalColors.primaryButtonLight,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
