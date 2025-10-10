part of 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';

class _StencilColorScheme {
  _StencilColorScheme._(this.theme);

  final ThemeData theme;

  Brightness get brightness => theme.brightness;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceMuted =>
      onSurface.withOpacity(brightness == Brightness.dark ? 0.68 : 0.62);
  List<Color> get backgroundGradient => brightness == Brightness.dark
      ? const [Color(0xFF040B1E), Color(0xFF061F3C)]
      : const [Color(0xFFF4F7FF), Color(0xFFFFFFFF)];
  Color get cardBackground =>
      brightness == Brightness.dark ? const Color(0xFF05142B) : Colors.white;
  Color get cardShadow =>
      brightness == Brightness.dark ? Colors.black.withOpacity(0.45) : Colors.black12;
  Color get surfaceOverlay => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.06)
      : const Color(0xFFF0F4FF);
  Color get dividerColor =>
      brightness == Brightness.dark ? Colors.white12 : Colors.black12;
  Color get errorFill =>
      brightness == Brightness.dark ? const Color(0x26FF5252) : const Color(0x1AFF5252);
  Color get errorBorder =>
      brightness == Brightness.dark ? const Color(0x80FF5252) : const Color(0x59FF5252);
  Color get errorText =>
      brightness == Brightness.dark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F);

  static _StencilColorScheme of(BuildContext context) =>
      _StencilColorScheme._(Theme.of(context));
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
                  style: GoogleFonts.orbitron(
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
                    style: GoogleFonts.orbitron(
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.robotoMono(
                color: (accent ?? palette.onSurface).withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                color: palette.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
