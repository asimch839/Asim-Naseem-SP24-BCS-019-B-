import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BootReceiver {
  static Future<void> showBootNotification(int count) async {
    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.show(
      99,
      "Pending Tasks",
      "You have $count pending tasks",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pending_boot_channel',
          'Boot Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
