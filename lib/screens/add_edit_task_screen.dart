import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key, this.existingTask});


  final Task? existingTask;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _saving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<TaskProvider>();
    final now = DateTime.now();

    if (_isEditing) {
      final updated = widget.existingTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        updatedDate: now,
      );
      await provider.editTask(updated);
    } else {
      final newTask = Task(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        createdDate: now,
        updatedDate: now,
      );
      await provider.addTask(newTask);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'e.g. Finish project proposal'),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Title is required';
                  if (trimmed.length < 3) return 'Title must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Add more details (optional)'),
              ),
              const SizedBox(height: 20),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                  ButtonSegment(value: TaskPriority.medium, label: Text('Medium')),
                  ButtonSegment(value: TaskPriority.high, label: Text('High')),
                ],
                selected: {_priority},
                onSelectionChanged: (selection) => setState(() => _priority = selection.first),
              ),
              const SizedBox(height: 20),
              const Text('Due date', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _dueDate == null
                            ? 'No due date selected'
                            : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-'
                                '${_dueDate!.day.toString().padLeft(2, '0')}',
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Create task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
