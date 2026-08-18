import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/state_widgets.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/task_tile.dart';
import 'add_edit_task_screen.dart';
import 'task_details_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: SyncStatusIndicator(
                isOnline: provider.isOnline,
                syncStatus: provider.syncStatus,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search tasks by title...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: provider.filter == TaskFilter.all,
                            onSelected: () => provider.setFilter(TaskFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Pending (${provider.pendingCount})',
                            selected: provider.filter == TaskFilter.pending,
                            onSelected: () => provider.setFilter(TaskFilter.pending),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Completed (${provider.completedCount})',
                            selected: provider.filter == TaskFilter.completed,
                            onSelected: () => provider.setFilter(TaskFilter.completed),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<TaskSort>(
                    tooltip: 'Sort tasks',
                    initialValue: provider.sort,
                    onSelected: provider.setSort,
                    icon: const Icon(Icons.sort_rounded),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: TaskSort.dueDate, child: Text('Sort by due date')),
                      PopupMenuItem(value: TaskSort.priority, child: Text('Sort by priority')),
                      PopupMenuItem(
                          value: TaskSort.createdDate, child: Text('Sort by created date')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TaskProvider provider) {
    switch (provider.loadState) {
      case LoadState.loading:
        return const LoadingStateView();
      case LoadState.error:
        return ErrorStateView(message: provider.errorMessage, onRetry: provider.retry);
      case LoadState.empty:
      case LoadState.loaded:
        final tasks = provider.visibleTasks;
        if (tasks.isEmpty) {
          final hasActiveFilters =
              provider.searchQuery.isNotEmpty || provider.filter != TaskFilter.all;
          return EmptyStateView(
            title: hasActiveFilters ? 'No matching tasks' : 'No tasks yet',
            message: hasActiveFilters
                ? 'Try a different search term or filter.'
                : 'Tap the + button to create your first task.',
            icon: hasActiveFilters ? Icons.search_off_rounded : Icons.checklist_rounded,
          );
        }
        return RefreshIndicator(
          onRefresh: provider.manualSync,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: ValueKey(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                ),
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) => provider.deleteTask(task.id),
                child: TaskTile(
                  task: task,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
                  ),
                  onToggle: (_) => provider.toggleCompletion(task),
                ),
              );
            },
          ),
        );
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
