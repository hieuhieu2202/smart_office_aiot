import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rack_left_panel.dart' show RackStatusLegendBar;

class RackHeaderDelegate extends SliverPersistentHeaderDelegate {
  const RackHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant RackHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class RackPinnedHeader extends StatelessWidget {
  const RackPinnedHeader({
    required this.controller,
    required this.total,
    required this.online,
    required this.offline,
    super.key,
  });

  final TabController controller;
  final int total;
  final int online;
  final int offline;

  static double estimateHeight({
    required BuildContext context,
    required double maxWidth,
  }) {
    final tabHeight = RackTabSelector.estimateHeight(context);
    final legendMaxWidth = math.max(0.0, maxWidth - 24); // trừ padding ngang của header
    final legendHeight = RackStatusLegendBar.estimateHeight(
      context: context,
      maxWidth: legendMaxWidth,
    );

    // padding: top=10, bottom=12, legend margin top=12, cộng thêm buffer nhỏ để
    // bù sai số khi text scale lớn khiến legend wrap thành nhiều dòng.
    return tabHeight + legendHeight + 10 + 12 + 12 + 8;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.colorScheme.surface,
      elevation: isDark ? 4 : 2,
      shadowColor: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RackTabSelector(
              controller: controller,
              total: total,
              online: online,
              offline: offline,
            ),
            const RackStatusLegendBar(
              margin: EdgeInsets.only(top: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class RackTabSelector extends StatelessWidget {
  const RackTabSelector({
    required this.controller,
    required this.total,
    required this.online,
    required this.offline,
    super.key,
  });

  final TabController controller;
  final int total;
  final int online;
  final int offline;

  static double estimateHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final textScale = mediaQuery.textScaleFactor;

    final labelStyle = (theme.textTheme.labelMedium ?? const TextStyle())
        .copyWith(fontWeight: FontWeight.w700);
    final countStyle = (theme.textTheme.labelSmall ?? const TextStyle())
        .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2);

    final labelPainter = TextPainter(
      text: TextSpan(text: 'Offline', style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaleFactor: textScale,
    )..layout();

    final countPainter = TextPainter(
      text: TextSpan(text: '000', style: countStyle),
      textDirection: TextDirection.ltr,
      textScaleFactor: textScale,
    )..layout();

    final badgeHeight = countPainter.height + 8; // vertical padding 4 top & bottom
    final rowContentHeight = math.max(16, math.max(labelPainter.height, badgeHeight));
    final chipHeight = rowContentHeight + 16; // chip padding vertical 8
    const containerPadding = 12; // vertical padding 6 top & bottom

    return chipHeight + containerPadding + 2; // small epsilon for rounding
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tabs = [
      _RackTabData(
        label: 'All',
        count: total,
        icon: Icons.apps_rounded,
        color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
      ),
      _RackTabData(
        label: 'Online',
        count: online,
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF20C25D),
      ),
      _RackTabData(
        label: 'Offline',
        count: offline,
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFFE53935),
      ),
    ];

    final activeIndex = controller.index;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2233) : const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final fitsWithinWidth = maxWidth.isFinite &&
              _estimateChipRowWidth(context, tabs) <= maxWidth + 0.1;

          if (fitsWithinWidth) {
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  _RackTabChip(
                    data: tabs[i],
                    selected: activeIndex == i,
                    onTap: () => controller.animateTo(i),
                  ),
              ],
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    _RackTabChip(
                      data: tabs[i],
                      selected: activeIndex == i,
                      onTap: () => controller.animateTo(i),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RackTabData {
  const _RackTabData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _RackTabChip extends StatelessWidget {
  const _RackTabChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _RackTabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        selected ? data.color : theme.colorScheme.onSurface.withOpacity(0.65);
    final bgColor = selected
        ? data.color.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.16)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? data.color.withOpacity(0.45)
                  : theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                data.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(selected ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${data.count}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _estimateChipRowWidth(BuildContext context, List<_RackTabData> tabs) {
  final mediaQuery = MediaQuery.of(context);
  final theme = Theme.of(context);
  final textScale = mediaQuery.textScaleFactor;

  final labelStyle = (theme.textTheme.labelMedium ?? const TextStyle())
      .copyWith(fontWeight: FontWeight.w700);
  final countStyle = (theme.textTheme.labelSmall ?? const TextStyle())
      .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2);

  double totalWidth = 0;
  for (final tab in tabs) {
    totalWidth += _estimateChipWidth(
      label: tab.label,
      count: tab.count,
      labelStyle: labelStyle,
      countStyle: countStyle,
      textScale: textScale,
    );
  }

  return totalWidth;
}

double _estimateChipWidth({
  required String label,
  required int count,
  required TextStyle labelStyle,
  required TextStyle countStyle,
  required double textScale,
}) {
  final labelPainter = TextPainter(
    text: TextSpan(text: label, style: labelStyle),
    textDirection: TextDirection.ltr,
    textScaleFactor: textScale,
  )..layout();

  final countPainter = TextPainter(
    text: TextSpan(text: '$count', style: countStyle),
    textDirection: TextDirection.ltr,
    textScaleFactor: textScale,
  )..layout();

  const outerPadding = 8.0; // tổng padding ngang của widget cha
  const chipHorizontalPadding = 28.0; // padding trong AnimatedContainer (14 * 2)
  const iconWidth = 16.0;
  const gapIconToLabel = 6.0;
  const gapLabelToBadge = 6.0;
  const badgeHorizontalPadding = 16.0; // padding trong badge (8 * 2)

  return outerPadding +
      chipHorizontalPadding +
      iconWidth +
      gapIconToLabel +
      labelPainter.width +
      gapLabelToBadge +
      badgeHorizontalPadding +
      countPainter.width;
}
