import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioRecorder: AVAudioRecorder?
  private var audioFilePath: String?
  private var isRecording = false
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
      default:
        NSLog("❌ [iOS] Unknown method: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
    
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
      
      // Setup recording settings
      let settings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]
      NSLog("🔧 [iOS] Audio settings configured: \(settings)")
      
      // Generate file path
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let timestamp = Int(Date().timeIntervalSince1970)
      let audioFilename = documentsPath.appendingPathComponent("voice_memo_\(timestamp).m4a")
      
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
