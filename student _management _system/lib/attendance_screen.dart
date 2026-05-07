import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'student_controller.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final StudentController controller = Get.find();
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Daily Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date: $selectedDate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                Text("Total: ${controller.students.length}", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: controller.students.length,
              itemBuilder: (context, index) {
                final student = controller.students[index];
                bool isPresent = student.attendance[selectedDate] ?? false;

                return Card(
                  margin: EdgeInsets.only(bottom: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(student.name[0]),
                    ),
                    title: Text(student.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Roll No: ${student.rollNumber}"),
                    trailing: Switch(
                      value: isPresent,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (val) {
                        controller.markAttendance(student.id, selectedDate, val);
                      },
                    ),
                  ),
                );
              },
            )),
          ),
        ],
      ),
    );
  }
}
