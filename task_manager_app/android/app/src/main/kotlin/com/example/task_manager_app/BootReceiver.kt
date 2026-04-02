package com.example.task_manager_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class BootReceiver : BroadcastReceiver() {

    private val CHANNEL = "pending_tasks_channel_method"

    override fun onReceive(context: Context, intent: Intent?) {

        // Only handle unlock event
        if (intent?.action == Intent.ACTION_USER_PRESENT) {

            val engine = FlutterEngine(context)
            engine.dartExecutor.binaryMessenger.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("checkTasks", null)
            }

            FlutterEngineCache.getInstance().put("my_engine", engine)
        }
    }
}
