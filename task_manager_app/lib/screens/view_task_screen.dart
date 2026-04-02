import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class ViewTaskScreen extends StatelessWidget {
  final TaskModel task;

  const ViewTaskScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TaskController controller = Get.find<TaskController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("View Task"),
        backgroundColor: const Color(0xFF8E24AA),
        elevation: 4,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.brightness == Brightness.dark
                  ? const Color(0xFF1E1E2C)
                  : Colors.white,
              theme.brightness == Brightness.dark
                  ? const Color(0xFF2C2C3E)
                  : Colors.purple.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Obx(() {
          // Find the latest version of this task from the controller
          final currentTask = controller.tasks.firstWhere((t) => t.id == task.id, orElse: () => task);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTask.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy – hh:mm a').format(currentTask.dueDate),
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.repeat, size: 20, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          "Repeat: ${currentTask.repeatType}",
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          currentTask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: currentTask.isCompleted ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentTask.isCompleted ? "Completed" : "Pending",
                          style: TextStyle(
                            fontSize: 16,
                            color: currentTask.isCompleted ? Colors.green : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Description:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentTask.description.isNotEmpty ? currentTask.description : "No description provided.",
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (currentTask.subtasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Subtasks",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                            const Divider(),
                            ...currentTask.subtasks.map(
                              (sub) => ListTile(
                                leading: Icon(
                                  sub.done ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: sub.done ? Colors.green : Colors.grey[600],
                                ),
                                title: Text(
                                  sub.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: sub.done ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (currentTask.subtasks.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: currentTask.progress,
                            backgroundColor: Colors.grey.shade300,
                            color: const Color(0xFF8E24AA),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 6),
                          Text("${(currentTask.progress * 100).toStringAsFixed(0)}% completed", style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
