package com.example.flutter_voice_bridge

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.MediaRecorder
import android.media.MediaPlayer
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.IOException
import java.io.File
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import android.widget.TextView
import android.view.View
import android.graphics.Color
import android.graphics.Typeface

class MainActivity: FlutterActivity(), MediaPlayer.OnCompletionListener, MediaPlayer.OnErrorListener {
    companion object {
        /** Must match VoiceBridgeChannels.audio in lib/core/platform/voice_bridge_channels.dart. */
        private const val CHANNEL = "voice.bridge/audio"
        private const val TAG = "FlutterVoiceBridge"
        private const val RECORD_AUDIO_PERMISSION_REQUEST_CODE = 1001
        private const val SAMPLE_RATE_HZ = 16000
    }

    // Holds the Dart call while the permission dialog is open; a second start is rejected until it resolves.
    private var pendingRecordingResult: MethodChannel.Result? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    
    // Recording related
    private var mediaRecorder: MediaRecorder? = null
    private var audioFilePath: String? = null
    private var isRecording = false
    
    // Playback related
    private var mediaPlayer: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var isPlaying = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize AudioManager for playback
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "🎙️ [Android] Audio channel method called: ${call.method}")
            
            when (call.method) {
                "startRecording" -> {
                    try {
                        if (isRecording) {
                            result.error("ALREADY_RECORDING", "Recording already in progress", null)
                        } else if (checkRecordAudioPermission()) {
                            val filePath = startRecording()
                            result.success(filePath)
                        } else if (pendingRecordingResult != null) {
                            result.error("ALREADY_PENDING", "Waiting for the microphone permission dialog", null)
                        } else {
                            // Request permission and store result callback
                            pendingRecordingResult = result
                            requestRecordAudioPermission()
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ [Android] Recording error: ${e.message}")
                        result.error("RECORDING_ERROR", "Failed to start recording: ${e.message}", null)
                    }
                }
                "stopRecording" -> {
                    try {
                        val filePath = stopRecording()
                        result.success(filePath)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ [Android] Stop recording error: ${e.message}")
                        result.error("RECORDING_ERROR", "Failed to stop recording: ${e.message}", null)
                    }
                }
                "playRecording" -> {
                    val arguments = call.arguments as? Map<*, *>
                    val path = arguments?.get("path") as? String
                    
                    if (path != null) {
                        try {
                            playRecording(path, result)
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ [Android] Playback error: ${e.message}")
                            result.error("PLAYBACK_ERROR", "Failed to play recording: ${e.message}", null)
                        }
                    } else {
                        Log.e(TAG, "❌ [Android] playRecording called without valid path argument")
                        result.error("INVALID_ARGUMENTS", "Path argument is required for playRecording", null)
                    }
                }
                else -> {
                    Log.e(TAG, "❌ [Android] Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        // Register Platform View factory for native text view
        flutterEngine.platformViewsController
            .registry
            .registerViewFactory("native-text-view", NativeTextViewFactory())
    }

    private fun startRecording(): String {
        if (isRecording) {
            throw Exception("Recording already in progress")
        }

        // AAC in an .m4a container; Whisper needs WAV, so Android uses the placeholder transcription for now.
        val audioDir = File(filesDir, "audio")
        if (!audioDir.exists()) {
            audioDir.mkdirs()
        }
        
        val fileName = "voice_memo_${System.currentTimeMillis()}.m4a"
        audioFilePath = File(audioDir, fileName).absolutePath

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
            setAudioSamplingRate(SAMPLE_RATE_HZ)
            setAudioChannels(1)          // Mono for speech
            setOutputFile(audioFilePath)
            
            try {
                prepare()
                start()
                isRecording = true
                Log.d(TAG, "✅ [Android] Recording started (AAC, .m4a)")
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

        val recorder = mediaRecorder
        try {
            // stop() throws when no audio arrived yet (a very short recording); the file is unusable then.
            recorder?.stop()
        } catch (e: RuntimeException) {
            audioFilePath?.let { File(it).delete() }
            throw Exception("Recording too short or failed: ${e.message}")
        } finally {
            // Always release, or every later start would be refused as ALREADY_RECORDING.
            recorder?.release()
            mediaRecorder = null
            isRecording = false
        }

        return audioFilePath ?: throw Exception("Audio file path not available")
    }

    private fun playRecording(path: String, result: MethodChannel.Result) {
        Log.d(TAG, "🔊 [Android] playRecording called with path: $path")
        
        // Stop any current playback first (idempotent behavior)
        if (mediaPlayer != null && isPlaying) {
            Log.d(TAG, "⏹️ [Android] Stopping current playback before starting new one")
            stopPlayback()
        }
        
        // Validate file existence
        val file = File(path)
        if (!file.exists()) {
            Log.e(TAG, "❌ [Android] File does not exist at path: $path")
            result.error("FILE_NOT_FOUND", "Audio file not found at specified path", path)
            return
        }
        
        // Log file details
        try {
            val fileSize = file.length()
            Log.d(TAG, "📁 [Android] Playing file - size: $fileSize bytes, path: $path")
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ [Android] Could not get file attributes: ${e.message}")
        }
        
        if (requestAudioFocus() != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            Log.e(TAG, "❌ [Android] Failed to gain audio focus")
            result.error("AUDIO_FOCUS_ERROR", "Failed to gain audio focus for playback", null)
            return
        }
        
        Log.d(TAG, "✅ [Android] Audio focus granted")
        
        // Create and start MediaPlayer
        try {
            mediaPlayer = MediaPlayer().apply {
                setDataSource(path)
                setOnCompletionListener(this@MainActivity)
                setOnErrorListener(this@MainActivity)
                
                setAudioAttributes(playbackAttributes())
                
                prepare()
                start()
            }
            
            isPlaying = true
            Log.d(TAG, "✅ [Android] Playback started successfully")
            Log.d(TAG, "📊 [Android] Playback status - isPlaying: ${mediaPlayer?.isPlaying ?: false}")
            Log.d(TAG, "📊 [Android] Audio duration: ${mediaPlayer?.duration ?: 0} ms")
            
            result.success("Playback started")
            
        } catch (e: Exception) {
            Log.e(TAG, "💥 [Android] Error creating media player: ${e.message}")
            
            // Release audio focus on error
            abandonAudioFocus()
            
            result.error("PLAYER_ERROR", "Failed to create audio player: ${e.message}", e.message)
        }
    }
    
    private fun stopPlayback() {
        Log.d(TAG, "⏹️ [Android] stopPlayback called")
        
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        
        mediaPlayer = null
        isPlaying = false
        
        // Release audio focus
        abandonAudioFocus()
        Log.d(TAG, "✅ [Android] Audio focus released")
    }
    
    // MediaPlayer.OnCompletionListener implementation
    override fun onCompletion(mp: MediaPlayer?) {
        Log.d(TAG, "🏁 [Android] Playback completed successfully")
        isPlaying = false
        
        // Release the MediaPlayer and audio focus
        mediaPlayer?.release()
        mediaPlayer = null
        abandonAudioFocus()
        
        Log.d(TAG, "✅ [Android] MediaPlayer released and audio focus abandoned after completion")
    }
    
    // MediaPlayer.OnErrorListener implementation
    override fun onError(mp: MediaPlayer?, what: Int, extra: Int): Boolean {
        Log.e(TAG, "💥 [Android] MediaPlayer error occurred - what: $what, extra: $extra")
        isPlaying = false
        
        // Release the MediaPlayer and audio focus
        mediaPlayer?.release()
        mediaPlayer = null
        abandonAudioFocus()
        
        Log.d(TAG, "✅ [Android] MediaPlayer released and audio focus abandoned after error")
        
        // Return true to indicate we handled the error
        return true
    }

    // Permission handling methods
    private fun checkRecordAudioPermission(): Boolean {
        val permission = android.Manifest.permission.RECORD_AUDIO
        val hasPermission = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        
        Log.d(TAG, "🔐 [Android] RECORD_AUDIO permission check: $hasPermission")
        return hasPermission
    }
    
    private fun requestRecordAudioPermission() {
        Log.d(TAG, "📋 [Android] Requesting RECORD_AUDIO permission")
        
        if (ActivityCompat.shouldShowRequestPermissionRationale(this, android.Manifest.permission.RECORD_AUDIO)) {
            Log.d(TAG, "💬 [Android] Showing permission rationale to user")
        }
        
        ActivityCompat.requestPermissions(
            this,
            arrayOf(android.Manifest.permission.RECORD_AUDIO),
            RECORD_AUDIO_PERMISSION_REQUEST_CODE
        )
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            RECORD_AUDIO_PERMISSION_REQUEST_CODE -> {
                val result = pendingRecordingResult
                pendingRecordingResult = null
                
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    Log.d(TAG, "✅ [Android] RECORD_AUDIO permission granted")
                    
                    // Permission granted, start recording
                    try {
                        val filePath = startRecording()
                        result?.success(filePath)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ [Android] Recording error after permission granted: ${e.message}")
                        result?.error("RECORDING_ERROR", "Failed to start recording: ${e.message}", null)
                    }
                } else {
                    Log.e(TAG, "❌ [Android] RECORD_AUDIO permission denied")
                    result?.error("PERMISSION_DENIED", "Microphone permission is required for audio recording", null)
                }
            }
        }
    }

    private fun playbackAttributes(): AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()

    private fun requestAudioFocus(): Int? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(playbackAttributes())
                .build()
            audioFocusRequest = request
            return audioManager?.requestAudioFocus(request)
        }
        @Suppress("DEPRECATION")
        return audioManager?.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isRecording) {
            try {
                stopRecording()
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping recording on destroy: ${e.message}")
            }
        }
        if (isPlaying || mediaPlayer != null) {
            try {
                stopPlayback()
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping playback on destroy: ${e.message}")
            }
        }
    }
}

// MARK: - Platform View Implementation
/// 📺 **Module 3: Platform Views - Android Implementation**
/// 
/// Demonstrates embedding native Android UI components (TextView) directly within Flutter.
/// This shows how Platform Views bridge Flutter's widget tree with native Android View components.

class NativeTextViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return NativeTextView(context, viewId, args)
    }
}

class NativeTextView(context: Context, id: Int, creationParams: Any?) : PlatformView {
    private val textView: TextView

    init {
        textView = TextView(context)
        
        // Parse creation parameters from Flutter
        val params = creationParams as? Map<*, *>
        val text = params?.get("text") as? String ?: "Hello from Android!"
        val backgroundColorValue = params?.get("backgroundColor") as? Int ?: Color.parseColor("#2196F3")
        
        // Configure the native TextView
        textView.apply {
            this.text = text
            
            // Convert Flutter color int to Android Color
            val color = if (backgroundColorValue is Long) {
                backgroundColorValue.toInt()
            } else {
                backgroundColorValue
            }
            setBackgroundColor(color)
            
            // Styling
            setTextColor(Color.WHITE)
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            gravity = android.view.Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
            textSize = 16f
            
            // Padding
            setPadding(32, 24, 32, 24)
        }
    }

    override fun getView(): View {
        return textView
    }

    override fun dispose() {
        // Clean up any resources if needed
    }
}
