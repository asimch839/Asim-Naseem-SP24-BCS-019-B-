import 'package:get/get.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  static NotificationController get to => Get.find();

  final NotificationRepository _repo = NotificationRepository();
  final RxInt unreadCount = 0.obs;
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshReminders();
  }

  Future<void> refreshReminders() async {
    isLoading.value = true;
    try {
      await _repo.refreshReminders();
      await loadNotifications();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNotifications() async {
    final list = await _repo.getNotifications();
    notifications.assignAll(list);
    unreadCount.value = await _repo.getUnreadCount();
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    await loadNotifications();
  }
}
