package com.safecall.ai

import android.content.Context
import com.google.mlkit.nl.translate.TranslateLanguage

object AppSettings {
    private const val PREFS_NAME = "safe_call_settings"
    private const val KEY_PROTECTION_ENABLED = "protection_enabled"
    private const val KEY_TARGET_LANGUAGE = "target_language"
    private const val KEY_CLOUD_TRANSLATE_API_KEY = "cloud_translate_api_key"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun isProtectionEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_PROTECTION_ENABLED, true)

    fun setProtectionEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_PROTECTION_ENABLED, enabled).apply()
    }

    fun getTargetLanguage(context: Context): String =
        prefs(context).getString(KEY_TARGET_LANGUAGE, TranslateLanguage.ENGLISH)
            ?: TranslateLanguage.ENGLISH

    fun setTargetLanguage(context: Context, languageCode: String) {
        prefs(context).edit().putString(KEY_TARGET_LANGUAGE, languageCode).apply()
    }

    fun getCloudTranslateApiKey(context: Context): String =
        prefs(context).getString(KEY_CLOUD_TRANSLATE_API_KEY, "") ?: ""

    fun setCloudTranslateApiKey(context: Context, apiKey: String) {
        prefs(context).edit().putString(KEY_CLOUD_TRANSLATE_API_KEY, apiKey).apply()
    }
}
