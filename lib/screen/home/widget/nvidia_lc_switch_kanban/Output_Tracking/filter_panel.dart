import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/nvidia_lc_switch_kanban_controller.dart';

class OtFilterPanel extends StatefulWidget {
  const OtFilterPanel({super.key});
  @override
  State<OtFilterPanel> createState() => _OtFilterPanelState();
}

class _OtFilterPanelState extends State<OtFilterPanel> {
  late DateTime _date;
  String _shift = 'Day';
  final Set<String> _selected = <String>{};
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = Get.find<KanbanController>();
    _date = c.date.value;
    _shift = c.shift.value;
    _selected..clear()..addAll(c.groups);
    // không gọi force ở đây để tránh 2 lần; sẽ force ngay trước khi mở picker
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final c = Get.find<KanbanController>();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            _dateField(context, 'Date', _date, () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: _date,
              );
              if (d != null) setState(() => _date = d);
            }),

            DropdownButtonFormField<String>(
              value: _shift,
              decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Day', child: Text('Day')),
                DropdownMenuItem(value: 'Night', child: Text('Night')),
              ],
              onChanged: (v) => setState(() => _shift = v ?? 'Day'),
            ),

            Obx(() {
              if (c.isLoadingModels.value) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ));
              }
              return InkWell(
                onTap: () async {
                  // ✅ ÉP gọi API lấy danh sách models trước khi mở picker
                  await c.ensureModels(force: true);
                  await _openModelPicker(context, c);
                  setState(() {});
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Models',
                    border: OutlineInputBorder(),
                  ),
                  child: Text('Selected: ${_selected.length}'),
                ),
              );
            }),

            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Get.snackbar('Export', 'Đang chuẩn bị export (TODO)');
                    },
                    icon: const Icon(Icons.file_download),
                    label: const Text('EXPORT EXCEL'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'date': _date,
                        'shift': _shift,
                        'groups': _selected.toList(),
                      });
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('QUERY'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(BuildContext ctx, String label, DateTime d, VoidCallback onPick) {
    final s = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: 'Pick date',
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: onPick,
        ),
      ),
      controller: TextEditingController(text: s),
      onTap: onPick,
    );
  }

  Future<void> _openModelPicker(BuildContext context, KanbanController c) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Obx(() {
            final all = c.allModels;
            final filtered = all
                .where((m) => m.toLowerCase().contains(_searchCtl.text.toLowerCase()))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
              builder: (ctx, scrollCtrl) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('SELECTED: ${_selected.length}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () { _selected..clear()..addAll(all); setState(() {}); },
                            child: const Text('Select All'),
                          ),
                          TextButton(
                            onPressed: () { _selected.clear(); setState(() {}); },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchCtl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final m = filtered[i];
                            final checked = _selected.contains(m);
                            return CheckboxListTile(
                              title: Text(m),
                              value: checked,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) _selected.add(m);
                                  else _selected.remove(m);
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
                          const SizedBox(width: 8),
                          Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
