package com.safecall.ai

import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions

class TranslationManager(targetLanguage: String = TranslateLanguage.ENGLISH) {

    private val options = TranslatorOptions.Builder()
        .setSourceLanguage(TranslateLanguage.KOREAN)
        .setTargetLanguage(targetLanguage)
        .build()

    private val translator: Translator = Translation.getClient(options)

    fun downloadModelIfNeeded(onReady: () -> Unit) {
        translator.downloadModelIfNeeded()
            .addOnSuccessListener { onReady() }
            .addOnFailureListener { onReady() } // proceed even if download fails
    }

    fun translate(text: String, onResult: (String) -> Unit) {
        if (text.isBlank()) {
            onResult("")
            return
        }
        translator.translate(text)
            .addOnSuccessListener { translated -> onResult(translated) }
            .addOnFailureListener { onResult(text) } // fallback: pass through original
    }

    fun close() = translator.close()
}
