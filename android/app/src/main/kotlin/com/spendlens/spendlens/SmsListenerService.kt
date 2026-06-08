package com.spendlens.spendlens

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service that keeps the process alive long enough to persist an
 * incoming bank SMS to Hive via the telephony Flutter plugin's Dart isolate.
 *
 * When started with EXTRA_BODY the service notifies Flutter via a method
 * channel if the app is in the foreground; otherwise it stores the payload
 * for the next Flutter startup via SharedPreferences so the Dart layer can
 * pick it up.
 */
class SmsListenerService : Service() {

    companion object {
        const val EXTRA_BODY = "sms_body"
        const val EXTRA_SENDER = "sms_sender"
        const val EXTRA_TIMESTAMP = "sms_timestamp"

        private const val CHANNEL_ID = "spendlens_sms_channel"
        private const val NOTIF_ID = 1001
        private const val PREFS_NAME = "spendlens_pending_sms"
        private const val PREFS_KEY_BODY = "pending_sms_body"
        private const val PREFS_KEY_TS = "pending_sms_ts"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val body = intent?.getStringExtra(EXTRA_BODY)
        val ts = intent?.getLongExtra(EXTRA_TIMESTAMP, System.currentTimeMillis())
            ?: System.currentTimeMillis()

        if (!body.isNullOrBlank()) {
            // Persist for Dart to read on next resume
            getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                .putString(PREFS_KEY_BODY, body)
                .putLong(PREFS_KEY_TS, ts)
                .apply()
        }

        stopSelf(startId)
        return START_NOT_STICKY
    }

    private fun buildNotification(): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SpendLens")
            .setContentText("Monitoring bank SMS…")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

    private fun createNotificationChannel() {
        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (mgr.getNotificationChannel(CHANNEL_ID) == null) {
            mgr.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "SpendLens SMS Monitor",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
        }
    }
}
