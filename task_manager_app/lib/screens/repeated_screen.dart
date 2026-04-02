import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../screens/add_edit_task_screen.dart';
import '../models/task_model.dart';

class RepeatedScreen extends StatelessWidget {
  const RepeatedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final repeated = provider.tasks.where((t) => t.repeatType != 'none').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔁 Repeated Tasks'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E24AA), Color(0xFFCE93D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: repeated.isEmpty
          ? const Center(
        child: Text('No repeated tasks found.',
            style: TextStyle(fontSize: 16, color: Colors.black54)),
      )
          : ListView.builder(
        itemCount: repeated.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, i) {
          final t = repeated[i];
          return TaskTile(
            task: t,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTaskScreen(editing: t),
              ),
            ),
            onDelete: () => provider.deleteTask(t),
            onToggleComplete: () => provider.toggleTaskCompletion(t),
          );
        },
      ),
    );
  }
}
