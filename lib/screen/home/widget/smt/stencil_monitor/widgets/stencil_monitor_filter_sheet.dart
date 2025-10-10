part of 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({required this.controller});

  final StencilMonitorController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filters',
      icon: const Icon(Icons.filter_alt_outlined),
      onPressed: () => _openFilterSheet(context),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Stencil Filters',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        final screenWidth = MediaQuery.of(ctx).size.width;
        final sheetWidth = screenWidth < 420 ? screenWidth * 0.9 : 360.0;

        return SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
              child: SizedBox(
                width: sheetWidth,
                child: _FilterSheetCard(
                  controller: controller,
                  onClose: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }
}

class _FilterSheetCard extends StatelessWidget {
  const _FilterSheetCard({
    required this.controller,
    required this.onClose,
  });

  final StencilMonitorController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    final isDark = palette.isDark;
    final fieldFill = isDark
        ? GlobalColors.inputDarkFill
        : GlobalColors.inputLightFill;
    final dropdownColor = isDark
        ? GlobalColors.cardDark
        : GlobalColors.cardLight;
    final accent = palette.accentPrimary;
    final borderColor = palette.dividerColor.withOpacity(isDark ? 0.4 : 0.6);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadow,
              blurRadius: 28,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Obx(() {
          final customers = controller.customers.toList(growable: false);
          final floors = controller.floors.toList(growable: false);
          final customerOptions = customers.isEmpty ? <String>['ALL'] : customers;
          final floorOptions = floors.isEmpty ? <String>['ALL'] : floors;
          final selectedCustomer = controller.selectedCustomer.value;
          final selectedFloor = controller.selectedFloor.value;
          final activeCount = controller.filteredData.length;

          String ensureValue(List<String> values, String value) {
            if (values.isEmpty) {
              return 'ALL';
            }
            return values.contains(value) ? value : values.first;
          }

          final effectiveCustomer = ensureValue(customerOptions, selectedCustomer);
          final effectiveFloor = ensureValue(floorOptions, selectedFloor);

          Widget buildDropdown({
            required String label,
            required String value,
            required List<String> options,
            required ValueChanged<String> onChanged,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                    fontFamily: GoogleFonts.robotoMono().fontFamily,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: value,
                  dropdownColor: dropdownColor,
                  icon: Icon(Icons.expand_more, color: accent),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: accent.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: accent, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                    fontFamily: GoogleFonts.robotoMono().fontFamily,
                    color: palette.onSurface,
                    fontSize: 13,
                  ),
                  items: options
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onChanged(value);
                    }
                  },
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'FILTERS',
                      style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                        fontFamily: GoogleFonts.orbitron().fontFamily,
                        fontSize: 16,
                        letterSpacing: 1.1,
                        color: accent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: palette.onSurfaceMuted),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDropdown(
                      label: 'Customer',
                      value: effectiveCustomer,
                      options: customerOptions,
                      onChanged: controller.selectCustomer,
                    ),
                    const SizedBox(height: 18),
                    buildDropdown(
                      label: 'Factory',
                      value: effectiveFloor,
                      options: floorOptions,
                      onChanged: controller.selectFloor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Records matched: $activeCount',
                      style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                        color: palette.onSurfaceMuted,
                        fontFamily: GoogleFonts.robotoMono().fontFamily,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent.withOpacity(0.6)),
                          ),
                          onPressed: () {
                            controller.selectCustomer('ALL');
                            controller.selectFloor('ALL');
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor:
                                  isDark ? GlobalColors.darkBackground : Colors.white,
                            ),
                            onPressed: () async {
                              await controller.refresh();
                              onClose();
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
