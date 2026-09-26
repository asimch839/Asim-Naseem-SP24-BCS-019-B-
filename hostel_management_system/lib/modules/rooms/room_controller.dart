import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/models/room_model.dart';
import '../../data/models/bed_model.dart';
import '../../core/services/app_refresh_service.dart';

class RoomController extends GetxController {
  final RoomRepository _roomRepo = RoomRepository();

  final rooms = <RoomModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final statusFilter = 'All'.obs;

  // Selected room for inspecting bed layout
  final selectedRoom = Rx<RoomModel?>(null);
  final selectedRoomBeds = <BedModel>[].obs;
  final isLoadingBeds = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    isLoading.value = true;
    try {
      final results = await _roomRepo.getAllRooms(
        search: searchQuery.value,
        statusFilter: statusFilter.value,
      );
      rooms.value = results;
      if (selectedRoom.value != null) {
        final updated = results.firstWhereOrNull((r) => r.id == selectedRoom.value!.id);
        if (updated != null) {
          selectRoom(updated);
        } else if (results.isNotEmpty) {
          selectRoom(results.first);
        }
      } else if (results.isNotEmpty) {
        selectRoom(results.first);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load rooms: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectRoom(RoomModel room) async {
    selectedRoom.value = room;
    isLoadingBeds.value = true;
    try {
      if (room.id != null) {
        selectedRoomBeds.value = await _roomRepo.getBedsByRoomId(room.id!);
      }
    } catch (e) {
      debugPrint('Error fetching beds: $e');
    } finally {
      isLoadingBeds.value = false;
    }
  }

  Future<void> saveRoom({
    int? id,
    required String roomNumber,
    required String block,
    required String floor,
    required String roomType,
    required int totalBeds,
    required double monthlyRent,
    String? notes,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      if (id == null) {
        // Create
        final newRoom = RoomModel(
          roomNumber: roomNumber.trim(),
          block: block.trim(),
          floor: floor.trim(),
          roomType: roomType,
          totalBeds: totalBeds,
          monthlyRent: monthlyRent,
          roomStatus: 'Available',
          notes: notes,
          createdAt: now,
        );
        await _roomRepo.createRoom(newRoom);
        if (Get.isDialogOpen == true) Get.back(); // safely close dialog only if open
        Get.snackbar('Success', 'Room $roomNumber created successfully!');
      } else {
        // Update
        final existing = rooms.firstWhere((r) => r.id == id);
        final updated = existing.copyWith(
          roomNumber: roomNumber.trim(),
          block: block.trim(),
          floor: floor.trim(),
          roomType: roomType,
          totalBeds: totalBeds,
          monthlyRent: monthlyRent,
          notes: notes,
        );
        await _roomRepo.updateRoom(updated);
        if (Get.isDialogOpen == true) Get.back();
        Get.snackbar('Success', 'Room $roomNumber updated!');
      }
      await AppRefreshService.refreshAll();
    } catch (e) {
      Get.snackbar('Operation Failed', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> setBedStatus(int bedId, String newStatus) async {
    try {
      await _roomRepo.updateBedStatus(bedId, newStatus);
      if (selectedRoom.value?.id != null) {
        await _roomRepo.syncRoomStatus(selectedRoom.value!.id!);
      }
      await AppRefreshService.refreshAll();
      Get.snackbar('Success', 'Bed status updated to $newStatus');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> deleteRoom(RoomModel room) async {
    try {
      if (room.id != null) {
        await _roomRepo.deleteRoom(room.id!, room.roomNumber);
        Get.snackbar('Success', 'Room ${room.roomNumber} deleted.');
        await AppRefreshService.refreshAll();
      }
    } catch (e) {
      Get.snackbar('Cannot Delete', e.toString().replaceAll('Exception: ', ''));
    }
  }
}
