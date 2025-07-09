package com.example.flutter_voice_bridge

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.MediaRecorder
import android.os.Build
import java.io.IOException
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "voice.bridge/audio"
    private var mediaRecorder: MediaRecorder? = null
    private var audioFilePath: String? = null
    private var isRecording = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    try {
                        val filePath = startRecording()
                        result.success(filePath)
                    } catch (e: Exception) {
                        result.error("RECORDING_ERROR", "Failed to start recording: ${e.message}", null)
                    }
                }
                "stopRecording" -> {
                    try {
                        val filePath = stopRecording()
                        result.success(filePath)
                    } catch (e: Exception) {
                        result.error("RECORDING_ERROR", "Failed to stop recording: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startRecording(): String {
        if (isRecording) {
            throw Exception("Recording already in progress")
        }

        // Create audio file path
        val audioDir = File(filesDir, "audio")
        if (!audioDir.exists()) {
            audioDir.mkdirs()
        }
        
        val fileName = "voice_memo_${System.currentTimeMillis()}.m4a"
        audioFilePath = File(audioDir, fileName).absolutePath

        // Initialize MediaRecorder
        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        mediaRecorder?.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setOutputFile(audioFilePath)
            
            try {
                prepare()
                start()
                isRecording = true
            } catch (e: IOException) {
                throw Exception("Failed to start recording: ${e.message}")
            }
        }

        return audioFilePath ?: throw Exception("Failed to create audio file path")
    }

    private fun stopRecording(): String {
        if (!isRecording) {
            throw Exception("No recording in progress")
        }

        mediaRecorder?.apply {
            try {
                stop()
                release()
            } catch (e: Exception) {
                throw Exception("Failed to stop recording: ${e.message}")
            }
        }

        mediaRecorder = null
        isRecording = false
        
        return audioFilePath ?: throw Exception("Audio file path not available")
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isRecording) {
            try {
                stopRecording()
            } catch (e: Exception) {
                // Log error but don't crash
                println("Error stopping recording on destroy: ${e.message}")
            }
        }
    }
}
