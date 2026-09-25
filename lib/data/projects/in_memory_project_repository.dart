import '../../models/data_models/edit_project.dart';
import 'project_repository.dart';

/// Backs the tests, and any run where sqflite is unavailable.
class InMemoryProjectRepository implements ProjectRepository {
  InMemoryProjectRepository([List<EditProject> seed = const []]) {
    for (final project in seed) {
      _projects[project.id] = project;
    }
  }

  final Map<String, EditProject> _projects = {};

  List<EditProject> get _sorted {
    final list = _projects.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<List<EditProject>> recent({int limit = 20}) async =>
      _sorted.take(limit).toList();

  @override
  Future<List<EditProject>> all() async => _sorted;

  @override
  Future<EditProject?> byId(String id) async => _projects[id];

  @override
  Future<void> save(EditProject project) async => _projects[project.id] = project;

  @override
  Future<void> touch(
    String id, {
    Map<String, dynamic>? adjustments,
    String? thumbnailPath,
    String? editedPath,
    String? name,
  }) async {
    final existing = _projects[id];
    if (existing == null) return;
    _projects[id] = existing.copyWith(
      adjustments: adjustments,
      thumbnailPath: thumbnailPath,
      editedPath: editedPath,
      name: name,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> delete(String id) async => _projects.remove(id);

  @override
  Future<int> count() async => _projects.length;
}
