package com.safecall.ai

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import android.content.Intent

@RequiresApi(Build.VERSION_CODES.N)
class VoicePhishingScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val number = callDetails.handle?.schemeSpecificPart ?: "Unknown"

        // Always allow the call — we monitor only, never block
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSilenceCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()

        respondToCall(callDetails, response)

        if (!AppSettings.isProtectionEnabled(this)) {
            return
        }

        // Launch overlay monitoring service
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
            putExtra(OverlayService.EXTRA_PHONE_NUMBER, number)
        }
        ContextCompat.startForegroundService(this, intent)
    }
}
