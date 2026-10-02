import Cocoa
import FlutterMacOS
import AVFoundation

@main
class AppDelegate: FlutterAppDelegate {
    // Recording related
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioFilePath: String?
    private var isRecording = false
    private var isPlaying = false
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Public Audio Methods (called from MainFlutterWindow)
    
    func handleStartRecording(result: @escaping FlutterResult) {
        print("🎤 [macOS] === startRecording called ===")
        print("🎤 [macOS] Thread: \(Thread.current)")
        print("🎤 [macOS] isRecording: \(isRecording)")
        
        if isRecording {
            print("❌ [macOS] Recording already in progress")
            result(FlutterError(code: "ALREADY_RECORDING", message: "Recording already in progress", details: nil))
            return
        }
        
        print("🎤 [macOS] Requesting microphone permission...")
        // Request microphone permission
        requestMicrophonePermission { [weak self] granted in
            print("🎤 [macOS] Microphone permission result: \(granted)")
            DispatchQueue.main.async {
                if granted {
                    print("✅ [macOS] Permission granted, starting recording...")
                    self?.performStartRecording(result: result)
                } else {
                    print("❌ [macOS] Permission denied")
                    result(FlutterError(code: "PERMISSION_DENIED", message: "Microphone permission not granted", details: nil))
                }
            }
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        print("🔐 [macOS] === requestMicrophonePermission called ===")
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        print("🔐 [macOS] Current authorization status: \(authStatus.rawValue)")
        
        switch authStatus {
        case .authorized:
            print("🔐 [macOS] Already authorized")
            completion(true)
        case .notDetermined:
            print("🔐 [macOS] Permission not determined, requesting access...")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                print("🔐 [macOS] Permission request result: \(granted)")
                completion(granted)
            }
        case .denied, .restricted:
            print("🔐 [macOS] Permission denied or restricted")
            completion(false)
        @unknown default:
            print("🔐 [macOS] Unknown permission status")
            completion(false)
        }
    }
    
    private func performStartRecording(result: @escaping FlutterResult) {
        print("🎤 [macOS] === performStartRecording called ===")
        print("🎤 [macOS] Thread: \(Thread.current)")
        
        do {
            print("🎤 [macOS] Creating audio directory...")
            // Create audio directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let audioDir = documentsPath.appendingPathComponent("audio")
            print("🎤 [macOS] Audio directory path: \(audioDir.path)")
            
            if !FileManager.default.fileExists(atPath: audioDir.path) {
                print("🎤 [macOS] Audio directory doesn't exist, creating...")
                try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true, attributes: nil)
                print("✅ [macOS] Audio directory created")
            } else {
                print("✅ [macOS] Audio directory already exists")
            }
            
            // Create audio file path (using WAV format for Whisper compatibility)
            let fileName = "voice_memo_\(Int64(Date().timeIntervalSince1970 * 1000)).wav"
            let audioFileURL = audioDir.appendingPathComponent(fileName)
            audioFilePath = audioFileURL.path
            print("🎤 [macOS] Audio file path: \(audioFilePath ?? "nil")")
            
            // Set recording settings (WAV format for Whisper compatibility)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000.0,  // 16kHz is optimal for speech recognition
                AVNumberOfChannelsKey: 1,   // Mono for speech
                AVLinearPCMBitDepthKey: 16, // 16-bit depth
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            print("🎤 [macOS] Recording settings: \(settings)")
            
            // Create and start recorder
            print("🎤 [macOS] Creating AVAudioRecorder...")
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.delegate = self
            print("✅ [macOS] AVAudioRecorder created successfully")
            
            print("🎤 [macOS] Starting recording...")
            if audioRecorder?.record() == true {
                isRecording = true
                print("✅ [macOS] Recording started successfully!")
                print("✅ [macOS] File path: \(audioFilePath ?? "unknown path")")
                result(audioFilePath)
            } else {
                print("❌ [macOS] Failed to start recording (recorder.record() returned false)")
                throw NSError(domain: "RecordingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"])
            }
            
        } catch {
            print("❌ [macOS] Recording error: \(error)")
            print("❌ [macOS] Error description: \(error.localizedDescription)")
            result(FlutterError(code: "RECORDING_ERROR", message: "Failed to start recording: \(error.localizedDescription)", details: nil))
        }
    }
    
    func handleStopRecording(result: @escaping FlutterResult) {
        print("⏹️ [macOS] === handleStopRecording called ===")
        print("⏹️ [macOS] Current isRecording state: \(isRecording)")
        print("⏹️ [macOS] audioRecorder exists: \(audioRecorder != nil)")
        print("⏹️ [macOS] audioRecorder isRecording: \(audioRecorder?.isRecording ?? false)")
        
        // Check if we have an active recorder, even if our flag is wrong
        if let recorder = audioRecorder, recorder.isRecording {
            print("✅ [macOS] Active recorder found, stopping...")
            recorder.stop()
            isRecording = false
            print("✅ [macOS] Recording stopped successfully. File saved to: \(audioFilePath ?? "unknown path")")
            result(audioFilePath)
        } else if isRecording {
            // Our flag says recording but no active recorder - sync the state
            print("⚠️ [macOS] State sync issue: isRecording=true but no active recorder, resetting state")
            isRecording = false
            audioRecorder = nil
            audioFilePath = nil
            result(FlutterError(code: "RECORDING_ERROR", message: "Recording state was inconsistent, reset successfully", details: nil))
        } else {
            print("❌ [macOS] No recording in progress")
            result(FlutterError(code: "RECORDING_ERROR", message: "No recording in progress", details: nil))
        }
    }
    
    func handlePlayRecording(path: String, result: @escaping FlutterResult) {
        print("🔊 [macOS] Playing recording: \(path)")
        
        // Stop any current playback
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        }
        
        // Check if file exists
        let fileURL = URL(fileURLWithPath: path)
        if !FileManager.default.fileExists(atPath: path) {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "Audio file not found at specified path", details: path))
            return
        }
        
        do {
            // Create and start player
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            
            if audioPlayer?.play() == true {
                isPlaying = true
                print("✅ [macOS] Playback started successfully")
                result("Playback started")
            } else {
                throw NSError(domain: "PlaybackError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start playback"])
            }
            
        } catch {
            print("❌ [macOS] Playback error: \(error.localizedDescription)")
            result(FlutterError(code: "PLAYBACK_ERROR", message: "Failed to play recording: \(error.localizedDescription)", details: nil))
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AppDelegate: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("🎤 [macOS] === audioRecorderDidFinishRecording ===")
        print("🎤 [macOS] Success: \(flag)")
        print("🎤 [macOS] File URL: \(recorder.url)")
        
        // Always reset recording state when recorder finishes
        isRecording = false
        
        if !flag {
            print("❌ [macOS] Recording finished unsuccessfully")
            // Could notify Flutter about the failure here if needed
        } else {
            print("✅ [macOS] Recording finished successfully")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ [macOS] === audioRecorderEncodeErrorDidOccur ===")
        print("❌ [macOS] Error: \(error?.localizedDescription ?? "unknown error")")
        
        // Reset state on error
        isRecording = false
        audioRecorder = nil
        audioFilePath = nil
    }
}

// MARK: - AVAudioPlayerDelegate
extension AppDelegate: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🔊 [macOS] Audio player finished: success=\(flag)")
        isPlaying = false
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ [macOS] Audio player error: \(error?.localizedDescription ?? "unknown error")")
        isPlaying = false
    }
}
