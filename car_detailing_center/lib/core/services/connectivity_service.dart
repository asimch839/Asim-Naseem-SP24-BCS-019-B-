import 'package:get/get.dart';

enum SyncStatus { online, offline, syncing, synced, syncError }

class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.isRegistered<ConnectivityService>() ? Get.find<ConnectivityService>() : ConnectivityService();

  final RxBool isConnected = true.obs;
  final Rx<SyncStatus> syncStatus = SyncStatus.synced.obs;
  final RxString statusMessage = 'Local SQLite Active'.obs;

  void setSyncing() {}
  void setSynced() {}
  void setSyncError(String error) {}
}
