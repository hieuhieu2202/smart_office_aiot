import '../entities/kanban_entities.dart';
import '../repositories/nvidia_kanban_repository.dart';

class GetGroupsByDateRange {
  const GetGroupsByDateRange(this._repo);

  final NvidiaKanbanRepository _repo;

  Future<List<String>> call(KanbanRequest request) {
    return _repo.fetchGroupsByDateRange(request);
  }
}
