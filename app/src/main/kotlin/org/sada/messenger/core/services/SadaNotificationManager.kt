package org.sada.messenger.core.services

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.sada.messenger.MainActivity
import org.sada.messenger.R

class SadaNotificationManager(private val context: Context) {
    companion object {
        private const val MESSAGES_CHANNEL_ID = "sada_messages"
        private const val MESSAGES_CHANNEL_NAME = "Sada Messages"
        private const val SOS_CHANNEL_ID = "sada_emergency"
        private const val SOS_CHANNEL_NAME = "Sada Emergency"
    }

    fun showIncomingMessageNotification(
        chatId: String,
        title: String,
        body: String
    ) {
        if (!hasNotificationPermission()) return
        ensureChannels()

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("open_chat_id", chatId)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            chatId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, MESSAGES_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_notify_chat)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .build()

        NotificationManagerCompat.from(context).notify(("msg_$chatId").hashCode(), notification)
    }

    fun showSosNotification(body: String) {
        if (!hasNotificationPermission()) return
        ensureChannels()

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            "sos".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, SOS_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setContentTitle("Sada SOS")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .build()

        NotificationManagerCompat.from(context).notify("sos_alert".hashCode(), notification)
    }

    private fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val messagesChannel = NotificationChannel(
            MESSAGES_CHANNEL_ID,
            MESSAGES_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Incoming chat notifications"
            setShowBadge(true)
        }

        val sosChannel = NotificationChannel(
            SOS_CHANNEL_ID,
            SOS_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Emergency SOS alerts"
            setShowBadge(true)
        }

        manager.createNotificationChannel(messagesChannel)
        manager.createNotificationChannel(sosChannel)
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
