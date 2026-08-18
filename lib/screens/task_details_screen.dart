import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../utils/date_formatter.dart';
import '../widgets/priority_badge.dart';
import 'add_edit_task_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final task = provider.getById(taskId);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task details')),
        body: const Center(child: Text('This task no longer exists.')),
      );
    }

    final overdue = DateFormatter.isOverdue(task.dueDate, task.isCompleted);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddEditTaskScreen(existingTask: task)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete task?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await provider.deleteTask(task.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              task.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PriorityBadge(priority: task.priority),
                Chip(
                  avatar: Icon(
                    task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: task.isCompleted ? Colors.green : Colors.orange,
                  ),
                  label: Text(task.isCompleted ? 'Completed' : 'Pending'),
                ),
                if (task.dueDate != null)
                  Chip(
                    avatar: Icon(Icons.event_rounded, size: 16, color: overdue ? Colors.red : Colors.grey),
                    label: Text(DateFormatter.relativeDueLabel(task.dueDate)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              task.description.isEmpty ? 'No description provided.' : task.description,
              style: TextStyle(
                color: task.description.isEmpty ? Colors.grey : null,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            _MetaRow(label: 'Created', value: DateFormatter.withTime(task.createdDate)),
            const SizedBox(height: 8),
            _MetaRow(label: 'Last updated', value: DateFormatter.withTime(task.updatedDate)),
            const SizedBox(height: 8),
            _MetaRow(
              label: 'Sync status',
              value: task.isSynced ? 'Synced to cloud' : 'Pending sync',
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => provider.toggleCompletion(task),
              icon: Icon(task.isCompleted ? Icons.undo_rounded : Icons.check_rounded),
              label: Text(task.isCompleted ? 'Mark as pending' : 'Mark as completed'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
