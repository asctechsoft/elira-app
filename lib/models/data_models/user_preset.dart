import 'dart:convert';

import 'edit_operation.dart';

/// A look the user saved to reuse.
///
/// Only the colour and effect slices: a crop or a caption belongs to one photo,
/// not to a look, so saving them would make a preset do something different on
/// the next photo than it did on the one it came from.
class UserPreset {
  const UserPreset({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.useCount = 0,
    this.adjust = AdjustParams.identity,
    this.filter = FilterParams.identity,
    this.effects = EffectParams.identity,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// How often it has been applied, so the list can lead with what is used.
  final int useCount;

  final AdjustParams adjust;
  final FilterParams filter;
  final EffectParams effects;

  /// A preset that changes nothing is not worth saving, and the UI refuses it.
  bool get isEmpty =>
      adjust.isIdentity && filter.isIdentity && effects.isIdentity;

  /// Captures the reusable part of an edit, dropping the photo-specific slices.
  factory UserPreset.fromState({
    required String id,
    required String name,
    required EditState state,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    return UserPreset(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
      adjust: state.adjust,
      filter: state.filter,
      effects: state.effects,
    );
  }

  /// The operations applying this preset becomes. Same trick as a template:
  /// a preset is ordinary edits, so it is undoable and saved like anything
  /// else, and the editor needs no concept of presets at all.
  List<EditOperation> toOperations() {
    final operations = <EditOperation>[];
    if (!filter.isIdentity) {
      operations.add(EditOperation(
        type: EditOperationType.filter,
        label: name,
        params: filter.toMap(),
      ));
    }
    if (!adjust.isIdentity) {
      operations.add(EditOperation(
        type: EditOperationType.adjust,
        label: name,
        params: adjust.toMap(),
      ));
    }
    if (!effects.isIdentity) {
      operations.add(EditOperation(
        type: EditOperationType.effects,
        label: name,
        params: effects.toMap(),
      ));
    }
    return operations;
  }

  UserPreset copyWith({String? name, int? useCount, DateTime? updatedAt}) =>
      UserPreset(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        useCount: useCount ?? this.useCount,
        adjust: adjust,
        filter: filter,
        effects: effects,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'use_count': useCount,
        'state': jsonEncode({
          'adjust': adjust.toMap(),
          'filter': filter.toMap(),
          'effects': effects.toMap(),
        }),
      };

  factory UserPreset.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> state = const {};
    final raw = map['state'];
    if (raw is Map) {
      state = raw.map((k, v) => MapEntry(k.toString(), v));
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          state = decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {
        // A row written by a newer build must not break the list.
      }
    }

    Map<String, dynamic> slice(String key) => state[key] is Map
        ? (state[key] as Map).map((k, v) => MapEntry(k.toString(), v))
        : const {};

    int asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);

    return UserPreset(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Untitled look',
      createdAt: DateTime.fromMillisecondsSinceEpoch(asInt(map['created_at'])),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(asInt(map['updated_at'])),
      useCount: asInt(map['use_count']),
      adjust: AdjustParams.fromMap(slice('adjust')),
      filter: FilterParams.fromMap(slice('filter')),
      effects: EffectParams.fromMap(slice('effects')),
    );
  }

  @override
  String toString() => 'UserPreset($id, "$name")';
}
