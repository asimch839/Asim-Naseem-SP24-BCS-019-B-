import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/rent_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/models/student_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/room_allocation_model.dart';
import '../../data/models/room_model.dart';
import '../../data/models/bed_model.dart';
import '../../core/services/app_refresh_service.dart';

class StudentController extends GetxController {
  final StudentRepository _studentRepo = StudentRepository();
  final RentRepository _rentRepo = RentRepository();
  final RoomRepository _roomRepo = RoomRepository();

  final students = <StudentModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final statusFilter = 'Active'.obs; // Default to Active

  // Selected student for detail/history modal
  final selectedStudent = Rx<StudentModel?>(null);
  final studentPaymentHistory = <PaymentModel>[].obs;
  final studentAllocationHistory = <RoomAllocationModel>[].obs;
  final isLoadingHistory = false.obs;

  // Available rooms and beds for transfer modal
  final availableRooms = <RoomModel>[].obs;
  final availableBedsForTransfer = <BedModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    isLoading.value = true;
    try {
      students.value = await _studentRepo.getAllStudents(
        search: searchQuery.value,
        statusFilter: statusFilter.value,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load students: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> viewStudentDetails(StudentModel student) async {
    selectedStudent.value = student;
    isLoadingHistory.value = true;
    try {
      if (student.id != null) {
        studentPaymentHistory.value = await _rentRepo.getStudentPaymentHistory(student.id!);
        studentAllocationHistory.value = await _studentRepo.getStudentAllocations(student.id!);
      }
    } catch (e) {
      debugPrint('Error fetching student history: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> updateStudent(StudentModel updatedStudent) async {
    try {
      await _studentRepo.updateStudent(updatedStudent);
      if (Get.isDialogOpen == true) Get.back(); // safely close modal only if open
      Get.snackbar('Success', 'Student details updated successfully!');
      await AppRefreshService.refreshAll();
      if (selectedStudent.value?.id == updatedStudent.id) {
        selectedStudent.value = await _studentRepo.getStudentById(updatedStudent.id!);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadAvailableRoomsForTransfer() async {
    try {
      availableRooms.value = await _roomRepo.getAllRooms(statusFilter: 'Available');
    } catch (e) {
      debugPrint('Error loading available rooms: $e');
    }
  }

  Future<void> loadAvailableBedsForRoom(int roomId) async {
    try {
      availableBedsForTransfer.value = await _roomRepo.getAvailableBedsByRoomId(roomId);
    } catch (e) {
      debugPrint('Error loading available beds: $e');
    }
  }

  Future<void> transferRoom({
    required int studentId,
    required int newRoomId,
    required int newBedId,
    required String transferDate,
    String? reason,
  }) async {
    try {
      await _studentRepo.changeRoom(
        studentId: studentId,
        newRoomId: newRoomId,
        newBedId: newBedId,
        transferDate: transferDate,
        reason: reason,
      );
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('Success', 'Student room changed successfully! History recorded.');
      await AppRefreshService.refreshAll();
      if (selectedStudent.value?.id == studentId) {
        await viewStudentDetails((await _studentRepo.getStudentById(studentId))!);
      }
    } catch (e) {
      Get.snackbar('Transfer Failed', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> markStudentAsLeft({
    required int studentId,
    required String leavingDate,
    String? reason,
    double adjustSecurityToRent = 0.0,
    double refundSecurityAmount = 0.0,
    String? settlementNotes,
  }) async {
    try {
      await _studentRepo.markStudentAsLeft(
        studentId: studentId,
        leavingDate: leavingDate,
        reason: reason,
        adjustSecurityToRent: adjustSecurityToRent,
        refundSecurityAmount: refundSecurityAmount,
        settlementNotes: settlementNotes,
      );
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('Departure Completed', 'Student marked as Left. Bed released & security settlement finalized.');
      await AppRefreshService.refreshAll();
    } catch (e) {
      Get.snackbar('Action Failed', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<double> getStudentPendingRent(int studentId) async {
    try {
      return await _studentRepo.getStudentPendingRentTotal(studentId);
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> deleteStudent(StudentModel student) async {
    try {
      if (student.id != null) {
        await _studentRepo.deleteStudent(student.id!);
        Get.snackbar('Deleted', 'Student "${student.fullName}" deleted successfully.');
        await AppRefreshService.refreshAll();
      }
    } catch (e) {
      Get.snackbar('Delete Failed', e.toString().replaceAll('Exception: ', ''));
    }
  }
}
