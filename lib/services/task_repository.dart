import 'dart:async';
import '../models/task.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';

enum SyncStatus { idle, syncing, error }

/// Single source of truth for task data used by the UI layer.
///
/// Design: **local storage is authoritative for the UI**. Every read the app
/// does goes through Hive, which means the app is fully usable offline and
/// starts instantly (no waiting on a network round trip). Writes are saved
/// locally first (marked "dirty"), then pushed to Firestore in the
/// background whenever a connection is available. When connectivity is
/// restored, [syncWithFirestore] pushes any pending local changes and pulls
/// the latest remote state, merging it in without clobbering local edits
/// that haven't been pushed yet.
class TaskRepository {
  TaskRepository({
    required FirestoreService firestoreService,
    required LocalStorageService localStorageService,
    required ConnectivityService connectivityService,
  })  : _firestoreService = firestoreService,
        _localStorageService = localStorageService,
        _connectivityService = connectivityService;

  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;
  final ConnectivityService _connectivityService;

  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  void init() {
    _connectivitySubscription = _connectivityService.onStatusChange.listen((online) {
      if (online) {
        // Fire-and-forget: reconnecting should trigger a background sync.
        unawaited(syncWithFirestore());
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }

  List<Task> getLocalTasks() => _localStorageService.getAllTasks();

  /// Returns the local cache immediately (so the UI can render instantly)
  /// and kicks off a background sync if online.
  Future<List<Task>> loadInitialTasks() async {
    final local = _localStorageService.getAllTasks();
    if (_connectivityService.isOnline) {
      unawaited(syncWithFirestore());
    }
    return local;
  }

  Future<Task> createTask(Task task) async {
    final toSave = task.copyWith(isDirty: true, isSynced: false);
    await _localStorageService.saveTask(toSave);
    if (_connectivityService.isOnline) {
      unawaited(syncWithFirestore());
    }
    return toSave;
  }

  Future<Task> updateTask(Task task) async {
    final toSave = task.copyWith(
      isDirty: true,
      isSynced: false,
      updatedDate: DateTime.now(),
    );
    await _localStorageService.saveTask(toSave);
    if (_connectivityService.isOnline) {
      unawaited(syncWithFirestore());
    }
    return toSave;
  }

  Future<void> deleteTask(String id) async {
    final existing = _localStorageService.getTask(id);
    if (existing == null) return;

    if (_connectivityService.isOnline) {
      try {
        await _firestoreService.deleteTask(id);
        await _localStorageService.hardDeleteTask(id);
        return;
      } catch (_) {
        // Network hiccup mid-delete: fall through and queue it like an
        // offline delete so it retries on the next sync.
      }
    }

    final tombstone = existing.copyWith(
      isDeleted: true,
      isDirty: true,
      updatedDate: DateTime.now(),
    );
    await _localStorageService.saveTask(tombstone);
    if (_connectivityService.isOnline) {
      unawaited(syncWithFirestore());
    }
  }

  /// Pushes local pending changes to Firestore, then pulls the latest
  /// remote state and merges it into local storage.
  ///
  /// Remote data only overwrites a local task when that local task has no
  /// unsynced edits, so an offline edit can never be silently lost by an
  /// incoming remote update.
  Future<void> syncWithFirestore() async {
    if (_isSyncing || !_connectivityService.isOnline) return;
    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // 1. Push local pending changes (creates, edits, deletes).
      final dirtyTasks = _localStorageService.getDirtyTasks();
      for (final task in dirtyTasks) {
        if (task.isDeleted) {
          await _firestoreService.deleteTask(task.id);
          await _localStorageService.hardDeleteTask(task.id);
        } else {
          await _firestoreService.upsertTask(task);
          await _localStorageService.saveTask(
            task.copyWith(isDirty: false, isSynced: true),
          );
        }
      }

      // 2. Pull remote state and merge.
      final remoteTasks = await _firestoreService.fetchAllTasks();
      final localById = {
        for (final t in _localStorageService.getAllTasks(includeDeleted: true))
          t.id: t,
      };

      for (final remote in remoteTasks) {
        final local = localById[remote.id];
        final hasUnsyncedLocalChanges =
            local != null && (local.isDirty || local.isDeleted);
        if (!hasUnsyncedLocalChanges) {
          await _localStorageService.saveTask(
            remote.copyWith(isDirty: false, isSynced: true),
          );
        }
      }

      // 3. Drop local tasks that were removed remotely and have no pending
      // local changes of their own.
      final remoteIds = remoteTasks.map((t) => t.id).toSet();
      for (final local in localById.values) {
        final isFullySynced = local.isSynced && !local.isDirty && !local.isDeleted;
        if (!remoteIds.contains(local.id) && isFullySynced) {
          await _localStorageService.hardDeleteTask(local.id);
        }
      }

      _syncStatusController.add(SyncStatus.idle);
    } catch (_) {
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }
}
