import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;
  final bool canEdit;      // new
  final bool canComplete;  // new

  const TaskTile({
    required this.task,
    this.onTap,
    this.onDelete,
    this.onToggleComplete,
    this.canEdit = true,
    this.canComplete = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: canComplete
            ? IconButton(
          icon: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : Colors.blueGrey,
          ),
          onPressed: onToggleComplete,
        )
            : Icon(Icons.check_circle, color: Colors.green),
        title: Text(
          task.title,
          style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((task.description).isNotEmpty)
              Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: task.progress, minHeight: 6),
          ],
        ),
        trailing: PopupMenuButton<int>(
          onSelected: (v) {
            if (v == 2 && onDelete != null) onDelete!();
            if (v == 3 && canComplete && onToggleComplete != null) onToggleComplete!();
            if (v == 1 && canEdit && onTap != null) onTap!();
          },
          itemBuilder: (ctx) {
            final items = <PopupMenuEntry<int>>[];
            if (canEdit) items.add(const PopupMenuItem(value: 1, child: Text('Edit')));
            items.add(const PopupMenuItem(value: 2, child: Text('Delete')));
            return items;
          },
        ),
      ),
    );
  }
}
