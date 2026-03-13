class Course {
  final String name;
  final double totalMarks; // This will always be 100.0
  final double obtainedMarks; // This will be the normalized score (percentage)
  final int credits;
  final bool isLab;
  late double gradePoint;
  late String grade;

  Course({
    required this.name,
    required double totalMarks, // Input total marks
    required double obtainedMarks, // Input obtained marks
    required this.credits,
    required this.isLab,
  })  : this.totalMarks = 100.0,
        this.obtainedMarks = (totalMarks > 0) ? (obtainedMarks / totalMarks) * 100 : 0.0 {
    _calculateResults();
  }

  void _calculateResults() {
    double percentage = obtainedMarks; // Already normalized to 100
    if (percentage >= 85) {
      gradePoint = 4.0;
      grade = 'A';
    } else if (percentage >= 80) {
      gradePoint = 3.7;
      grade = 'A-';
    } else if (percentage >= 75) {
      gradePoint = 3.3;
      grade = 'B+';
    } else if (percentage >= 70) {
      gradePoint = 3.0;
      grade = 'B';
    } else if (percentage >= 65) {
      gradePoint = 2.7;
      grade = 'B-';
    } else if (percentage >= 61) {
      gradePoint = 2.3;
      grade = 'C+';
    } else if (percentage >= 58) {
      gradePoint = 2.0;
      grade = 'C';
    } else if (percentage >= 55) {
      gradePoint = 1.7;
      grade = 'C-';
    } else if (percentage >= 50) {
      gradePoint = 1.0;
      grade = 'D';
    } else {
      gradePoint = 0.0;
      grade = 'F';
    }
  }
}

class Semester {
  final String name;
  final List<Course> courses;
  double sgpa = 0.0;

  Semester({required this.name, required this.courses}) {
    calculateSGPA();
  }

  void calculateSGPA() {
    if (courses.isEmpty) {
      sgpa = 0.0;
      return;
    }
    double totalPoints = 0;
    int totalCredits = 0;
    for (var course in courses) {
      totalPoints += course.gradePoint * course.credits;
      totalCredits += course.credits;
    }
    sgpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }
}

class HistoryEntry {
  final double overallCGPA;
  final List<Semester> semesters;
  final DateTime dateTime;

  HistoryEntry({
    required this.overallCGPA,
    required this.semesters,
    required this.dateTime,
  });
}

class HistoryManager {
  static final HistoryManager _instance = HistoryManager._internal();
  factory HistoryManager() => _instance;
  HistoryManager._internal();

  final List<HistoryEntry> _history = [];

  List<HistoryEntry> get history => List.unmodifiable(_history);

  void addEntry(double overallCGPA, List<Semester> semesters) {
    _history.add(HistoryEntry(
      overallCGPA: overallCGPA,
      semesters: List.from(semesters), // Create a copy
      dateTime: DateTime.now(),
    ));
  }

  void clearHistory() {
    _history.clear();
  }
}
