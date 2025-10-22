part of 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';

class _StencilColorScheme {
  _StencilColorScheme._(this.theme);

  final ThemeData theme;

  Brightness get brightness => theme.brightness;
  bool get isDark => brightness == Brightness.dark;

  Color get onSurface =>
      isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
  Color get onSurfaceMuted =>
      isDark ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText;
  List<Color> get backgroundGradient => isDark
      ? [GlobalColors.bgDark, GlobalColors.darkBackground]
      : [GlobalColors.bgLight, GlobalColors.lightBackground];
  Color get cardBackground =>
      isDark ? GlobalColors.cardDark : GlobalColors.cardLight;
  Color get cardShadow =>
      isDark ? GlobalColors.shadowDark : GlobalColors.shadowLight;
  Color get surfaceOverlay =>
      isDark ? GlobalColors.inputDarkFill : GlobalColors.inputLightFill;
  Color get dividerColor =>
      isDark ? GlobalColors.borderDark : GlobalColors.borderLight;
  Color get accentPrimary => GlobalColors.accentByIsDark(isDark);
  Color get accentSecondary =>
      isDark ? GlobalColors.gradientDarkEnd : GlobalColors.gradientLightEnd;
  Color get tooltipBackground =>
      isDark ? GlobalColors.tooltipBgDark : GlobalColors.tooltipBgLight;
  Color get chipBackground =>
      isDark ? GlobalColors.slotBgDark : GlobalColors.slotBgLight;
  Color get errorFill =>
      isDark ? const Color(0x26FF5252) : const Color(0x1AFF5252);
  Color get errorBorder =>
      isDark ? const Color(0x80FF5252) : const Color(0x59FF5252);
  Color get errorText =>
      isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F);

  static _StencilColorScheme of(BuildContext context) =>
      _StencilColorScheme._(Theme.of(context));
}

class _StencilTypography {
  _StencilTypography._();

  static const String heading = 'SpaceGrotesk';
  static const String body = 'IBMPlexSans';
  static const String numeric = 'IBMPlexMono';
}


class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.title,
    required this.child,
    required this.accent,
    this.action,
  });

  final String title;
  final Widget child;
  final Color accent;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.45)),
        color: palette.cardBackground,
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.14), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GlobalTextStyles.bodyMedium(isDark: palette.isDark)
                      .copyWith(
                    fontFamily: _StencilTypography.heading,
                    color: accent,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetailSheetContainer extends StatelessWidget {
  const _DetailSheetContainer({
    required this.title,
    required this.child,
    this.controller,
  });

  final String title;
  final Widget child;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: palette.onSurfaceMuted.withOpacity(0.25),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                child: Text(
                  title,
                  style: GlobalTextStyles.bodyMedium(isDark: palette.isDark)
                      .copyWith(
                      fontFamily: _StencilTypography.heading,
                      color: palette.onSurface,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: palette.onSurfaceMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Material(
                color: palette.cardBackground,
                child: controller == null
                    ? child
                    : PrimaryScrollController(
                        controller: controller!,
                        child: child,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

