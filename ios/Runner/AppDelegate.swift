import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioRecorder: AVAudioRecorder?
  private var audioPlayer: AVAudioPlayer?
  private var audioFilePath: String?
  private var isRecording = false
  private var isPlaying = false
  private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "voice.bridge/audio",
                                            binaryMessenger: controller.binaryMessenger)
    
    audioChannel.setMethodCallHandler { [weak self] (call, result) in
      NSLog("🎙️ [iOS] Audio channel method called: \(call.method)")
      
      switch call.method {
      case "startRecording":
        self?.startRecording(result: result)
      case "stopRecording":
        self?.stopRecording(result: result)
      case "playRecording":
        if let arguments = call.arguments as? [String: Any],
           let path = arguments["path"] as? String {
          self?.playRecording(atPath: path, result: result)
        } else {
          NSLog("❌ [iOS] playRecording called without valid path argument")
          result(FlutterError(code: "INVALID_ARGUMENTS",
                             message: "Path argument is required for playRecording",
                             details: nil))
        }
      default:
        NSLog("❌ [iOS] Unknown method: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Register Platform View factory for native text view
    let nativeTextViewFactory = NativeTextViewFactory()
    self.registrar(forPlugin: "NativeTextView")?.register(nativeTextViewFactory, withId: "native-text-view")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func startRecording(result: @escaping FlutterResult) {
    NSLog("🎤 [iOS] startRecording called")
    
    // Check and request microphone permission
    switch audioSession.recordPermission {
    case .granted:
      NSLog("✅ [iOS] Microphone permission already granted")
      self.beginRecording(result: result)
    case .denied:
      NSLog("❌ [iOS] Microphone permission denied")
      result(FlutterError(code: "PERMISSION_DENIED",
                         message: "Microphone permission denied",
                         details: nil))
    case .undetermined:
      NSLog("❓ [iOS] Microphone permission undetermined, requesting...")
      audioSession.requestRecordPermission { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            NSLog("✅ [iOS] Microphone permission granted by user")
            self?.beginRecording(result: result)
          } else {
            NSLog("❌ [iOS] Microphone permission denied by user")
            result(FlutterError(code: "PERMISSION_DENIED",
                               message: "Microphone permission denied by user",
                               details: nil))
          }
        }
      }
    @unknown default:
      NSLog("⚠️ [iOS] Unknown microphone permission state")
      result(FlutterError(code: "PERMISSION_UNKNOWN",
                         message: "Unknown permission state",
                         details: nil))
    }
  }
  
  private func beginRecording(result: @escaping FlutterResult) {
    NSLog("🎬 [iOS] beginRecording called")
    
    do {
      // Configure audio session
      try audioSession.setCategory(.playAndRecord, mode: .default)
      try audioSession.setActive(true)
      NSLog("✅ [iOS] Audio session configured successfully")
      
      // Setup recording settings (WAV format for Whisper compatibility)
      let settings = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16000.0,  // 16kHz is optimal for speech recognition
        AVNumberOfChannelsKey: 1,   // Mono for speech
        AVLinearPCMBitDepthKey: 16, // 16-bit depth
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false
      ]
      NSLog("🔧 [iOS] Audio settings configured: \(settings)")
      
      // Generate file path (using WAV format for Whisper compatibility)
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let audioDir = documentsPath.appendingPathComponent("audio")
      
      // Create audio directory if it doesn't exist
      if !FileManager.default.fileExists(atPath: audioDir.path) {
        try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true, attributes: nil)
        NSLog("✅ [iOS] Audio directory created")
      }
      
      let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
      let audioFilename = audioDir.appendingPathComponent("voice_memo_\(timestamp).wav")
      
      NSLog("📁 [iOS] Generated file path: \(audioFilename.path)")
      NSLog("📁 [iOS] Documents directory: \(documentsPath.path)")
      
      // Create and start recorder
      audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      audioRecorder?.delegate = self
      audioRecorder?.isMeteringEnabled = true
      
      let success = audioRecorder?.record() ?? false
      if success {
        NSLog("✅ [iOS] Recording started successfully")
        NSLog("📊 [iOS] Recording status - isRecording: \(audioRecorder?.isRecording ?? false)")
        result(audioFilename.path)
      } else {
        NSLog("❌ [iOS] Failed to start recording")
        result(FlutterError(code: "RECORDING_FAILED",
                           message: "Failed to start recording",
                           details: nil))
      }
      
    } catch {
      NSLog("💥 [iOS] Error in beginRecording: \(error.localizedDescription)")
      result(FlutterError(code: "RECORDING_ERROR",
                         message: "Recording setup failed: \(error.localizedDescription)",
                         details: error.localizedDescription))
    }
  }
  
  private func stopRecording(result: @escaping FlutterResult) {
    NSLog("⏹️ [iOS] stopRecording called")
    
    guard let recorder = audioRecorder else {
      NSLog("❌ [iOS] No active recorder found")
      result(FlutterError(code: "NO_RECORDING",
                         message: "No active recording to stop",
                         details: nil))
      return
    }
    
    NSLog("📊 [iOS] Pre-stop status - isRecording: \(recorder.isRecording)")
    
    let audioURL = recorder.url
    recorder.stop()
    
    NSLog("📁 [iOS] Recording stopped, file saved to: \(audioURL.path)")
    
    // Verify file exists and get details
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: audioURL.path) {
      do {
        let attributes = try fileManager.attributesOfItem(atPath: audioURL.path)
        let fileSize = attributes[.size] as? NSNumber ?? 0
        NSLog("✅ [iOS] File verified - size: \(fileSize) bytes")
        NSLog("📂 [iOS] File details: \(attributes)")
      } catch {
        NSLog("⚠️ [iOS] Could not get file attributes: \(error)")
      }
    } else {
      NSLog("❌ [iOS] Warning: File does not exist at path: \(audioURL.path)")
    }
    
    // Deactivate audio session
    do {
      try audioSession.setActive(false)
      NSLog("✅ [iOS] Audio session deactivated")
    } catch {
      NSLog("⚠️ [iOS] Error deactivating audio session: \(error)")
    }
    
    audioRecorder = nil
    result(audioURL.path)
  }
  
  private func playRecording(atPath path: String, result: @escaping FlutterResult) {
    NSLog("🔊 [iOS] playRecording called with path: \(path)")
    
    // Stop any current playback (idempotent behavior)
    if let currentPlayer = audioPlayer, currentPlayer.isPlaying {
      NSLog("⏹️ [iOS] Stopping current playback before starting new one")
      currentPlayer.stop()
      isPlaying = false
    }
    
    // Validate file existence
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: path) else {
      NSLog("❌ [iOS] File does not exist at path: \(path)")
      result(FlutterError(code: "FILE_NOT_FOUND",
                         message: "Audio file not found at specified path",
                         details: path))
      return
    }
    
    // Log file details
    do {
      let attributes = try fileManager.attributesOfItem(atPath: path)
      let fileSize = attributes[.size] as? NSNumber ?? 0
      NSLog("📁 [iOS] Playing file - size: \(fileSize) bytes, path: \(path)")
    } catch {
      NSLog("⚠️ [iOS] Could not get file attributes: \(error)")
    }
    
    // Setup audio session for playback
    do {
      try audioSession.setCategory(.playback, mode: .default)
      try audioSession.setActive(true)
      NSLog("✅ [iOS] Audio session configured for playback")
    } catch {
      NSLog("❌ [iOS] Failed to configure audio session: \(error)")
      result(FlutterError(code: "AUDIO_SESSION_ERROR",
                         message: "Failed to configure audio session for playback",
                         details: error.localizedDescription))
      return
    }
    
    // Create and start audio player
    do {
      let audioURL = URL(fileURLWithPath: path)
      audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
      audioPlayer?.delegate = self
      audioPlayer?.prepareToPlay()
      
      let success = audioPlayer?.play() ?? false
      if success {
        isPlaying = true
        NSLog("✅ [iOS] Playback started successfully")
        NSLog("📊 [iOS] Playback status - isPlaying: \(audioPlayer?.isPlaying ?? false)")
        NSLog("📊 [iOS] Audio duration: \(audioPlayer?.duration ?? 0) seconds")
        result("Playback started")
      } else {
        NSLog("❌ [iOS] Failed to start playback")
        result(FlutterError(code: "PLAYBACK_FAILED",
                           message: "Failed to start audio playback",
                           details: nil))
      }
    } catch {
      NSLog("💥 [iOS] Error creating audio player: \(error.localizedDescription)")
      result(FlutterError(code: "PLAYER_ERROR",
                         message: "Failed to create audio player: \(error.localizedDescription)",
                         details: error.localizedDescription))
    }
  }
}

// MARK: - AVAudioRecorderDelegate
extension AppDelegate: AVAudioRecorderDelegate {
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    NSLog("🏁 [iOS] audioRecorderDidFinishRecording - success: \(flag)")
    if !flag {
      NSLog("❌ [iOS] Recording finished unsuccessfully")
    }
  }
  
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    NSLog("💥 [iOS] audioRecorderEncodeErrorDidOccur: \(error?.localizedDescription ?? "Unknown error")")
  }
}

// MARK: - AVAudioPlayerDelegate
extension AppDelegate: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    NSLog("🏁 [iOS] audioPlayerDidFinishPlaying - success: \(flag)")
    isPlaying = false
    
    // Deactivate audio session after playback
    do {
      try audioSession.setActive(false)
      NSLog("✅ [iOS] Audio session deactivated after playback")
    } catch {
      NSLog("⚠️ [iOS] Error deactivating audio session after playback: \(error)")
    }
    
    if !flag {
      NSLog("❌ [iOS] Playback finished unsuccessfully")
    }
  }
  
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    NSLog("💥 [iOS] audioPlayerDecodeErrorDidOccur: \(error?.localizedDescription ?? "Unknown error")")
    isPlaying = false
  }
}

// MARK: - Platform View Implementation
/// 📺 **Module 3: Platform Views - iOS Implementation**
/// 
/// Demonstrates embedding native iOS UI components (UILabel) directly within Flutter.
/// This shows how Platform Views bridge Flutter's widget tree with native UIKit components.

class NativeTextViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return NativeTextView(frame: frame, viewId: viewId, args: args)
  }
  
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class NativeTextView: NSObject, FlutterPlatformView {
  private let _view: UIView
  private let _label: UILabel
  
  init(frame: CGRect, viewId: Int64, args: Any?) {
    // Create container view
    _view = UIView(frame: frame)
    
    // Create and configure native UILabel
    _label = UILabel()
    _label.translatesAutoresizingMaskIntoConstraints = false
    _label.textAlignment = .center
    _label.numberOfLines = 0
    _label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    _label.textColor = .white
    
    // Parse arguments from Flutter
    if let arguments = args as? [String: Any] {
      let text = arguments["text"] as? String ?? "Hello from iOS!"
      let backgroundColorValue = arguments["backgroundColor"] as? Int64 ?? 0xFF2196F3
      
      _label.text = text
      
      // Convert Flutter color int to UIColor
      let red = CGFloat((backgroundColorValue >> 16) & 0xFF) / 255.0
      let green = CGFloat((backgroundColorValue >> 8) & 0xFF) / 255.0
      let blue = CGFloat(backgroundColorValue & 0xFF) / 255.0
      let alpha = CGFloat((backgroundColorValue >> 24) & 0xFF) / 255.0
      
      let backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
      _view.backgroundColor = backgroundColor
    } else {
      _label.text = "Hello from iOS!"
      _view.backgroundColor = UIColor.systemBlue
    }
    
    // Add label to container view
    _view.addSubview(_label)
    
    // Add constraints for label
    NSLayoutConstraint.activate([
      _label.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
      _label.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
      _label.leadingAnchor.constraint(greaterThanOrEqualTo: _view.leadingAnchor, constant: 16),
      _label.trailingAnchor.constraint(lessThanOrEqualTo: _view.trailingAnchor, constant: -16)
    ])
    
    // Add rounded corners
    _view.layer.cornerRadius = 8
    _view.layer.masksToBounds = true
    
    super.init()
  }
  
  func view() -> UIView {
    return _view
  }
}
