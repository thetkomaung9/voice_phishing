package com.safecall.ai

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import androidx.core.content.ContextCompat
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch

// ── Event bus: OverlayService → Flutter EventChannel ──────────────────────
object CallEventBus {
    val _events = MutableSharedFlow<Map<String, Any>>(extraBufferCapacity = 128)
    val events = _events.asSharedFlow()
}

class OverlayService : Service() {

    companion object {
        const val ACTION_START = "com.safecall.ai.OVERLAY_START"
        const val ACTION_STOP = "com.safecall.ai.OVERLAY_STOP"
        const val EXTRA_PHONE_NUMBER = "phone_number"
        private const val CHANNEL_ID = "safecall_monitor"
        private const val NOTIFICATION_ID = 1001
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private lateinit var sttManager: SpeechRecognitionManager
    private val detector = PhishingDetector()
    private var translationManager: TranslationManager? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var phoneNumber = "Unknown"
    private val fullTranscript = StringBuilder()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        sttManager = SpeechRecognitionManager(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                if (!AppSettings.isProtectionEnabled(this)) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                phoneNumber = intent.getStringExtra(EXTRA_PHONE_NUMBER) ?: "Unknown"
                ensureTranslator()
                val hasMic = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && hasMic) {
                    startForeground(NOTIFICATION_ID, buildNotification(),
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
                } else {
                    startForeground(NOTIFICATION_ID, buildNotification())
                }
                showOverlay()
                if (hasMic) startMonitoring()
            }
            ACTION_STOP -> {
                cleanup()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    // ── STT + Detection + Translation pipeline ────────────────────────────
    private fun startMonitoring() {
        fullTranscript.clear()
        sttManager.start(
            onPartial = { partial ->
                updateOverlayTranscript(partial)
                val result = detector.analyze("$fullTranscript $partial")
                updateOverlayRisk(result)
                emitEvent(partial, result)
            },
            onFinal = { final ->
                if (final.isNotBlank()) {
                    fullTranscript.append(" ").append(final)
                    translationManager?.translate(final) { translated ->
                        updateOverlayTranslation(translated)
                    }
                    val result = detector.analyze(fullTranscript.toString())
                    updateOverlayRisk(result)
                    emitEvent(final, result)
                }
            }
        )
    }

    private fun ensureTranslator() {
        translationManager?.close()
        translationManager = TranslationManager(AppSettings.getTargetLanguage(this))
        translationManager?.downloadModelIfNeeded {}
    }

    private fun emitEvent(transcript: String, result: PhishingResult) {
        scope.launch {
            CallEventBus._events.emit(
                mapOf(
                    "type" to "update",
                    "transcript" to transcript,
                    "risk_level" to result.riskLevel,
                    "is_phishing" to result.isPhishing,
                    "alert_level" to result.alertLevel,
                    "message" to result.message,
                    "reason" to result.reason,
                    "recommended_action" to result.recommendedAction,
                    "score" to result.score,
                    "phone_number" to phoneNumber
                )
            )
        }
    }

    // ── Overlay window ───────────────────────────────────────────────────
    private fun showOverlay() {
        if (!Settings.canDrawOverlays(this)) return
        removeOverlay()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_call_assistant, null)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP
            y = 100
        }

        overlayView?.let { view ->
            view.findViewById<Button>(R.id.btn112)?.setOnClickListener { dialEmergency("112") }
            view.findViewById<Button>(R.id.btn119)?.setOnClickListener { dialEmergency("119") }
            view.findViewById<Button>(R.id.btnDismiss)?.setOnClickListener { removeOverlay() }
            windowManager?.addView(view, params)
        }
    }

    private fun removeOverlay() {
        overlayView?.let {
            try { windowManager?.removeView(it) } catch (_: Exception) {}
        }
        overlayView = null
    }

    private fun updateOverlayTranscript(text: String) {
        overlayView?.post {
            overlayView?.findViewById<TextView>(R.id.tvTranscript)?.text = text
        }
    }

    private fun updateOverlayTranslation(text: String) {
        overlayView?.post {
            overlayView?.findViewById<TextView>(R.id.tvTranslation)?.text = text
        }
    }

    private fun updateOverlayRisk(result: PhishingResult) {
        overlayView?.post {
            val tv = overlayView?.findViewById<TextView>(R.id.tvWarning) ?: return@post
            if (result.riskLevel >= 2) {
                tv.visibility = View.VISIBLE
                tv.text = "⚠️  ${result.message}"
            } else {
                tv.visibility = View.GONE
            }
        }
    }

    private fun dialEmergency(number: String) {
        val dialIntent = Intent(Intent.ACTION_DIAL).apply {
            data = android.net.Uri.parse("tel:$number")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(dialIntent)
    }

    private fun cleanup() {
        sttManager.stop()
        translationManager?.close()
        removeOverlay()
    }

    override fun onDestroy() {
        cleanup()
        scope.cancel()
        super.onDestroy()
    }

    // ── Foreground notification ──────────────────────────────────────────
    private fun buildNotification(): Notification {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID, "Safe Call Monitor",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Safe-Call AI Active")
            .setContentText("Monitoring call from $phoneNumber")
            .setSmallIcon(android.R.drawable.stat_notify_call_mute)
            .setOngoing(true)
            .build()
    }
}
