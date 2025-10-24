import '../entities/kanban_entities.dart';

abstract class NvidiaKanbanRepository {
  Future<List<String>> fetchGroups(KanbanRequest request);
  Future<OutputTrackingEntity> fetchOutputTracking(KanbanRequest request);
  Future<UphTrackingEntity> fetchUphTracking(KanbanRequest request);
  Future<OutputTrackingDetailEntity> fetchOutputTrackingDetail(
    OutputTrackingDetailParams params,
  );
}
