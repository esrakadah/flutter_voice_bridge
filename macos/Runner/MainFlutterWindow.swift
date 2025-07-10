import Cocoa
import FlutterMacOS
import AVFoundation

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Set up method channel here where we know FlutterViewController is ready
    setupAudioMethodChannel(flutterViewController: flutterViewController)

    super.awakeFromNib()
  }
  
  private func setupAudioMethodChannel(flutterViewController: FlutterViewController) {
    print("🔧 [macOS] Setting up audio method channel in MainFlutterWindow")
    print("🔧 [macOS] FlutterViewController: \(flutterViewController)")
    
    let channel = FlutterMethodChannel(name: "voice.bridge/audio", binaryMessenger: flutterViewController.engine.binaryMessenger)
    
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      print("🎙️ [macOS] Audio channel method called: \(call.method)")
      
      // Get the AppDelegate instance to handle the audio methods
      guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
        print("❌ [macOS] Could not get AppDelegate instance")
        result(FlutterError(code: "INSTANCE_ERROR", message: "AppDelegate instance not available", details: nil))
        return
      }
      
      switch call.method {
      case "startRecording":
        print("🎤 [macOS] Calling startRecording via AppDelegate...")
        appDelegate.handleStartRecording(result: result)
        
      case "stopRecording":
        print("⏹️ [macOS] Calling stopRecording via AppDelegate...")
        appDelegate.handleStopRecording(result: result)
        
      case "playRecording":
        print("🔊 [macOS] Calling playRecording via AppDelegate...")
        if let arguments = call.arguments as? [String: Any],
           let path = arguments["path"] as? String {
          appDelegate.handlePlayRecording(path: path, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Path argument is required for playRecording", details: nil))
        }
        
      default:
        print("❌ [macOS] Unknown method: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
    
    print("✅ [macOS] Audio method channel setup completed!")
  }
}
