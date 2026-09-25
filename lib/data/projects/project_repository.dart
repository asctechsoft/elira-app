import '../../models/data_models/edit_project.dart';

/// Local store of the user's projects.
///
/// Deliberately local-only for now. Cloud sync (spec 6) needs a uid on every
/// row, conflict rules and a delete path, and putting it behind this interface
/// means Home does not have to change when it arrives.
abstract class ProjectRepository {
  /// Most recently edited first.
  Future<List<EditProject>> recent({int limit = 20});

  Future<List<EditProject>> all();

  Future<EditProject?> byId(String id);

  /// Insert or replace. Called when a draft is created and on every save.
  Future<void> save(EditProject project);

  /// Only touches the fields an edit changes, so a save cannot quietly revert
  /// a rename made elsewhere.
  Future<void> touch(
    String id, {
    Map<String, dynamic>? adjustments,
    String? thumbnailPath,
    String? editedPath,
    String? name,
  });

  Future<void> delete(String id);

  Future<int> count();
}
