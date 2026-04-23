package com.safecall.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat

class PhoneStateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        if (!AppSettings.isProtectionEnabled(context)) return

        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: "Unknown"

        when (intent.getStringExtra(TelephonyManager.EXTRA_STATE)) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                val serviceIntent = Intent(context, OverlayService::class.java).apply {
                    action = OverlayService.ACTION_START
                    putExtra(OverlayService.EXTRA_PHONE_NUMBER, number)
                }
                ContextCompat.startForegroundService(context, serviceIntent)
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                val serviceIntent = Intent(context, OverlayService::class.java).apply {
                    action = OverlayService.ACTION_STOP
                }
                context.startService(serviceIntent)
            }
        }
    }
}
