part of 'stencil_monitor_screen.dart';

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
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF05142B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
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
                  style: GoogleFonts.robotoMono(
                    color: Colors.cyanAccent.withOpacity(0.8),
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: value,
                  dropdownColor: const Color(0xFF071B30),
                  icon: const Icon(Icons.expand_more, color: Colors.cyanAccent),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.cyanAccent.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.cyanAccent,
                        width: 1.4,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
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
                  Text(
                    'FILTERS',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildDropdown(
                label: 'Customer',
                value: effectiveCustomer,
                options: customerOptions,
                onChanged: controller.selectCustomer,
              ),
              const SizedBox(height: 16),
              buildDropdown(
                label: 'Factory',
                value: effectiveFloor,
                options: floorOptions,
                onChanged: controller.selectFloor,
              ),
              const SizedBox(height: 20),
              Text(
                'Records matched: $activeCount',
                style: GoogleFonts.robotoMono(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyanAccent,
                      side: BorderSide(color: Colors.cyanAccent.withOpacity(0.6)),
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
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.blueGrey[900],
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
          );
        }),
      ),
    );
  }
}
