import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'student_controller.dart';
import 'student_model.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;

  StudentFormScreen({this.student});

  @override
  _StudentFormScreenState createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final StudentController controller = Get.find();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController rollController;
  late TextEditingController emailController;
  late TextEditingController classController;
  late TextEditingController sectionController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController feeController;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student?.name ?? '');
    rollController = TextEditingController(text: widget.student?.rollNumber ?? '');
    emailController = TextEditingController(text: widget.student?.email ?? '');
    classController = TextEditingController(text: widget.student?.studentClass ?? '');
    sectionController = TextEditingController(text: widget.student?.section ?? '');
    phoneController = TextEditingController(text: widget.student?.phoneNumber ?? '');
    addressController = TextEditingController(text: widget.student?.address ?? '');
    feeController = TextEditingController(text: widget.student?.monthlyFee.toString() ?? '0.0');
    _selectedImagePath = widget.student?.profilePath;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    rollController.dispose();
    emailController.dispose();
    classController.dispose();
    sectionController.dispose();
    phoneController.dispose();
    addressController.dispose();
    feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.student != null;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Profile' : 'New Registration',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18.sp),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50.r,
                          backgroundColor: Color(0xFF1E88E5).withOpacity(0.1),
                          backgroundImage: _selectedImagePath != null ? FileImage(File(_selectedImagePath!)) : null,
                          child: _selectedImagePath == null 
                            ? Icon(Icons.person_outline_rounded, size: 60.sp, color: Color(0xFF1E88E5))
                            : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Color(0xFF1E88E5),
                            radius: 18.r,
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 18.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  'Personal Details',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                _buildTextField(controller: nameController, label: 'Full Name', icon: Icons.person_outline),
                SizedBox(height: 16.h),
                _buildTextField(controller: phoneController, label: 'Phone Number', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                SizedBox(height: 16.h),
                _buildTextField(controller: emailController, label: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 16.h),
                _buildTextField(controller: addressController, label: 'Home Address', icon: Icons.location_on_outlined, maxLines: 2),
                
                SizedBox(height: 32.h),
                Text(
                  'Academic Details',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: rollController, label: 'Roll No', icon: Icons.badge_outlined)),
                    SizedBox(width: 16.w),
                    Expanded(child: _buildTextField(controller: classController, label: 'Class', icon: Icons.school_outlined)),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: sectionController, label: 'Section', icon: Icons.grid_view_rounded)),
                    SizedBox(width: 16.w),
                    Expanded(child: _buildTextField(controller: feeController, label: 'Monthly Fee', icon: Icons.attach_money_rounded, keyboardType: TextInputType.number)),
                  ],
                ),
                
                SizedBox(height: 40.h),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Student studentObj = Student(
                        id: isEditing ? widget.student!.id : DateTime.now().toString(),
                        name: nameController.text,
                        rollNumber: rollController.text,
                        studentClass: classController.text,
                        section: sectionController.text,
                        phoneNumber: phoneController.text,
                        email: emailController.text,
                        address: addressController.text,
                        profilePath: _selectedImagePath,
                        monthlyFee: double.tryParse(feeController.text) ?? 0.0,
                        attendance: isEditing ? widget.student!.attendance : {},
                        marks: isEditing ? widget.student!.marks : {},
                        isFeePaid: isEditing ? widget.student!.isFeePaid : false,
                      );

                      if (isEditing) {
                        controller.updateStudent(studentObj);
                        Get.back();
                        Get.snackbar(
                          'Updated', 
                          'Student information updated', 
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.blue, 
                          colorText: Colors.white,
                          margin: EdgeInsets.all(15.r),
                        );
                      } else {
                        controller.addStudent(studentObj);
                        Get.back();
                        Get.snackbar(
                          'Success', 
                          'Student added successfully', 
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green, 
                          colorText: Colors.white,
                          margin: EdgeInsets.all(15.r),
                        );
                      }
                    }
                  },
                  child: Text(
                    isEditing ? 'UPDATE STUDENT' : 'REGISTER STUDENT',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp),
        prefixIcon: Icon(icon, color: Color(0xFF1E88E5), size: 20.sp),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}
