import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_model.dart';

class StudentController extends GetxController {
  var students = <Student>[].obs;
  var filteredStudents = <Student>[].obs;
  static const String _storageKey = 'students_list';

  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      students.map((student) => student.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_storageKey);

    if (storedData != null) {
      final List<dynamic> decodedData = jsonDecode(storedData);
      students.assignAll(
        decodedData.map((item) => Student.fromJson(item)).toList(),
      );
    }
    filteredStudents.assignAll(students);
  }

  void addStudent(Student student) {
    students.add(student);
    filterStudents(''); // Refresh filter
    _saveToStorage();
  }

  void updateStudent(Student student) {
    int index = students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      students[index] = student;
      filterStudents(''); // Refresh filter
      _saveToStorage();
    }
  }

  void deleteStudent(String id) {
    students.removeWhere((s) => s.id == id);
    filterStudents(''); // Refresh filter
    _saveToStorage();
  }

  // Search & Filter
  void filterStudents(String query) {
    if (query.isEmpty) {
      filteredStudents.assignAll(students);
    } else {
      filteredStudents.assignAll(students.where((s) =>
          s.name.toLowerCase().contains(query.toLowerCase()) ||
          s.rollNumber.contains(query)));
    }
  }

  // Attendance Logic
  void markAttendance(String studentId, String date, bool isPresent) {
    int index = students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      Map<String, bool> newAttendance = Map<String, bool>.from(students[index].attendance);
      newAttendance[date] = isPresent;
      students[index].attendance = newAttendance;
      students.refresh();
      _saveToStorage();
    }
  }

  // Marks Logic
  void updateMarks(String studentId, String subject, double score) {
    int index = students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      Map<String, double> newMarks = Map<String, double>.from(students[index].marks);
      newMarks[subject] = score;
      students[index].marks = newMarks;
      students.refresh();
      _saveToStorage();
    }
  }

  // Fee Logic
  void updateFeeStatus(String studentId, bool paid) {
    int index = students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      students[index].isFeePaid = paid;
      students.refresh();
      _saveToStorage();
    }
  }
}
