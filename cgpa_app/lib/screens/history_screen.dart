import 'package:flutter/material.dart';
import '../models/cpa_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryManager _historyManager = HistoryManager();

  @override
  Widget build(BuildContext context) {
    final history = _historyManager.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculation History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () {
                setState(() {
                  _historyManager.clearHistory();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History Cleared')),
                );
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No History Found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your saved CGPA results will appear here.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[history.length - 1 - index]; // Show latest first
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assessment_rounded, color: Colors.blue),
                    ),
                    title: Text(
                      'Overall CGPA: ${entry.overallCGPA.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Date: ${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year} at ${entry.dateTime.hour}:${entry.dateTime.minute}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    children: entry.semesters.map((sem) => ListTile(
                      dense: true,
                      title: Text(sem.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('GPA: ${sem.sgpa.toStringAsFixed(2)}'),
                      trailing: Text('${sem.courses.length} Subjects'),
                    )).toList(),
                  ),
                );
              },
            ),
    );
  }
}
