package com.safecall.ai

import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

class CloudTranslationClient(private val apiKey: String) {

    private val mainHandler = Handler(Looper.getMainLooper())

    fun translate(text: String, targetLanguage: String, onResult: (String) -> Unit) {
        if (apiKey.isBlank() || text.isBlank()) {
            onResult(text)
            return
        }

        Thread {
            val result = runCatching {
                val encodedKey = URLEncoder.encode(apiKey, "UTF-8")
                val url = URL("https://translation.googleapis.com/language/translate/v2?key=$encodedKey")
                val connection = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 7000
                    readTimeout = 7000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                }

                val body = JSONObject()
                    .put("q", text)
                    .put("target", targetLanguage)
                    .put("format", "text")
                    .toString()

                OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
                    writer.write(body)
                }

                val stream = if (connection.responseCode in 200..299) {
                    connection.inputStream
                } else {
                    connection.errorStream
                }
                val payload = stream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                connection.disconnect()

                JSONObject(payload)
                    .getJSONObject("data")
                    .getJSONArray("translations")
                    .getJSONObject(0)
                    .getString("translatedText")
                    .trim()
            }.getOrDefault(text)

            mainHandler.post {
                onResult(result.ifBlank { text })
            }
        }.start()
    }
}
