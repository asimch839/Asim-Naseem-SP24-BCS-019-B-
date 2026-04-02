package com.example.task_manager_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

fun createNotificationChannel(context: Context) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val name = "Pending Tasks"
        val descriptionText = "Notifications for pending tasks"
        val importance = NotificationManager.IMPORTANCE_HIGH
        val channel = NotificationChannel("pending_tasks_channel", name, importance)
        channel.description = descriptionText
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }
}
