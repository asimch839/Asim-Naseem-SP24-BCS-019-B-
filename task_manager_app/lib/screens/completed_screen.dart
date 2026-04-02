import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';

class CompletedScreen extends StatelessWidget {
  final List<TaskModel> tasks;
  const CompletedScreen({required this.tasks, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const Center(child: Text('No completed tasks yet.'));
    final provider = Provider.of<TaskProvider>(context, listen: false);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final t = tasks[i];
        return TaskTile(
          task: t,
          canEdit: false,        // Completed screen cannot edit
          canComplete: false,    // Cannot toggle completion
          onDelete: () => provider.deleteTask(t),
        );
      },
    );
  }
}
