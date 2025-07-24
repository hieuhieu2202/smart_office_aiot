import 'package:flutter/material.dart';
import '../../../../config/global_color.dart';

class RackCard extends StatelessWidget {
  final String rackName;
  final String modelName;
  final int totalPass;
  final double yr;
  final double ut;
  final List<Map<String, dynamic>> slots;
  final bool isInactive;
  final Animation<double> animation;
  final Animation<double> slotAnimation;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;
  final bool isDark;

  const RackCard({
    super.key,
    required this.rackName,
    required this.modelName,
    required this.totalPass,
    required this.yr,
    required this.ut,
    required this.slots,
    required this.isInactive,
    required this.animation,
    required this.slotAnimation,
    required this.getStatusColor,
    required this.getStatusIcon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorDot = isInactive
        ? (isDark ? Colors.grey : Colors.grey[400])
        : (isDark ? GlobalColors.iconDark : GlobalColors.iconLight);

    final borderColor = isDark
        ? GlobalColors.borderDark.withOpacity(0.13)
        : GlobalColors.borderLight.withOpacity(0.15);

    final cardBg = isInactive
        ? (isDark ? Colors.grey.shade900 : Colors.grey[100])
        : (isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg);

    final passTextColor = isDark ? GlobalColors.iconDark : GlobalColors.iconLight;
    final rackTextColor = isDark ? GlobalColors.iconDark : GlobalColors.iconLight;
    final modelTextColor = isDark
        ? GlobalColors.darkSecondaryText
        : GlobalColors.lightSecondaryText;
    final progressBg = isDark
        ? Colors.blueGrey[800]!.withOpacity(0.18)
        : Colors.blueGrey[100]!.withOpacity(0.45);

    final utColor = isDark ? Colors.blueAccent : GlobalColors.labelLight;
    final yrColor = isDark ? GlobalColors.iconDark : GlobalColors.iconLight;

    final slotTextColor = isDark ? Colors.white : GlobalColors.lightPrimaryText;
    final slotProgressBg = isDark
        ? Colors.blueGrey[700]!.withOpacity(0.23)
        : Colors.blue[100]!.withOpacity(0.3);
    final slotPassBg = isDark
        ? GlobalColors.iconDark.withOpacity(0.18)
        : GlobalColors.iconLight.withOpacity(0.09);

    final tooltipBg = isDark ? Colors.blueGrey[900]?.withOpacity(0.96) : Colors.white;
    final tooltipBorder = isDark
        ? GlobalColors.iconDark.withOpacity(0.28)
        : GlobalColors.iconLight.withOpacity(0.18);
    final tooltipText = isDark ? GlobalColors.iconDark : GlobalColors.iconLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? GlobalColors.iconDark.withOpacity(0.07)
                : GlobalColors.iconLight.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.circle, size: 13, color: colorDot),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$rackName\n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rackTextColor,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: modelName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: modelTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '$totalPass pcs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: passTextColor,
                  fontSize: 15,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // YR Progress
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final animatedValue = animation.value * ((yr).clamp(0, 100) / 100);
              return LinearProgressIndicator(
                value: isInactive ? ((yr).clamp(0, 100) / 100) : animatedValue,
                minHeight: 6,
                backgroundColor: progressBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isInactive
                      ? Colors.grey
                      : (isDark ? GlobalColors.iconDark : GlobalColors.iconLight),
                ),
              );
            },
          ),

          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UT: ${ut.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: utColor)),
              Text('YR: ${yr.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: yrColor)),
            ],
          ),
          const SizedBox(height: 11),

          // Slots
          Flexible(
            child: GridView.builder(
              itemCount: slots.length,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, i) {
                final slot = slots[i];
                final slotName = slot['SlotName'] ?? '';
                final slotNumber = slot['SlotNumber']?.toString() ?? (i + 1).toString();
                final slotPass = slot['Total_Pass'] ?? 0;
                final slotFail = slot['Fail'] ?? 0;
                final slotYr = slot['YR'] ?? 0;
                final status = slot['Status'] ?? '';
                final color = getStatusColor(status);

                return AnimatedBuilder(
                  animation: slotAnimation,
                  builder: (context, child) {
                    final opacity = 0.6 + (slotAnimation.value * 0.4);
                    return Opacity(
                      opacity: opacity,
                      child: child,
                    );
                  },
                  child: Tooltip(
                    message: status,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tooltipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tooltipBorder, width: 1.1),
                    ),
                    textStyle: TextStyle(
                      fontSize: 13,
                      color: tooltipText,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blueGrey[800]!.withOpacity(0.95) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withOpacity(0.20),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(getStatusIcon(status), color: color, size: 15),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '$slotName-$slotNumber',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: slotTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${slotYr.toString()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? GlobalColors.iconDark : GlobalColors.iconLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (slotYr is num ? slotYr.clamp(0, 100) : 0) / 100,
                                    minHeight: 5,
                                    backgroundColor: slotProgressBg,
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: slotPassBg,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '$slotPass/${slotPass + slotFail}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: slotTextColor,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
