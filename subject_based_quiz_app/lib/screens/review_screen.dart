import 'package:flutter/material.dart';
import '../models/question_model.dart';

class ReviewScreen extends StatelessWidget {
  final QuizRecord record;
  const ReviewScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Results"),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: record.reviewData.length,
        itemBuilder: (context, index) {
          final data = record.reviewData[index];
          final bool isCorrect = data['isCorrect'] ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${index + 1}: ${data['question']}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Your Answer: ", style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        "${data['selected']}",
                        style: TextStyle(
                          color: isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (!isCorrect) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("Correct Answer: ", style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          "${data['correct']}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
