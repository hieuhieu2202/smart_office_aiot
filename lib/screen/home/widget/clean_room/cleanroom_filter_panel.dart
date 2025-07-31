import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';

class CleanroomFilterPanel extends StatefulWidget {
  final bool show;
  final DateTime start;
  final DateTime end;
  final String? customer;
  final String? factory;
  final String? floor;
  final String? room;
  final List<String> customerOptions;
  final List<String> factoryOptions;
  final List<String> floorOptions;
  final List<String> roomOptions;
  final void Function(DateTime start, DateTime end, String? customer, String? factory, String? floor, String? room) onApply;
  final VoidCallback onClose;
  final bool isDark;

  const CleanroomFilterPanel({
    super.key,
    required this.show,
    required this.start,
    required this.end,
    required this.customer,
    required this.factory,
    required this.floor,
    required this.room,
    required this.customerOptions,
    required this.factoryOptions,
    required this.floorOptions,
    required this.roomOptions,
    required this.onApply,
    required this.onClose,
    required this.isDark,
  });

  @override
  State<CleanroomFilterPanel> createState() => _CleanroomFilterPanelState();
}

class _CleanroomFilterPanelState extends State<CleanroomFilterPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;
  late DateTime _start;
  late DateTime _end;
  String? _customer;
  String? _factory;
  String? _floor;
  String? _room;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (widget.show) _controller.forward();
    _start = widget.start;
    _end = widget.end;
    _customer = widget.customer;
    _factory = widget.factory;
    _floor = widget.floor;
    _room = widget.room;
  }

  @override
  void didUpdateWidget(covariant CleanroomFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _start = widget.start;
    _end = widget.end;
    _customer = widget.customer;
    _factory = widget.factory;
    _floor = widget.floor;
    _room = widget.room;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final format = DateFormat('yyyy/MM/dd HH:mm');
    return IgnorePointer(
      ignoring: !widget.show,
      child: AnimatedOpacity(
        opacity: widget.show ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Stack(
          children: [
            GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black26),
            ),
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
                            IconButton(
                              icon: const Icon(Icons.close, size: 28),
                              onPressed: widget.onClose,
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text("Lọc phòng sạch", style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: isDark ? Colors.white : Colors.black,
                        )),
                        const SizedBox(height: 28),
                        Text("Từ ngày", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _DateTimePicker(
                          date: _start,
                          isDark: isDark,
                          onChanged: (d) => setState(() => _start = d),
                        ),
                        const SizedBox(height: 16),
                        Text("Đến ngày", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _DateTimePicker(
                          date: _end,
                          isDark: isDark,
                          onChanged: (d) => setState(() => _end = d),
                        ),
                        const SizedBox(height: 22),
                        Text("Khách hàng", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _customer,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          items: widget.customerOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) {
                            setState(() => _customer = v);
                            Get.find<CleanRoomController>().selectedCustomer.value = v ?? '';
                            Get.find<CleanRoomController>().fetchFactories();
                          },
                        ),
                        const SizedBox(height: 16),
                        Text("Nhà máy", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _factory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          items: widget.factoryOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) {
                            setState(() => _factory = v);
                            Get.find<CleanRoomController>().selectedFactory.value = v ?? '';
                            Get.find<CleanRoomController>().fetchFloors();
                          },
                        ),
                        const SizedBox(height: 16),
                        Text("Tầng", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _floor,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          items: widget.floorOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) {
                            setState(() => _floor = v);
                            Get.find<CleanRoomController>().selectedFloor.value = v ?? '';
                            Get.find<CleanRoomController>().fetchRooms();
                          },
                        ),
                        const SizedBox(height: 16),
                        Text("Phòng", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _room,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          items: widget.roomOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _room = v),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                ),
                                onPressed: widget.onClose,
                                child: const Text("Huỷ"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                ),
                                onPressed: () {
                                  widget.onApply(_start, _end, _customer, _factory, _floor, _room);
                                },
                                child: const Text("Áp dụng"),
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