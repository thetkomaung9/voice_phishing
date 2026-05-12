package com.safecall.ai

import android.content.Intent
import android.net.Uri
import android.app.role.RoleManager
import android.os.Build
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.text.TextUtils
import java.util.Locale
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "com.safecall.ai/callMonitor"
        const val EVENT_CHANNEL  = "com.safecall.ai/callEvents"
        const val OVERLAY_REQUEST_CODE = 1234
    }

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var textToSpeech: TextToSpeech? = null
    private var isTextToSpeechReady = false
    private var pendingTextCallSpeech: Pair<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Method Channel ──────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMonitoring" -> {
                        val number = call.argument<String>("phoneNumber") ?: "Unknown"
                        val intent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_START
                            putExtra(OverlayService.EXTRA_PHONE_NUMBER, number)
                        }
                        startForegroundService(intent)
                        result.success(null)
                    }
                    "stopMonitoring" -> {
                        val intent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "hasOverlayPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }
                    "requestOverlayPermission" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivityForResult(intent, OVERLAY_REQUEST_CODE)
                        result.success(null)
                    }
                    "setProtectionEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        AppSettings.setProtectionEnabled(this, enabled)
                        result.success(null)
                    }
                    "getProtectionEnabled" -> {
                        result.success(AppSettings.isProtectionEnabled(this))
                    }
                    "setPreferredLanguage" -> {
                        val languageCode = call.argument<String>("languageCode") ?: "en"
                        AppSettings.setTargetLanguage(this, languageCode)
                        result.success(null)
                    }
                    "setCloudTranslationApiKey" -> {
                        val apiKey = call.argument<String>("apiKey").orEmpty()
                        AppSettings.setCloudTranslateApiKey(this, apiKey)
                        result.success(null)
                    }
                    "getPreferredLanguage" -> {
                        result.success(AppSettings.getTargetLanguage(this))
                    }
                    "openCallScreeningSettings" -> {
                        openCallScreeningSettings()
                        result.success(null)
                    }
                    "isCallScreeningEnabled" -> {
                        result.success(isCallScreeningEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "isSamsungTextCallCaptureEnabled" -> {
                        result.success(isSamsungTextCallCaptureEnabled())
                    }
                    "speakTextCallMessage" -> {
                        val text = call.argument<String>("text").orEmpty()
                        val languageCode = call.argument<String>("languageCode") ?: "en"
                        speakTextCallMessage(text, languageCode)
                        result.success(null)
                    }
                    "stopTextCallSpeaker" -> {
                        textToSpeech?.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Event Channel ───────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var eventJob: Job? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventJob = CallEventBus.events
                        .onEach { payload -> events.success(payload) }
                        .launchIn(scope)
                }

                override fun onCancel(arguments: Any?) {
                    eventJob?.cancel()
                    eventJob = null
                }
            })
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        scope.cancel()
        super.onDestroy()
    }

    private fun openCallScreeningSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            roleManager?.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
        } else {
            Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
        }

        startActivity(intent ?: Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS))
    }

    private fun isCallScreeningEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return false
        }

        val roleManager = getSystemService(RoleManager::class.java) ?: return false
        return roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun isSamsungTextCallCaptureEnabled(): Boolean {
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val expected = "$packageName/${SamsungTextCallAccessibilityService::class.java.name}"
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        for (service in splitter) {
            if (service.equals(expected, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    private fun speakTextCallMessage(text: String, languageCode: String) {
        if (text.isBlank()) {
            return
        }

        if (textToSpeech == null) {
            pendingTextCallSpeech = text to languageCode
            textToSpeech = TextToSpeech(applicationContext) { status ->
                isTextToSpeechReady = status == TextToSpeech.SUCCESS
                val pending = pendingTextCallSpeech ?: return@TextToSpeech
                if (isTextToSpeechReady) {
                    playTextCallMessage(pending.first, pending.second)
                }
                pendingTextCallSpeech = null
            }
            return
        }

        if (!isTextToSpeechReady) {
            pendingTextCallSpeech = text to languageCode
            return
        }

        playTextCallMessage(text, languageCode)
    }

    private fun playTextCallMessage(text: String, languageCode: String) {
        val tts = textToSpeech ?: return
        val locale = Locale.forLanguageTag(languageCode.replace('_', '-'))
        val availability = tts.setLanguage(locale)
        if (availability == TextToSpeech.LANG_MISSING_DATA ||
            availability == TextToSpeech.LANG_NOT_SUPPORTED) {
            tts.setLanguage(Locale.ENGLISH)
        }
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "safe_call_text_call")
    }
}
