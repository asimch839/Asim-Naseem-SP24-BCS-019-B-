import 'dart:async';
import 'package:flutter/material.dart';
import '../data/questions_data.dart';
import '../models/question_model.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  String? selectedOption;
  bool isAnswered = false;
  List<Map<String, dynamic>> reviewData = [];
  
  // Timer variables
  Timer? _timer;
  int _timeLeft = 10;

  @override
  void initState() {
    super.initState();
    // Start timer for the first question
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = 10;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _timer?.cancel();
            _handleTimeout();
          }
        });
      }
    });
  }

  void _handleTimeout() {
    final String subject = ModalRoute.of(context)!.settings.arguments as String;
    final questions = questionData[subject]!;

    // Record as missed
    reviewData.add({
      'question': questions[currentQuestionIndex].question,
      'selected': "Time Out",
      'correct': questions[currentQuestionIndex].correctAnswer,
      'isCorrect': false,
    });

    // Show popup for timeout
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Time Out!"),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );

    // Wait for snackbar then move next
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _nextQuestionSilently(questions);
      }
    });
  }

  void _nextQuestionSilently(List<Question> questions) {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOption = null;
        isAnswered = false;
      });
      _startTimer();
    } else {
      _finishQuiz(questions);
    }
  }

  void _finishQuiz(List<Question> questions) {
    final String subject = ModalRoute.of(context)!.settings.arguments as String;
    
    final record = QuizRecord(
      subject: subject,
      score: score,
      total: questions.length,
      reviewData: List.from(reviewData),
    );

    // Save to AppData
    AppData.history.add(record);

    Navigator.pushReplacementNamed(
      context,
      '/result',
      arguments: {
        'score': score,
        'total': questions.length,
        'record': record, // Passing the full record for review
      },
    );
  }

  void nextQuestion(List<Question> questions) {
    _timer?.cancel();
    
    if (selectedOption == questions[currentQuestionIndex].correctAnswer) {
      score++;
    }

    // Record answer
    reviewData.add({
      'question': questions[currentQuestionIndex].question,
      'selected': selectedOption ?? "None",
      'correct': questions[currentQuestionIndex].correctAnswer,
      'isCorrect': selectedOption == questions[currentQuestionIndex].correctAnswer,
    });

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOption = null;
        isAnswered = false;
      });
      _startTimer();
    } else {
      _finishQuiz(questions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String subject = ModalRoute.of(context)!.settings.arguments as String;
    final questions = questionData[subject]!;
    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (currentQuestionIndex + 1) / questions.length,
                  ),
                ),
                const SizedBox(width: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _timeLeft / 10,
                      strokeWidth: 5,
                      color: _timeLeft < 4 ? Colors.red : Colors.deepPurple,
                    ),
                    Text(
                      "$_timeLeft",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Question ${currentQuestionIndex + 1}/${questions.length}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              currentQuestion.question,
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ...currentQuestion.options.map((option) {
              Color buttonColor = Colors.white;
              Color textColor = Colors.black;

              if (isAnswered) {
                if (option == currentQuestion.correctAnswer) {
                  buttonColor = Colors.green;
                  textColor = Colors.white;
                } else if (option == selectedOption) {
                  buttonColor = Colors.red;
                  textColor = Colors.white;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAnswered
                        ? null
                        : () {
                      _timer?.cancel();
                      setState(() {
                        selectedOption = option;
                        isAnswered = true;
                      });
                      // Automatically move to next after 1.5 seconds
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        if (mounted) nextQuestion(questions);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: buttonColor,
                      foregroundColor: textColor,
                      disabledBackgroundColor: buttonColor,
                      disabledForegroundColor: textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isAnswered && (option == currentQuestion.correctAnswer || option == selectedOption)
                            ? BorderSide.none
                            : const BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Text(
                      option,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}