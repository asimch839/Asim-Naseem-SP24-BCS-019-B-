import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'student_controller.dart';
import 'student_form_screen.dart';

class StudentDetailsScreen extends StatelessWidget {
  final String studentId;
  final StudentController controller = Get.find();

  StudentDetailsScreen({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Student Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18.sp)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, size: 22.sp),
            onPressed: () {
              final student = controller.students.firstWhere((s) => s.id == studentId);
              Get.to(() => StudentFormScreen(student: student));
            },
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, size: 22.sp),
            onPressed: () => Get.snackbar('PDF Export', 'Generating report card...', snackPosition: SnackPosition.BOTTOM),
          ),
        ],
      ),
      body: Obx(() {
        final studentIndex = controller.students.indexWhere((s) => s.id == studentId);
        if (studentIndex == -1) return Center(child: Text("Profile not found"));
        
        final student = controller.students[studentIndex];

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      backgroundImage: student.profilePath != null ? FileImage(File(student.profilePath!)) : null,
                      child: student.profilePath == null 
                        ? Text(student.name[0].toUpperCase(), style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: Colors.blue))
                        : null,
                    ),
                    SizedBox(height: 15.h),
                    Text(student.name, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                    Text("Class: ${student.studentClass} (${student.section})", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildChip(student.isFeePaid ? "Fee Paid" : "Unpaid", student.isFeePaid ? Colors.green : Colors.red),
                        SizedBox(width: 10.w),
                        _buildChip("GPA: ${student.gpa}", Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              
              // Marks Summary
              if (student.marks.isNotEmpty)
                _buildSection("Academic Performance", [
                  ...student.marks.entries.map((e) => _buildInfoRow(Icons.book_outlined, e.key, "${e.value} / 100")),
                ]),
              SizedBox(height: 15.h),

              // Contact Information
              _buildSection("Contact Information", [
                _buildInfoRow(Icons.phone, "Phone", student.phoneNumber),
                _buildInfoRow(Icons.email, "Email", student.email),
                _buildInfoRow(Icons.location_on, "Address", student.address),
              ]),
              SizedBox(height: 15.h),
              
              // Academic Details
              _buildSection("Academic Details", [
                _buildInfoRow(Icons.badge, "Roll Number", student.rollNumber),
                _buildInfoRow(Icons.trending_up, "Avg Marks", "${student.averageMarks.toStringAsFixed(1)}%"),
                _buildInfoRow(Icons.payments, "Monthly Fee", "Rs. ${student.monthlyFee}"),
              ]),
              
              SizedBox(height: 30.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: student.isFeePaid ? Colors.grey : Colors.green,
                  minimumSize: Size(double.infinity, 50.h),
                ),
                onPressed: () => controller.updateFeeStatus(student.id, !student.isFeePaid),
                child: Text(student.isFeePaid ? "MARK AS UNPAID" : "MARK FEE AS PAID", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey[800] : Colors.white, 
        borderRadius: BorderRadius.circular(15.r)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Color(0xFF1E88E5))),
          Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.sp)),
    );
  }
}
