package com.example.task_manager_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class UnlockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_USER_PRESENT) {
            val notification = NotificationCompat.Builder(context, "pending_tasks_channel")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("Pending Tasks")
                .setContentText("You have pending tasks!")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            NotificationManagerCompat.from(context).notify(1001, notification)
        }
    }
}
