import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/student_model.dart';
import '../../data/models/room_model.dart';
import '../../data/models/bed_model.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../layout/main_layout_controller.dart';
import '../../core/services/app_refresh_service.dart';

class AdmissionController extends GetxController {
  final StudentRepository _studentRepo = StudentRepository();
  final RoomRepository _roomRepo = RoomRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final studentCodeCtrl = TextEditingController();
  final fullNameCtrl = TextEditingController();
  final fatherNameCtrl = TextEditingController();
  final cnicCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emergencyPhoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final universityCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();
  final semesterCtrl = TextEditingController();
  final rentCtrl = TextEditingController();
  final depositCtrl = TextEditingController();
  final admissionDateCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  // Hints
  final rentHint = 'e.g. 15000'.obs;
  final depositHint = 'e.g. 5000 or 0'.obs;

  // State
  final availableRooms = <RoomModel>[].obs;
  final availableBeds = <BedModel>[].obs;
  final selectedRoom = Rx<RoomModel?>(null);
  final selectedBed = Rx<BedModel?>(null);
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    prepareNewAdmission();
  }

  Future<void> prepareNewAdmission() async {
    admissionDateCtrl.text = DateFormatter.toIsoDate(DateTime.now());
    selectedRoom.value = null;
    selectedBed.value = null;
    availableBeds.clear();
    fullNameCtrl.clear();
    fatherNameCtrl.clear();
    cnicCtrl.clear();
    phoneCtrl.clear();
    emergencyPhoneCtrl.clear();
    addressCtrl.clear();
    universityCtrl.clear();
    departmentCtrl.clear();
    semesterCtrl.clear();
    rentCtrl.clear();
    depositCtrl.clear();
    notesCtrl.clear();

    try {
      studentCodeCtrl.text = await _studentRepo.generateNextStudentCode();
      final settings = await _settingsRepo.getSettings();
      rentHint.value = 'e.g. ${settings.defaultMonthlyRent.toStringAsFixed(0)}';
      availableRooms.value = await _roomRepo.getAllRooms(statusFilter: 'Available');
    } catch (e) {
      debugPrint('Error preparing admission: $e');
    }
  }

  Future<void> onRoomSelected(RoomModel? room) async {
    selectedRoom.value = room;
    selectedBed.value = null;
    availableBeds.clear();

    if (room != null && room.id != null) {
      if (room.monthlyRent > 0) {
        rentHint.value = 'e.g. ${room.monthlyRent.toStringAsFixed(0)}';
      }
      availableBeds.value = await _roomRepo.getAvailableBedsByRoomId(room.id!);
    }
  }

  Future<void> submitAdmission() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedRoom.value == null) {
      Get.snackbar('Room Required', 'Please select an available room.');
      return;
    }

    if (selectedBed.value == null) {
      Get.snackbar('Bed Required', 'Please select an available bed.');
      return;
    }

    isSubmitting.value = true;
    try {
      final newStudent = StudentModel(
        studentIdCode: studentCodeCtrl.text.trim(),
        fullName: fullNameCtrl.text.trim(),
        fatherName: fatherNameCtrl.text.trim(),
        cnic: cnicCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        emergencyContact: emergencyPhoneCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        university: universityCtrl.text.trim(),
        department: departmentCtrl.text.trim(),
        semester: semesterCtrl.text.trim(),
        admissionDate: admissionDateCtrl.text.trim(),
        currentRoomId: selectedRoom.value!.id,
        currentBedId: selectedBed.value!.id,
        monthlyRent: double.tryParse(rentCtrl.text) ?? 15000.0,
        securityDeposit: double.tryParse(depositCtrl.text) ?? 0.0,
        status: 'Active',
        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _studentRepo.admitStudent(
        student: newStudent,
        roomId: selectedRoom.value!.id!,
        bedId: selectedBed.value!.id!,
        monthlyRent: double.tryParse(rentCtrl.text) ?? 15000.0,
        securityDeposit: double.tryParse(depositCtrl.text) ?? 0.0,
        admissionDate: admissionDateCtrl.text.trim(),
        admissionNotes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
      );

      Get.snackbar('Admission Successful!', 'Student ${newStudent.fullName} admitted to Room ${selectedRoom.value!.roomNumber}.');
      
      // Real-time synchronization across all modules
      await AppRefreshService.refreshAll();

      // Navigate to Students module
      Get.find<MainLayoutController>().setNavIndex(1);
    } catch (e) {
      Get.snackbar('Admission Failed', e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    studentCodeCtrl.dispose();
    fullNameCtrl.dispose();
    fatherNameCtrl.dispose();
    cnicCtrl.dispose();
    phoneCtrl.dispose();
    emergencyPhoneCtrl.dispose();
    addressCtrl.dispose();
    universityCtrl.dispose();
    departmentCtrl.dispose();
    semesterCtrl.dispose();
    rentCtrl.dispose();
    depositCtrl.dispose();
    admissionDateCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}
