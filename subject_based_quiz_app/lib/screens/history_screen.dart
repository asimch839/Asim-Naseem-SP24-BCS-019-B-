import 'package:flutter/material.dart';
import '../data/questions_data.dart';
import '../models/question_model.dart';
import 'review_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz History"),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
      body: AppData.history.isEmpty 
        ? const Center(child: Text("No history available"))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: AppData.history.length,
            itemBuilder: (context, i) {
              final record = AppData.history.reversed.toList()[i];
              return HistoryTile(record: record);
            },
          ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final QuizRecord record;
  const HistoryTile({super.key, required this.record});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          record.subject,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          "Score: ${record.score}/${record.total}",
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: record.percentage >= 50 ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "${record.percentage.toStringAsFixed(0)}%",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: record.percentage >= 50 ? Colors.green : Colors.red,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewScreen(record: record),
            ),
          );
        },
      ),
    );
  }
}
