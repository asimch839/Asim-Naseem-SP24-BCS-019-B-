import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'student_controller.dart';

class DashboardScreen extends StatelessWidget {
  final StudentController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            
            // Stats Row
            Obx(() => Row(
              children: [
                Expanded(
                  child: _buildSmallStatCard(
                    'Total Students',
                    '${controller.students.length}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: _buildSmallStatCard(
                    'Fee Status',
                    '${controller.students.where((s) => s.isFeePaid).length} Paid',
                    Icons.payments,
                    Colors.green,
                  ),
                ),
              ],
            )),
            
            SizedBox(height: 30.h),
            Text(
              'Academic Tools',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15.h),
            
            // Feature Grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15.w,
              mainAxisSpacing: 15.h,
              children: [
                _buildMenuCard(
                  'Attendance',
                  Icons.how_to_reg,
                  Colors.orange,
                  () => Get.toNamed('/attendance'),
                ),
                _buildMenuCard(
                  'Exam Results',
                  Icons.assignment_turned_in,
                  Colors.purple,
                  () => Get.toNamed('/results'),
                ),
                _buildMenuCard(
                  'Fee Records',
                  Icons.account_balance_wallet,
                  Colors.teal,
                  () => Get.toNamed('/fee'),
                ),
                _buildMenuCard(
                  'Reports (PDF)',
                  Icons.picture_as_pdf,
                  Colors.red,
                  () {
                    Get.snackbar(
                      'PDF Export',
                      'PDF Generation feature will be available in next update',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }, 
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 10.h),
          Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey, fontSize: 11.sp), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}
