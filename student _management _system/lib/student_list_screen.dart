import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'student_controller.dart';
import 'student_details_screen.dart';

class StudentListScreen extends StatefulWidget {
  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentController controller = Get.find();
  final TextEditingController searchController = TextEditingController();
  String selectedClass = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: EdgeInsets.all(16.r),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (val) => controller.filterStudents(val),
                  decoration: InputDecoration(
                    hintText: 'Search by Name or Roll No...',
                    prefixIcon: Icon(Icons.search, size: 20.sp),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: 10.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', '1st Year', '2nd Year', 'BSCS', 'BBA', 'SE'].map((className) {
                      bool isSelected = selectedClass == className;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text(className),
                          selected: isSelected,
                          selectedColor: Color(0xFF1E88E5),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          onSelected: (val) {
                            setState(() => selectedClass = className);
                            // Custom filter logic can be added in controller
                            if(className == 'All') {
                              controller.filterStudents(searchController.text);
                            } else {
                              controller.filteredStudents.assignAll(
                                controller.students.where((s) => s.studentClass == className).toList()
                              );
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (controller.filteredStudents.isEmpty) {
                return Center(child: Text('No students found'));
              }
              return ListView.builder(
                padding: EdgeInsets.all(16.r),
                itemCount: controller.filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = controller.filteredStudents[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF1E88E5).withOpacity(0.1),
                        child: Text(student.name[0]),
                      ),
                      title: Text(student.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Roll: ${student.rollNumber} | Class: ${student.studentClass}"),
                      trailing: Icon(Icons.chevron_right, size: 20.sp),
                      onTap: () => Get.to(() => StudentDetailsScreen(studentId: student.id)),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-student'),
        backgroundColor: Color(0xFF1E88E5),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
