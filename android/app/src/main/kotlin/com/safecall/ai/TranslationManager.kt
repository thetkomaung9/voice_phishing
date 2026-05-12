package com.safecall.ai

import android.content.Context
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions

class TranslationManager(
    context: Context,
    private val targetLanguage: String = TranslateLanguage.ENGLISH
) {

    private val englishOptions = TranslatorOptions.Builder()
        .setSourceLanguage(TranslateLanguage.KOREAN)
        .setTargetLanguage(TranslateLanguage.ENGLISH)
        .build()
    private val targetLanguageCode =
        TranslateLanguage.fromLanguageTag(targetLanguage)
    private val cloudTranslationClient =
        CloudTranslationClient(AppSettings.getCloudTranslateApiKey(context))

    private val englishTranslator: Translator = Translation.getClient(englishOptions)
    private val targetTranslator: Translator? =
        if (targetLanguageCode == null || targetLanguageCode == TranslateLanguage.ENGLISH) {
            null
        } else {
            Translation.getClient(
                TranslatorOptions.Builder()
                    .setSourceLanguage(TranslateLanguage.KOREAN)
                    .setTargetLanguage(targetLanguageCode)
                    .build()
            )
        }

    fun downloadModelIfNeeded(onReady: () -> Unit) {
        englishTranslator.downloadModelIfNeeded()
            .addOnSuccessListener {
                targetTranslator?.downloadModelIfNeeded()
                    ?.addOnSuccessListener { onReady() }
                    ?.addOnFailureListener { onReady() }
                    ?: onReady()
            }
            .addOnFailureListener { onReady() } // proceed even if download fails
    }

    fun translate(text: String, onResult: (String) -> Unit) {
        if (text.isBlank()) {
            onResult("")
            return
        }
        englishTranslator.translate(text)
            .addOnSuccessListener { translated -> onResult(translated) }
            .addOnFailureListener { onResult(text) } // fallback: pass through original
    }

    fun translatePreferred(text: String, onResult: (String) -> Unit) {
        if (text.isBlank()) {
            onResult("")
            return
        }

        if (targetLanguage == "my") {
            cloudTranslationClient.translate(text, targetLanguage, onResult)
            return
        }

        val translator = targetTranslator ?: englishTranslator
        translator.translate(text)
            .addOnSuccessListener { translated -> onResult(translated) }
            .addOnFailureListener {
                cloudTranslationClient.translate(text, targetLanguage, onResult)
            }
    }

    fun close() {
        englishTranslator.close()
        targetTranslator?.close()
    }
}
