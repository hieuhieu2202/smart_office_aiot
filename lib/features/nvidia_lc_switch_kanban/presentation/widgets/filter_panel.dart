import 'package:flutter/material.dart';

Future<Set<String>?> showOtModelPicker({
  required BuildContext context,
  required List<String> allModels,
  required Set<String> initialSelection,
}) {
  final sorted = allModels.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _OtModelPickerSheet(
        allModels: sorted,
        initialSelection: initialSelection,
      );
    },
  );
}

class _OtModelPickerSheet extends StatefulWidget {
  const _OtModelPickerSheet({
    required this.allModels,
    required this.initialSelection,
  });

  final List<String> allModels;
  final Set<String> initialSelection;

  @override
  State<_OtModelPickerSheet> createState() => _OtModelPickerSheetState();
}

class _OtModelPickerSheetState extends State<_OtModelPickerSheet> {
  late final TextEditingController _searchCtl;
  late Set<String> _selection;

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController();
    _selection = Set<String>.from(widget.initialSelection);
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) {
          final filtered = widget.allModels
              .where((m) => m.toLowerCase().contains(_searchCtl.text.toLowerCase()))
              .toList();

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Models',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selected: ${_selection.length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _selection.length == widget.allModels.length
                            ? null
                            : () {
                                setState(() {
                                  _selection = widget.allModels.toSet();
                                });
                              },
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: _selection.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _selection.clear();
                                });
                              },
                        child: const Text('Clear'),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchCtl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search model...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No model found',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final model = filtered[i];
                            final checked = _selection.contains(model);
                            return CheckboxListTile(
                              title: Text(model),
                              value: checked,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selection.add(model);
                                  } else {
                                    _selection.remove(model);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(_selection),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
