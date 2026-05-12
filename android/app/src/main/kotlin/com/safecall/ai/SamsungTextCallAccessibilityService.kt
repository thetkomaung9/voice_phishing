package com.safecall.ai

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class SamsungTextCallAccessibilityService : AccessibilityService() {

    private var lastTranscript = ""
    private var lastEmitAtMs = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!AppSettings.isProtectionEnabled(this)) return

        val packageName = event?.packageName?.toString().orEmpty()
        if (packageName == applicationContext.packageName) return

        val root = rootInActiveWindow ?: return
        val transcript = extractVisibleText(root)
        if (transcript.isBlank() || transcript == lastTranscript) return

        val now = System.currentTimeMillis()
        if (now - lastEmitAtMs < 800L) return

        lastTranscript = transcript
        lastEmitAtMs = now
        OverlayService.processExternalTranscript(transcript)
    }

    override fun onInterrupt() = Unit

    private fun extractVisibleText(root: AccessibilityNodeInfo): String {
        val lines = linkedSetOf<String>()
        collectText(root, lines)
        return lines
            .filter(::isUsefulCallText)
            .joinToString(" ")
            .trim()
    }

    private fun collectText(node: AccessibilityNodeInfo?, lines: MutableSet<String>) {
        if (node == null) return

        val text = node.text?.toString()?.trim()
        if (!text.isNullOrBlank()) {
            lines += text
        }

        val description = node.contentDescription?.toString()?.trim()
        if (!description.isNullOrBlank()) {
            lines += description
        }

        for (i in 0 until node.childCount) {
            collectText(node.getChild(i), lines)
        }
    }

    private fun isUsefulCallText(text: String): Boolean {
        if (text.length < 2) return false
        if (text.matches(Regex("[0-9+\\-()\\s:]+"))) return false

        val lower = text.lowercase()
        val ignored = listOf(
            "type response",
            "hide text call",
            "text call",
            "listening",
            "translation will appear",
            "ai is monitoring",
            "send me a text",
            "who are you",
            "i can't talk now"
        )
        if (ignored.any { lower.contains(it) }) return false

        return true
    }
}
