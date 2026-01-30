import '../../domain/entities/rack_entities.dart';
import 'rack_status_utils.dart';

class RackPartition {
  RackPartition({
    required this.online,
    required this.offline,
  });

  factory RackPartition.from(List<RackDetail> racks) {
    final online = <RackDetail>[];
    final offline = <RackDetail>[];

    for (final rack in racks) {
      if (isRackOffline(rack)) {
        offline.add(rack);
      } else {
        online.add(rack);
      }
    }

    return RackPartition(online: online, offline: offline);
  }

  final List<RackDetail> online;
  final List<RackDetail> offline;

  int get total => online.length + offline.length;
}
