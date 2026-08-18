import 'package:flutter/material.dart';
import '../services/task_repository.dart';


class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.isOnline,
    required this.syncStatus,
  });

  final bool isOnline;
  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String label;

    if (!isOnline) {
      icon = Icons.cloud_off_rounded;
      color = Colors.grey;
      label = 'Offline';
    } else if (syncStatus == SyncStatus.syncing) {
      icon = Icons.sync_rounded;
      color = Colors.blue;
      label = 'Syncing';
    } else if (syncStatus == SyncStatus.error) {
      icon = Icons.sync_problem_rounded;
      color = Colors.orange;
      label = 'Sync issue';
    } else {
      icon = Icons.cloud_done_rounded;
      color = Colors.green;
      label = 'Synced';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncStatus == SyncStatus.syncing && isOnline)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
