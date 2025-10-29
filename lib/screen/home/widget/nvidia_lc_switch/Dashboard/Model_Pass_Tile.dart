import 'package:flutter/material.dart';

class ModelPassTile extends StatefulWidget {
  final String modelName;
  final int qty;
  final int maxQty;
  final int colorIndex;
  final bool isMobile;

  const ModelPassTile({
    super.key,
    required this.modelName,
    required this.qty,
    required this.maxQty,
    this.colorIndex = 0,
    this.isMobile = false,
  });

  @override
  State<ModelPassTile> createState() => _ModelPassTileState();
}

class _ModelPassTileState extends State<ModelPassTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fillCtrl;

  @override
  void initState() {
    super.initState();
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1E2D);

    // gradient theo index
    final gradients = [
      [Colors.cyanAccent, Colors.blueAccent],
      [Colors.purpleAccent, Colors.deepPurpleAccent],
      [Colors.lightGreenAccent, Colors.greenAccent],
      [Colors.orangeAccent, Colors.deepOrangeAccent],
      [Colors.pinkAccent, Colors.redAccent],
    ];

    final barColors = gradients[widget.colorIndex % gradients.length];
    final ratio = widget.maxQty == 0 ? 0.0 : widget.qty / widget.maxQty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : screenWidth;
        final safeWidth = availableWidth.isFinite && availableWidth > 0
            ? availableWidth
            : screenWidth;

        final isCompact = safeWidth < 280;
        final isUltraCompact = safeWidth < 230;

        final nameFontSize = isUltraCompact
            ? 12.0
            : isCompact || widget.isMobile
                ? 13.0
                : 14.0;
        final qtyFontSize = isUltraCompact
            ? 11.5
            : isCompact
                ? 12.5
                : widget.isMobile
                    ? 13.0
                    : 15.0;
        final badgeHorizontal = isUltraCompact
            ? 6.0
            : isCompact
                ? 8.0
                : widget.isMobile
                    ? 8.0
                    : 10.0;
        final badgeVertical = isUltraCompact
            ? 4.0
            : isCompact
                ? 4.5
                : widget.isMobile
                    ? 5.0
                    : 6.0;
        final progressHeight = isUltraCompact
            ? 7.0
            : isCompact
                ? 8.0
                : 10.0;
        final verticalSpacing = isUltraCompact ? 4.0 : isCompact ? 5.0 : 6.0;
        final tilePadding = isUltraCompact ? 6.0 : isCompact ? 7.0 : 8.0;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: tilePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.modelName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: nameFontSize,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: EdgeInsets.symmetric(
                      horizontal: badgeHorizontal,
                      vertical: badgeVertical,
                    ),
                    decoration: BoxDecoration(
                      color: barColors.last.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: barColors.last.withOpacity(.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.qty}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: qtyFontSize,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
              AnimatedBuilder(
                animation: _fillCtrl,
                builder: (_, __) {
                  final animatedRatio = ratio * _fillCtrl.value;
                  final fillWidth = safeWidth * animatedRatio;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(progressHeight / 2),
                    child: Stack(
                      children: [
                        Container(
                          height: progressHeight,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: fillWidth,
                            height: progressHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: barColors,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: barColors.last.withOpacity(.35),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
