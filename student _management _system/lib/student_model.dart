class Student {
  String id;
  String name;
  String rollNumber;
  String studentClass;
  String section;
  String phoneNumber;
  String email;
  String address;
  String? profilePath; // For Profile Picture
  
  Map<String, bool> attendance; 
  Map<String, double> marks;
  bool isFeePaid;
  double monthlyFee;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.studentClass,
    required this.section,
    required this.phoneNumber,
    required this.email,
    required this.address,
    this.profilePath,
    this.attendance = const {},
    this.marks = const {},
    this.isFeePaid = false,
    this.monthlyFee = 0.0,
  });

  double get averageMarks {
    if (marks.isEmpty) return 0.0;
    double total = marks.values.reduce((a, b) => a + b);
    return total / marks.length;
  }

  String get gpa {
    double avg = averageMarks;
    if (avg >= 80) return "4.0";
    if (avg >= 70) return "3.5";
    if (avg >= 60) return "3.0";
    if (avg >= 50) return "2.0";
    return "F";
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
      'studentClass': studentClass,
      'section': section,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'profilePath': profilePath,
      'attendance': attendance,
      'marks': marks,
      'isFeePaid': isFeePaid,
      'monthlyFee': monthlyFee,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      rollNumber: json['rollNumber'],
      studentClass: json['studentClass'],
      section: json['section'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      address: json['address'],
      profilePath: json['profilePath'],
      attendance: Map<String, bool>.from(json['attendance'] ?? {}),
      marks: Map<String, double>.from(json['marks'] ?? {}),
      isFeePaid: json['isFeePaid'] ?? false,
      monthlyFee: (json['monthlyFee'] ?? 0.0).toDouble(),
    );
  }
}
