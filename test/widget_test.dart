import 'package:ethicfin/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task JSON round-trip (local storage)', () {
    test('toJson -> fromJson preserves all fields', () {
      final original = Task(
        id: 'abc-123',
        title: 'Write report',
        description: 'Quarterly summary',
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 9, 1),
        isCompleted: true,
        createdDate: DateTime(2026, 8, 1),
        updatedDate: DateTime(2026, 8, 10),
        isSynced: true,
        isDirty: false,
        isDeleted: false,
      );

      final restored = Task.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.priority, original.priority);
      expect(restored.dueDate, original.dueDate);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.createdDate, original.createdDate);
      expect(restored.isSynced, original.isSynced);
      expect(restored.isDirty, original.isDirty);
      expect(restored.isDeleted, original.isDeleted);
    });

    test('fromJson handles a null dueDate', () {
      final task = Task(
        id: '1',
        title: 'No due date',
        description: '',
        priority: TaskPriority.low,
        createdDate: DateTime.now(),
        updatedDate: DateTime.now(),
      );
      final restored = Task.fromJson(task.toJson());
      expect(restored.dueDate, isNull);
    });
  });

  group('Task.copyWith', () {
    test('clearDueDate removes the due date', () {
      final task = Task(
        id: '1',
        title: 'Task',
        description: '',
        priority: TaskPriority.medium,
        dueDate: DateTime(2026, 1, 1),
        createdDate: DateTime.now(),
        updatedDate: DateTime.now(),
      );
      final cleared = task.copyWith(clearDueDate: true);
      expect(cleared.dueDate, isNull);
    });

    test('toggling completion marks the task dirty for sync', () {
      final task = Task(
        id: '1',
        title: 'Task',
        description: '',
        priority: TaskPriority.medium,
        createdDate: DateTime.now(),
        updatedDate: DateTime.now(),
        isSynced: true,
        isDirty: false,
      );
      final toggled = task.copyWith(isCompleted: true, isDirty: true, isSynced: false);
      expect(toggled.isCompleted, isTrue);
      expect(toggled.isDirty, isTrue);
      expect(toggled.isSynced, isFalse);
    });
  });

  group('TaskPriority sort weight', () {
    test('High sorts before Medium sorts before Low', () {
      final priorities = [TaskPriority.low, TaskPriority.high, TaskPriority.medium]
        ..sort((a, b) => a.sortWeight.compareTo(b.sortWeight));

      expect(priorities, [TaskPriority.high, TaskPriority.medium, TaskPriority.low]);
    });
  });

  group('Search & filter logic (mirrors TaskProvider.visibleTasks)', () {
    List<Task> sampleTasks() => [
      Task(
        id: '1',
        title: 'Buy groceries',
        description: '',
        priority: TaskPriority.low,
        isCompleted: false,
        createdDate: DateTime.now(),
        updatedDate: DateTime.now(),
      ),
      Task(
        id: '2',
        title: 'Finish report',
        description: '',
        priority: TaskPriority.high,
        isCompleted: true,
        createdDate: DateTime.now(),
        updatedDate: DateTime.now(),
      ),
      Task(
        id: '3',
        title: 'Book flight',
        description: '',
        priority: TaskPriority.medium,
        isCompleted: false,
        createdDate: DateTime.now(),
        updatedDate: DateTime.now(),
      ),
    ];

    test('search filters by title, case-insensitively', () {
      final tasks = sampleTasks();
      final query = 'book';
      final result =
      tasks.where((t) => t.title.toLowerCase().contains(query.toLowerCase())).toList();
      expect(result.length, 1);
      expect(result.first.title, 'Book flight');
    });

    test('pending filter excludes completed tasks', () {
      final tasks = sampleTasks();
      final pending = tasks.where((t) => !t.isCompleted).toList();
      expect(pending.length, 2);
      expect(pending.every((t) => !t.isCompleted), isTrue);
    });

    test('completed filter includes only completed tasks', () {
      final tasks = sampleTasks();
      final completed = tasks.where((t) => t.isCompleted).toList();
      expect(completed.length, 1);
      expect(completed.first.title, 'Finish report');
    });
  });
}
