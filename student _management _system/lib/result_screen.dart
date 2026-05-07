import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'student_controller.dart';
import 'student_model.dart';

class ResultScreen extends StatelessWidget {
  final StudentController controller = Get.find();
  final List<String> subjects = ['English', 'Mathematics', 'Science', 'History', 'Urdu'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Result Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Obx(() => ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: controller.students.length,
        itemBuilder: (context, index) {
          final student = controller.students[index];
          return Card(
            margin: EdgeInsets.only(bottom: 15.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFF1E88E5).withOpacity(0.1),
                child: Text(student.name[0], style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              subtitle: Text("GPA: ${student.gpa} | Avg: ${student.averageMarks.toStringAsFixed(1)}%"),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Column(
                    children: [
                      ...subjects.map((subject) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            children: [
                              Expanded(child: Text(subject, style: TextStyle(fontSize: 14.sp))),
                              SizedBox(
                                width: 80.w,
                                child: TextFormField(
                                  initialValue: student.marks[subject]?.toString() ?? '0',
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                                    isDense: true,
                                  ),
                                  onFieldSubmitted: (val) {
                                    double score = double.tryParse(val) ?? 0.0;
                                    controller.updateMarks(student.id, subject, score);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 10.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.snackbar('Saved', 'Marks updated for ${student.name}', backgroundColor: Colors.green, colorText: Colors.white);
                        },
                        icon: Icon(Icons.check_circle, size: 18.sp),
                        label: Text('Save Result'),
                        style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40.h)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      )),
    );
  }
}
