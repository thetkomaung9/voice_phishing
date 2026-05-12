package com.safecall.ai

import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions

class TranslationManager(targetLanguage: String = TranslateLanguage.ENGLISH) {

    private val englishOptions = TranslatorOptions.Builder()
        .setSourceLanguage(TranslateLanguage.KOREAN)
        .setTargetLanguage(TranslateLanguage.ENGLISH)
        .build()
    private val targetLanguageCode =
        TranslateLanguage.fromLanguageTag(targetLanguage) ?: TranslateLanguage.ENGLISH
    private val targetOptions = TranslatorOptions.Builder()
        .setSourceLanguage(TranslateLanguage.KOREAN)
        .setTargetLanguage(targetLanguageCode)
        .build()

    private val englishTranslator: Translator = Translation.getClient(englishOptions)
    private val targetTranslator: Translator? =
        if (targetLanguageCode == TranslateLanguage.ENGLISH) null else Translation.getClient(targetOptions)

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

        val translator = targetTranslator ?: englishTranslator
        translator.translate(text)
            .addOnSuccessListener { translated -> onResult(translated) }
            .addOnFailureListener { onResult(text) }
    }

    fun close() {
        englishTranslator.close()
        targetTranslator?.close()
    }
}
