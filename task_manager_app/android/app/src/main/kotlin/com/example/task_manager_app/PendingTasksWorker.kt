// PendingTasksWorker.kt
package com.example.task_manager_app

import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters

class PendingTasksWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : Worker(appContext, workerParams) {

    override fun doWork(): Result {
        // TODO: Replace with actual DB query to count today's pending tasks
        val pendingTasksCount = 3

        if (pendingTasksCount > 0) {
            val notification = NotificationCompat.Builder(applicationContext, "pending_tasks_channel")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("Pending Tasks")
                .setContentText("You have $pendingTasksCount pending tasks today.")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            NotificationManagerCompat.from(applicationContext).notify(1001, notification)
        }

        return Result.success()
    }
}
