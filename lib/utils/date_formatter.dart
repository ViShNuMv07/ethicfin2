import 'package:intl/intl.dart';

class DateFormatter {
  static String short(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  static String withTime(DateTime date) =>
      DateFormat('MMM d, yyyy • h:mm a').format(date);


  static String relativeDueLabel(DateTime? due) {
    if (due == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;

    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff == -1) return 'Overdue • yesterday';
    if (diff < 0) return 'Overdue • ${short(due)}';
    if (diff <= 7) return 'Due in $diff days';
    return 'Due ${short(due)}';
  }

  static bool isOverdue(DateTime? due, bool isCompleted) {
    if (due == null || isCompleted) return false;
    final now = DateTime.now();
    return due.isBefore(DateTime(now.year, now.month, now.day));
  }
}
