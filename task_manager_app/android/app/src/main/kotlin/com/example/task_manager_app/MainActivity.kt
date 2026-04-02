package com.example.task_manager_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onResume() {
        super.onResume()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Pending Tasks"
            val descriptionText = "Notifications for pending tasks"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel("pending_tasks_channel", name, importance)
            channel.description = descriptionText
            val notificationManager: NotificationManager =
                getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
