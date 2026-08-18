import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/connectivity_service.dart';
import '../services/task_repository.dart';

enum TaskFilter { all, completed, pending }

enum TaskSort { dueDate, priority, createdDate }

enum LoadState { loading, loaded, empty, error }

class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required TaskRepository repository,
    required ConnectivityService connectivityService,
  })  : _repository = repository,
        _connectivityService = connectivityService {
    _init();
  }

  final TaskRepository _repository;
  final ConnectivityService _connectivityService;

  List<Task> _allTasks = [];
  LoadState _loadState = LoadState.loading;
  String _errorMessage = '';
  String _searchQuery = '';
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.dueDate;
  SyncStatus _syncStatus = SyncStatus.idle;
  bool _isOnline = true;

  LoadState get loadState => _loadState;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;
  SyncStatus get syncStatus => _syncStatus;
  bool get isOnline => _isOnline;

  void _init() {
    _repository.init();
    _isOnline = _connectivityService.isOnline;

    _connectivityService.onStatusChange.listen((online) {
      _isOnline = online;
      notifyListeners();
    });

    _repository.syncStatusStream.listen((status) {
      _syncStatus = status;
      if (status == SyncStatus.idle) {
        _refreshFromLocal();
      }
      notifyListeners();
    });

    unawaited(loadTasks());
  }

  Future<void> loadTasks() async {
    _loadState = LoadState.loading;
    notifyListeners();
    try {
      final tasks = await _repository.loadInitialTasks();
      _allTasks = tasks;
      _loadState = _allTasks.isEmpty ? LoadState.empty : LoadState.loaded;
    } catch (e) {
      _errorMessage = 'Unable to load your tasks. Please try again.';
      _loadState = LoadState.error;
    }
    notifyListeners();
  }

  void _refreshFromLocal() {
    _allTasks = _repository.getLocalTasks();
    _loadState = _allTasks.isEmpty ? LoadState.empty : LoadState.loaded;
    notifyListeners();
  }

  Future<void> retry() => loadTasks();

  Future<void> manualSync() => _repository.syncWithFirestore();

  /// Tasks after search, filter, and sort have been applied - entirely
  /// in-memory, no network calls.
  List<Task> get visibleTasks {
    var tasks = List<Task>.from(_allTasks);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      tasks = tasks.where((t) => t.title.toLowerCase().contains(query)).toList();
    }

    switch (_filter) {
      case TaskFilter.completed:
        tasks = tasks.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.pending:
        tasks = tasks.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    switch (_sort) {
      case TaskSort.dueDate:
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSort.priority:
        tasks.sort((a, b) => a.priority.sortWeight.compareTo(b.priority.sortWeight));
        break;
      case TaskSort.createdDate:
        tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        break;
    }

    return tasks;
  }

  int get completedCount => _allTasks.where((t) => t.isCompleted).length;
  int get pendingCount => _allTasks.where((t) => !t.isCompleted).length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSort(TaskSort sort) {
    _sort = sort;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    final saved = await _repository.createTask(task);
    _allTasks.add(saved);
    _loadState = LoadState.loaded;
    notifyListeners();
  }

  Future<void> editTask(Task task) async {
    final saved = await _repository.updateTask(task);
    final index = _allTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _allTasks[index] = saved;
    }
    notifyListeners();
  }

  Future<void> toggleCompletion(Task task) async {
    await editTask(task.copyWith(
      isCompleted: !task.isCompleted,
      updatedDate: DateTime.now(),
    ));
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    _allTasks.removeWhere((t) => t.id == id);
    _loadState = _allTasks.isEmpty ? LoadState.empty : LoadState.loaded;
    notifyListeners();
  }

  Task? getById(String id) {
    for (final task in _allTasks) {
      if (task.id == id) return task;
    }
    return null;
  }
}
