import '../models/question_model.dart';

class AppData {
  static List<QuizRecord> history = [];

  static int get totalQuizzes => history.length;
  
  static int get totalPoints => history.fold(0, (sum, item) => sum + item.score);

  static double get overallPercentage {
    if (history.isEmpty) return 0.0;
    double totalPerc = history.fold(0.0, (sum, item) => sum + item.percentage);
    return totalPerc / history.length;
  }

  static String get bestSubject {
    if (history.isEmpty) return "None";
    Map<String, List<double>> subjectScores = {};
    for (var record in history) {
      subjectScores.putIfAbsent(record.subject, () => []).add(record.percentage);
    }
    
    String best = "None";
    double highestAvg = -1;
    
    subjectScores.forEach((key, values) {
      double avg = values.reduce((a, b) => a + b) / values.length;
      if (avg > highestAvg) {
        highestAvg = avg;
        best = key;
      }
    });
    return best;
  }
}

final Map<String, List<Question>> questionData = {

  "Web Technologies": [
    Question(
      question: "HTML stands for?",
      options: [
        "Hyper Tool Multi Language",
        "Hyper Text Markup Language",
        "High Text Machine Language",
        "None"
      ],
      correctAnswer: "Hyper Text Markup Language",
    ),
    Question(
      question: "CSS is used for?",
      options: [
        "Database",
        "Server Logic",
        "Programming Hardware",
        "Styling Web Pages",
      ],
      correctAnswer: "Styling Web Pages",
    ),
    Question(
      question: "JavaScript runs on?",
      options: ["CPU", "RAM","Browser", "Printer"],
      correctAnswer: "Browser",
    ),
    Question(
      question: "HTTP stands for?",
      options: [
        "High Transfer Text Protocol",
        "Hyper Text Transfer Protocol",
        "Hyper Tool Transfer Program",
        "None"
      ],
      correctAnswer: "Hyper Text Transfer Protocol",
    ),
    Question(
      question: "Which is backend language?",
      options: ["HTML", "CSS", "PHP", "Bootstrap"],
      correctAnswer: "PHP",
    ),
  ],

  "Statistics": [
    Question(
      question: "Mean is also called?",
      options: ["Mode","Average", "Median", "Range"],
      correctAnswer: "Average",
    ),
    Question(
      question: "Median is?",
      options: [
        "Highest value",
        "Lowest value",
        "Middle value",
        "Total value"
      ],
      correctAnswer: "Middle value",
    ),
    Question(
      question: "Mode represents?",
      options: [
        "Least value",
        "Most frequent value",
        "Total",
        "None"
      ],
      correctAnswer: "Most frequent value",
    ),
    Question(
      question: "Standard deviation measures?",
      options: [
        "Total",
        "Average",
        "Middle",
        "Spread of data"
      ],
      correctAnswer: "Spread of data",
    ),
    Question(
      question: "Probability range is?",
      options: ["1 to 10", "0 to 100","0 to 1", "10 to 100"],
      correctAnswer: "0 to 1",
    ),
  ],

  "Design & Analysis": [
    Question(
      question: "Big O notation measures?",
      options: [
        "Color",
        "Memory Card",
        "Internet Speed",
        "Time Complexity",
      ],
      correctAnswer: "Time Complexity",
    ),
    Question(
      question: "Best case time complexity of Binary Search?",
      options: ["O(n)", "O(n2)","O(1)",  "O(log n)"],
      correctAnswer: "O(1)",
    ),
    Question(
      question: "Worst case of Linear Search?",
      options: [ "O(1)","O(n)", "O(log n)", "O(n log n)"],
      correctAnswer: "O(n)",
    ),
    Question(
      question: "Divide & Conquer example?",
      options: [
        "Linear Search",
        "Bubble Sort",
        "Merge Sort",
        "None"
      ],
      correctAnswer: "Merge Sort",
    ),
    Question(
      question: "Recursion means?",
      options: [
        "Loop",
        "Variable",
        "Array",
        "Function calling itself",
      ],
      correctAnswer: "Function calling itself",
    ),
  ],

  "Operating System": [
    Question(
      question: "OS is?",
      options: [
        "Application Software",
        "Game",
        "Browser",
        "System Software",
      ],
      correctAnswer: "System Software",
    ),
    Question(
      question: "CPU scheduling manages?",
      options: [
        "Color",
        "Mouse",
        "Process Execution",
        "Keyboard"
      ],
      correctAnswer: "Process Execution",
    ),
    Question(
      question: "RAM is?",
      options: [
        "Primary Memory",
        "Secondary Memory",
        "External Disk",
        "Printer"
      ],
      correctAnswer: "Primary Memory",
    ),
    Question(
      question: "Deadlock occurs when?",
      options: [
        "CPU stops",
        "Monitor off",
        "Processes wait forever",
        "Mouse broken"
      ],
      correctAnswer: "Processes wait forever",
    ),
    Question(
      question: "Linux is?",
      options: [
        "Browser",
        "Operating System",
        "Language",
        "Database"
      ],
      correctAnswer: "Operating System",
    ),
  ],

  "Assembly Language": [
    Question(
      question: "Assembly is?",
      options: [
        "Low level language",
        "High level language",
        "Database",
        "Browser"
      ],
      correctAnswer: "Low level language",
    ),
    Question(
      question: "MOV instruction does?",
      options: [
        "Delete data",
        "Multiply",
        "Move data",
        "Divide"
      ],
      correctAnswer: "Move data",
    ),
    Question(
      question: "CPU register stores?",
      options: [
        "Permanent file",
        "Image",
        "Video",
        "Temporary data",
      ],
      correctAnswer: "Temporary data",
    ),
    Question(
      question: "Assembler converts?",
      options: [
        "C++ to Java",
        "Assembly to Machine code",
        "HTML to CSS",
        "None"
      ],
      correctAnswer: "Assembly to Machine code",
    ),
    Question(
      question: "Opcode means?",
      options: [
        "Operating System",
        "Open code",
        "Output code",
        "Operation code",
      ],
      correctAnswer: "Operation code",
    ),
  ],

  "Mobile Application": [
    Question(
      question: "Flutter uses?",
      options: [ "Java", "C#","Dart", "Python"],
      correctAnswer: "Dart",
    ),
    Question(
      question: "APK stands for?",
      options: [
        "Application Program Key",
        "Android Package Kit",
        "Android Programming Kit",
        "None"
      ],
      correctAnswer: "Android Package Kit",
    ),
    Question(
      question: "Play Store is for?",
      options: [
        "Coding",
        "Database",
        "OS Installation",
        "App Distribution",
      ],
      correctAnswer: "App Distribution",
    ),
    Question(
      question: "UI means?",
      options: [
        "User Interface",
        "Unique Internet",
        "Universal Input",
        "None"
      ],
      correctAnswer: "User Interface",
    ),
    Question(
      question: "Hot Reload is feature of?",
      options: [ "HTML", "CSS", "MySQL","Flutter",],
      correctAnswer: "Flutter",
    ),
  ],

};