package com.recallbutler.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Smart Reminders Channel
            val remindersChannel = NotificationChannel(
                "recall_butler_reminders",
                "Smart Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Proactive reminders based on your memories and context"
                enableVibration(true)
                enableLights(true)
            }
            notificationManager.createNotificationChannel(remindersChannel)
            
            // Document Updates Channel
            val documentsChannel = NotificationChannel(
                "recall_butler_documents",
                "Document Updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications about document processing and sync status"
            }
            notificationManager.createNotificationChannel(documentsChannel)
            
            // AI Suggestions Channel
            val suggestionsChannel = NotificationChannel(
                "recall_butler_suggestions",
                "AI Suggestions",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Smart suggestions from the AI assistant"
            }
            notificationManager.createNotificationChannel(suggestionsChannel)
            
            // Calendar Events Channel
            val calendarChannel = NotificationChannel(
                "recall_butler_calendar",
                "Calendar Integration",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Reminders before calendar events with relevant memories"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(calendarChannel)
        }
    }
}
