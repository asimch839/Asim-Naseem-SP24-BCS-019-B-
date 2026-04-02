import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TaskController controller = Get.find<TaskController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity History"),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              Get.defaultDialog(
                title: "Clear History",
                middleText: "Are you sure you want to clear all history?",
                textCancel: "No",
                textConfirm: "Yes",
                confirmTextColor: Colors.white,
                onConfirm: () {
                  controller.clearHistory();
                  Get.back();
                },
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.history.isEmpty) {
          return const Center(
            child: Text("No history available.", style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: controller.history.length,
          itemBuilder: (context, index) {
            final item = controller.history[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _getActionIcon(item.action),
                title: Text(
                  item.taskTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Action: ${item.action.toUpperCase()}\n${DateFormat('MMM d, yyyy - hh:mm a').format(item.timestamp)}",
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _getActionIcon(String action) {
    switch (action) {
      case 'added':
        return const Icon(Icons.add_circle, color: Colors.blue);
      case 'edited':
        return const Icon(Icons.edit, color: Colors.orange);
      case 'deleted':
        return const Icon(Icons.delete, color: Colors.red);
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'incomplete':
        return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
      default:
        return const Icon(Icons.history);
    }
  }
}
