import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/data_models/edit_project.dart';
import 'cloud_project.dart';
import 'project_repository.dart';

/// Keeps the local project list and `/users/{uid}/projects/{pid}` in step.
///
/// **What this does and does not give you today.** Only the *recipe* is synced
/// — name, size, the edit stack and the id of the gallery photo. The image
/// bytes stay on the device, because there is no Firebase Storage in this
/// build (spec's cloud backup is a separate step).
///
/// So: reinstalling on the **same phone** restores the edits, because the
/// photo is still in that phone's library and can be found again by its asset
/// id. Moving to a **different phone** does not, and [CloudProject.isRestorable]
/// is how the UI tells the difference instead of offering a restore that would
/// fail.
abstract class ProjectSync {
  bool get isAvailable;

  Future<void> push(EditProject project);

  Future<List<CloudProject>> pull();

  Future<void> remove(String projectId);
}

class FirestoreProjectSync implements ProjectSync {
  FirestoreProjectSync({
    required FirebaseFirestore firestore,
    required String? Function() uid,
  })  : _firestore = firestore,
        _uid = uid;

  final FirebaseFirestore _firestore;
  final String? Function() _uid;

  @override
  bool get isAvailable => _uid() != null;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _uid();
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('projects');
  }

  @override
  Future<void> push(EditProject project) async {
    final collection = _collection;
    if (collection == null) return;
    // Never awaited by a caller on the UI path: with Firestore's offline
    // persistence a write does not resolve until the device is online, so
    // awaiting one in the editor would hang it in airplane mode.
    await collection
        .doc(project.id)
        .set(CloudProject.fromProject(project).toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<CloudProject>> pull() async {
    final collection = _collection;
    if (collection == null) return const [];
    final snapshot = await collection.orderBy('updatedAt', descending: true).get();
    return snapshot.docs
        .map((doc) => CloudProject.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> remove(String projectId) async {
    await _collection?.doc(projectId).delete();
  }
}

/// What the app uses when there is no Firebase: every call is a no-op and
/// [isAvailable] is false, so the UI hides the cloud section rather than
/// showing one that never fills.
class NullProjectSync implements ProjectSync {
  const NullProjectSync();

  @override
  bool get isAvailable => false;

  @override
  Future<void> push(EditProject project) async {}

  @override
  Future<List<CloudProject>> pull() async => const [];

  @override
  Future<void> remove(String projectId) async {}
}

/// Pushes local changes up without ever making the caller wait.
///
/// A backup that slows the editor down is a backup people turn off, so every
/// failure here is logged and swallowed: the local database is the source of
/// truth and has already been written by the time this runs.
class BackgroundProjectSync {
  BackgroundProjectSync({
    required ProjectSync sync,
    required ProjectRepository projects,
  })  : _sync = sync,
        _projects = projects;

  final ProjectSync _sync;
  final ProjectRepository _projects;

  bool get isAvailable => _sync.isAvailable;

  void pushLater(EditProject project) {
    if (!_sync.isAvailable) return;
    _sync.push(project).catchError((Object error) {
      debugPrint('[sync] push failed for ${project.id}: $error');
    });
  }

  Future<void> pushAll() async {
    if (!_sync.isAvailable) return;
    try {
      for (final project in await _projects.all()) {
        await _sync.push(project);
      }
    } catch (error) {
      debugPrint('[sync] pushAll failed: $error');
    }
  }

  /// Remote projects that are not already on this device.
  Future<List<CloudProject>> restorable() async {
    if (!_sync.isAvailable) return const [];
    try {
      final remote = await _sync.pull();
      final localIds = (await _projects.all()).map((p) => p.id).toSet();
      return remote
          .where((p) => !localIds.contains(p.id) && p.isRestorable)
          .toList();
    } catch (error) {
      debugPrint('[sync] pull failed: $error');
      return const [];
    }
  }

  Future<void> forget(String projectId) async {
    if (!_sync.isAvailable) return;
    try {
      await _sync.remove(projectId);
    } catch (error) {
      debugPrint('[sync] delete failed for $projectId: $error');
    }
  }
}
