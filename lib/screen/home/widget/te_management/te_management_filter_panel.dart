import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TEManagementFilterPanel extends StatefulWidget {
  final bool show;
  final DateTime start;
  final DateTime end;
  final String modelSerial;
  final String model;
  final void Function(DateTime start, DateTime end, String modelSerial, String model) onApply;
  final VoidCallback onClose;
  final bool isDark;

  const TEManagementFilterPanel({
    super.key,
    required this.show,
    required this.start,
    required this.end,
    required this.modelSerial,
    required this.model,
    required this.onApply,
    required this.onClose,
    required this.isDark,
  });

  @override
  State<TEManagementFilterPanel> createState() => _TEManagementFilterPanelState();
}

class _TEManagementFilterPanelState extends State<TEManagementFilterPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;
  late DateTime _start;
  late DateTime _end;
  late TextEditingController _serialCtrl;
  late TextEditingController _modelCtrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (widget.show) _controller.forward();
    _start = widget.start;
    _end = widget.end;
    _serialCtrl = TextEditingController(text: widget.modelSerial);
    _modelCtrl = TextEditingController(text: widget.model);
  }

  @override
  void didUpdateWidget(covariant TEManagementFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _start = widget.start;
    _end = widget.end;
    _serialCtrl.text = widget.modelSerial;
    _modelCtrl.text = widget.model;
  }

  @override
  void dispose() {
    _controller.dispose();
    _serialCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return IgnorePointer(
      ignoring: !widget.show,
      child: AnimatedOpacity(
        opacity: widget.show ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Stack(
          children: [
            GestureDetector(onTap: widget.onClose, child: Container(color: Colors.black26)),
            SlideTransition(
              position: _offset,
              child: Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  elevation: 10,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 370,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF232F34) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            IconButton(icon: const Icon(Icons.close, size: 28), onPressed: widget.onClose),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Filter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: isDark ? Colors.white : Colors.black)),
                        const SizedBox(height: 28),
                        Text('From', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _DateTimePicker(date: _start, isDark: isDark, onChanged: (d) => setState(() => _start = d)),
                        const SizedBox(height: 16),
                        Text('To', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _DateTimePicker(date: _end, isDark: isDark, onChanged: (d) => setState(() => _end = d)),
                        const SizedBox(height: 16),
                        Text('Model Serial', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _serialCtrl,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Model', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _modelCtrl,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
                                onPressed: widget.onClose,
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                onPressed: () {
                                  widget.onApply(
                                    _start,
                                    _end,
                                    _serialCtrl.text,
                                    _modelCtrl.text,
                                  );
                                },
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final DateTime date;
  final bool isDark;
  final ValueChanged<DateTime> onChanged;
  const _DateTimePicker({required this.date, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy/MM/dd HH:mm');
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(date.year - 1),
          lastDate: DateTime(date.year + 1),
          builder: (ctx, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark ? const ColorScheme.dark(primary: Colors.blueAccent) : const ColorScheme.light(primary: Colors.blue),
            ),
            child: child!,
          ),
        );
        if (picked == null) return;
        final t = TimeOfDay.fromDateTime(date);
        final pickedTime = await showTimePicker(context: context, initialTime: t);
        if (pickedTime == null) return;
        onChanged(DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute));
      },
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
        decoration: BoxDecoration(
          color: isDark ? Colors.blueGrey[900] : Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(format.format(date), style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
      ),
    );
  }
}
