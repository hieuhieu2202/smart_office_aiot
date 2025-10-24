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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === LABEL + VALUE ===
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tên Model
              Expanded(
                child: Text(
                  widget.modelName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: widget.isMobile ? 13 : 14,
                  ),
                ),
              ),

              // Badge Qty
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isMobile ? 8 : 10,
                  vertical: widget.isMobile ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: barColors.last.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: barColors.last.withOpacity(.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Text(
                  '${widget.qty}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isMobile ? 13 : 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // === ANIMATED FILL BAR ===
          LayoutBuilder(builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            return AnimatedBuilder(
              animation: _fillCtrl,
              builder: (_, __) {
                final animatedRatio = ratio * _fillCtrl.value;
                return Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      width: animatedRatio * maxW,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: barColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: barColors.last.withOpacity(.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
