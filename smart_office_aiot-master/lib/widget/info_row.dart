import 'package:flutter/material.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDarkMode;
  final IconData? icon;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.isDarkMode,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(
              icon,
              color:
                  isDarkMode
                      ? GlobalColors.primaryButtonDark
                      : GlobalColors.primaryButtonLight,
              size: 20,
            ),
          ),
        Flexible(
          flex: 1,
          child: Text(
            label,
            style: GlobalTextStyles.bodyMedium(isDark: isDarkMode).copyWith(
              color:
                  isDarkMode
                      ? GlobalColors.darkPrimaryText
                      : GlobalColors.lightPrimaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: GlobalTextStyles.bodyMedium(isDark: isDarkMode).copyWith(
              color:
                  isDarkMode ? GlobalColors.labelDark : GlobalColors.labelLight,
            ),
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
