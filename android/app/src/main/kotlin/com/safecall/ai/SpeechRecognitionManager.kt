package com.safecall.ai

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer

class SpeechRecognitionManager(private val context: Context) {

    private var recognizer: SpeechRecognizer? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var isActive = false

    private var partialCallback: ((String) -> Unit)? = null
    private var finalCallback: ((String) -> Unit)? = null

    private val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        // Multi-language: try Korean first; partial results give us continuous streaming
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ko-KR")
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2500L)
        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 500L)
    }

    fun start(onPartial: (String) -> Unit, onFinal: (String) -> Unit) {
        partialCallback = onPartial
        finalCallback = onFinal
        isActive = true
        mainHandler.post { startListening() }
    }

    private fun startListening() {
        if (!isActive) return

        recognizer?.destroy()
        recognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
            setRecognitionListener(object : RecognitionListener {

                override fun onPartialResults(partialResults: Bundle) {
                    val text = partialResults
                        .getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        ?.firstOrNull() ?: return
                    partialCallback?.invoke(text)
                }

                override fun onResults(results: Bundle) {
                    val text = results
                        .getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        ?.firstOrNull() ?: ""
                    finalCallback?.invoke(text)
                    // Auto-restart for continuous monitoring
                    if (isActive) mainHandler.postDelayed({ startListening() }, 300)
                }

                override fun onError(error: Int) {
                    val delay = when (error) {
                        SpeechRecognizer.ERROR_NO_MATCH,
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> 500L
                        SpeechRecognizer.ERROR_NETWORK,
                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> 3000L
                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> 1000L
                        else -> 800L
                    }
                    if (isActive) mainHandler.postDelayed({ startListening() }, delay)
                }

                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
            startListening(recognizerIntent)
        }
    }

    fun stop() {
        isActive = false
        mainHandler.post {
            recognizer?.stopListening()
            recognizer?.destroy()
            recognizer = null
        }
    }
}
