package com.safecall.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Monitoring starts only on incoming calls via PhoneStateReceiver/CallScreeningService.
        // This receiver exists for future use (e.g., restoring user settings on reboot).
    }
}
