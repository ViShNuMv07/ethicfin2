import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

/// Wraps Hive to persist tasks on-device so the app keeps working (and keeps
/// its data) with no network connection and across app restarts.
///
/// Tasks are stored as plain `Map<String, dynamic>` values (via
/// [Task.toJson]/[Task.fromJson]) which Hive supports natively, so no
/// generated TypeAdapter / build_runner step is required.
class LocalStorageService {
  static const String _boxName = 'tasks_box';
  Box<Map>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _tasksBox {
    final box = _box;
    if (box == null) {
      throw StateError(
        'LocalStorageService.init() must be called before use.',
      );
    }
    return box;
  }

  /// Returns all locally stored tasks. Soft-deleted (offline-pending-delete)
  /// tasks are excluded by default so the UI never shows them.
  List<Task> getAllTasks({bool includeDeleted = false}) {
    return _tasksBox.values
        .map((raw) => Task.fromJson(Map<String, dynamic>.from(raw)))
        .where((task) => includeDeleted || !task.isDeleted)
        .toList();
  }

  Task? getTask(String id) {
    final raw = _tasksBox.get(id);
    if (raw == null) return null;
    return Task.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> saveTask(Task task) async {
    await _tasksBox.put(task.id, task.toJson());
  }

  Future<void> saveTasks(Iterable<Task> tasks) async {
    final map = {for (final t in tasks) t.id: t.toJson()};
    await _tasksBox.putAll(map);
  }

  /// Permanently removes a task from local storage (used once a delete has
  /// been confirmed on Firestore, or when a remote task no longer exists).
  Future<void> hardDeleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  /// Tasks that still need to be pushed to Firestore (new, edited, or
  /// deleted while offline).
  List<Task> getDirtyTasks() {
    return getAllTasks(includeDeleted: true)
        .where((task) => task.isDirty)
        .toList();
  }

  Future<void> clear() async => _tasksBox.clear();
}
