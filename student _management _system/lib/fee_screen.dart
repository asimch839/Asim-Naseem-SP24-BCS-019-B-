import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'student_controller.dart';

class FeeScreen extends StatelessWidget {
  final StudentController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Fee Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        int paidCount = controller.students.where((s) => s.isFeePaid).length;
        int unpaidCount = controller.students.length - paidCount;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Paid", paidCount.toString(), Colors.green),
                  _buildStatItem("Unpaid", unpaidCount.toString(), Colors.red),
                  _buildStatItem("Total", controller.students.length.toString(), Colors.blue),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.r),
                itemCount: controller.students.length,
                itemBuilder: (context, index) {
                  final student = controller.students[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12.h),
                    child: ListTile(
                      title: Text(student.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Rs. ${student.monthlyFee}"),
                      trailing: ActionChip(
                        label: Text(student.isFeePaid ? "PAID" : "UNPAID"),
                        backgroundColor: student.isFeePaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        labelStyle: TextStyle(color: student.isFeePaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        onPressed: () => controller.updateFeeStatus(student.id, !student.isFeePaid),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
      ],
    );
  }
}
