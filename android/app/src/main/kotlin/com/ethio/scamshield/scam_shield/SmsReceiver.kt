package com.ethio.scamshield.scam_shield

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class SmsReceiver : BroadcastReceiver() {
    companion object {
        var smsCallback: ((String, String) -> Unit)? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNotEmpty()) {
                val sender = messages[0].originatingAddress ?: "Unknown"
                val body = messages.joinToString("") { it.messageBody ?: "" }
                smsCallback?.invoke(sender, body)
            }
        }
    }
}
