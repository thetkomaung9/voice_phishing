package com.safecall.ai

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class AudioCaptureManager {

    companion object {
        const val SAMPLE_RATE = 16000
        const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        private const val AMPLITUDE_THRESHOLD = 400 // simple VAD gate
    }

    private var recorder: AudioRecord? = null
    private var captureJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    val minBufferSize: Int
        get() = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

    fun start(onChunk: (ByteArray) -> Unit) {
        val bufferSize = minBufferSize * 4
        recorder = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, bufferSize
        )

        if (recorder?.state != AudioRecord.STATE_INITIALIZED) {
            recorder?.release()
            recorder = null
            return
        }

        recorder?.startRecording()

        captureJob = scope.launch {
            val buffer = ByteArray(bufferSize)
            while (isActive) {
                val read = recorder?.read(buffer, 0, buffer.size) ?: break
                if (read > 0 && hasAudioActivity(buffer, read)) {
                    onChunk(buffer.copyOf(read))
                }
            }
        }
    }

    private fun hasAudioActivity(buffer: ByteArray, size: Int): Boolean {
        var sum = 0L
        val samples = size / 2
        for (i in 0 until size - 1 step 2) {
            val low = buffer[i].toInt() and 0xFF
            val high = buffer[i + 1].toInt()
            val sample = (high shl 8) or low
            sum += Math.abs(sample.toShort().toInt())
        }
        return if (samples > 0) (sum / samples) > AMPLITUDE_THRESHOLD else false
    }

    fun stop() {
        captureJob?.cancel()
        captureJob = null
        recorder?.apply {
            stop()
            release()
        }
        recorder = null
    }
}
