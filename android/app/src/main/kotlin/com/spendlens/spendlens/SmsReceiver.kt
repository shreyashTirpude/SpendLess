package com.spendlens.spendlens

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * Receives SMS_RECEIVED broadcasts and starts [SmsListenerService] to handle
 * the message in a foreground service (keeps process alive on Doze).
 */
class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        val body = messages.joinToString("") { it.messageBody }
        val sender = messages.firstOrNull()?.originatingAddress ?: ""

        val serviceIntent = Intent(context, SmsListenerService::class.java).apply {
            putExtra(SmsListenerService.EXTRA_BODY, body)
            putExtra(SmsListenerService.EXTRA_SENDER, sender)
            putExtra(SmsListenerService.EXTRA_TIMESTAMP, System.currentTimeMillis())
        }
        context.startForegroundService(serviceIntent)
    }
}
