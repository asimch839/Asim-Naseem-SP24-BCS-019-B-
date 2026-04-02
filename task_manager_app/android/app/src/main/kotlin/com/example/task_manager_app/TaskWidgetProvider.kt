package com.example.task_manager_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences

class TaskWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val pendingTasks = prefs.getInt("flutter.prefs.pendingTasks", 0) // Flutter automatically prefixes keys

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            views.setTextViewText(R.id.widgetText, "Tasks Pending: $pendingTasks")
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
