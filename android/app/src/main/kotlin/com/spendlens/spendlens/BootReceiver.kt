package com.spendlens.spendlens

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts [SmsListenerService] after the device reboots so real-time SMS
 * detection continues without requiring the user to open the app.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val serviceIntent = Intent(context, SmsListenerService::class.java)
        context.startForegroundService(serviceIntent)
    }
}
