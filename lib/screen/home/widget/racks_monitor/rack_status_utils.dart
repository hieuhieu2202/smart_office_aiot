import '../../../../service/lc_switch_rack_api.dart'
    show RackDetail, SlotDetail;

const Set<String> kOfflineStatusKeywords = {
  'OFFLINE',
  'NO CONNECT',
  'NO_CONNECT',
  'DISCONNECTED',
  'DISCONNECT',
  'NOT CONNECTED',
  'POWER OFF',
  'POWER_OFF',
};

String normalizeRackStatus(String? status) => (status ?? '').trim().toUpperCase();

bool hasRackActivity(
  RackDetail rack, {
  List<SlotDetail>? slots,
}) {
  final list = slots ?? rack.slotDetails;
  if (rack.input > 0) return true;
  for (final slot in list) {
    if (slot.input > 0) return true;
    if (slot.totalPass > 0) return true;
  }
  return false;
}

bool isRackOffline(
  RackDetail rack, {
  List<SlotDetail>? slots,
}) {
  final list = slots ?? rack.slotDetails;
  if (list.isEmpty) return true;
  for (final slot in list) {
    final status = normalizeRackStatus(slot.status);
    if (kOfflineStatusKeywords.contains(status)) {
      return true;
    }
  }
  return !hasRackActivity(rack, slots: list);
}

bool isRackRunning(
  RackDetail rack, {
  List<SlotDetail>? slots,
}) {
  return hasRackActivity(rack, slots: slots);
}

bool isSlotOffline(SlotDetail slot) {
  final status = normalizeRackStatus(slot.status);
  if (kOfflineStatusKeywords.contains(status)) return true;
  return slot.input == 0 && slot.totalPass == 0;
}
