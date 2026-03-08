class Question {
  final String question;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class QuizRecord {
  final String subject;
  final int score;
  final int total;
  final List<Map<String, dynamic>> reviewData;

  QuizRecord({
    required this.subject,
    required this.score,
    required this.total,
    required this.reviewData,
  });

  double get percentage => (score / total) * 100;
}
