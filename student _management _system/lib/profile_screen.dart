import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isDarkMode = Get.isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 180.h,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45.r,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 55.sp, color: Color(0xFF1E88E5)),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Admin User',
                    style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Settings", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 10.h),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                    child: SwitchListTile(
                      title: Text("Dark Mode", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
                      secondary: Icon(Icons.dark_mode, color: Colors.amber),
                      value: isDarkMode,
                      onChanged: (val) {
                        setState(() => isDarkMode = val);
                        Get.changeThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text("Account Info", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 10.h),
                  _buildProfileItem(Icons.email, 'Email', 'admin@system.com'),
                  _buildProfileItem(Icons.phone, 'Phone', '+92 300 1234567'),
                  _buildProfileItem(Icons.school, 'Role', 'System Administrator'),

                  SizedBox(height: 30.h),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: Size(double.infinity, 50.h),
                    ),
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Logout',
                        middleText: 'Are you sure you want to logout?',
                        onConfirm: () => Get.offAllNamed('/login'),
                        textConfirm: 'Logout',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.redAccent,
                      );
                    },
                    child: Text('LOGOUT', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF1E88E5), size: 22.sp),
        title: Text(title, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        subtitle: Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
