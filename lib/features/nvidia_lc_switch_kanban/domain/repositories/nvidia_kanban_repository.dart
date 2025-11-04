import '../entities/kanban_entities.dart';

abstract class NvidiaKanbanRepository {
  Future<List<String>> fetchGroups(KanbanRequest request);
  Future<List<String>> fetchGroupsByDateRange(KanbanRequest request);
  Future<OutputTrackingEntity> fetchOutputTracking(KanbanRequest request);
  Future<UphTrackingEntity> fetchUphTracking(KanbanRequest request);
  Future<UpdTrackingEntity> fetchUpdTracking(KanbanRequest request);
  Future<OutputTrackingDetailEntity> fetchOutputTrackingDetail(
    OutputTrackingDetailParams params,
  );
}
