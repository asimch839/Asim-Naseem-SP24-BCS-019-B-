import 'package:flutter/material.dart';
import '../models/question_model.dart';
import 'review_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    
    if (arguments == null || arguments is! Map<String, dynamic>) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No result data found"),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/subjects'),
                child: const Text("Go Back"),
              )
            ],
          ),
        ),
      );
    }

    final resultData = arguments;
    final int score = resultData['score'] ?? 0;
    final int total = resultData['total'] ?? 0;
    final QuizRecord? record = resultData['record'];
    final double percentage = total > 0 ? (score / total) * 100 : 0;

    // Calculate detailed stats
    int correct = 0;
    int wrong = 0;
    int missed = 0;

    if (record != null) {
      for (var data in record.reviewData) {
        if (data['isCorrect'] == true) {
          correct++;
        } else if (data['selected'] == "Time Out") {
          missed++;
        } else {
          wrong++;
        }
      }
    } else {
      correct = score;
      wrong = total - score;
    }

    String message;
    if (percentage >= 80) {
      message = "Excellent 🎉";
    } else if (percentage >= 50) {
      message = "Good Job 👍";
    } else {
      message = "Try Again 😅";
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Quiz Result",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40), 
                    blurRadius: 15, 
                    offset: const Offset(0, 10)
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF764ba2),
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 40, thickness: 1),

                  // Detailed Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn("Correct", "$correct", Colors.green),
                      _buildStatColumn("Wrong", "$wrong", Colors.red),
                      _buildStatColumn("Missed", "$missed", Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            if (record != null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewScreen(record: record),
                      ),
                    );
                  },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text("REVIEW ANSWERS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/subjects', (route) => false);
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text("BACK TO DASHBOARD", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF764ba2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}