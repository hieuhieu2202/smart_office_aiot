import '../entities/kanban_entities.dart';
import '../repositories/nvidia_kanban_repository.dart';

class GetGroups {
  GetGroups(this._repository);

  final NvidiaKanbanRepository _repository;

  Future<List<String>> call(KanbanRequest request) {
    return _repository.fetchGroups(request);
  }
}
