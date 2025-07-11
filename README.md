# 🎙️ Flutter Voice Bridge

**Flutter Voice Bridge** is a **production-ready** cross-platform application showcasing advanced integration of native device features and local AI capabilities within a Flutter app. It provides a robust foundation for building voice-powered applications, featuring audio recording, playback, and **working offline speech-to-text transcription** using `Whisper.cpp`.

This project follows **Clean Architecture** principles and demonstrates **real-world implementation** of complex Flutter concepts including FFI, Platform Channels, and AI integration.

> **🎯 Status**: Currently **85% complete** with full iOS/macOS transcription support and comprehensive Android audio features. Perfect for learning advanced Flutter development patterns.

## ✨ Features

- **✅ Cross-Platform Audio Recording**: High-quality audio capture on iOS, macOS, and Android with optimized formats.
- **✅ Local Audio Playback**: Play recorded memos directly within the app across all platforms.
- **✅ Offline Speech-to-Text**: **WORKING** on-device transcription using `Whisper.cpp` via Dart FFI. No internet connection required.
- **✅ Real-time Audio Visualization**: Custom waveform, spectrum, and particle visualizations during recording.
- **✅ Keyword Extraction**: Automatic keyword detection from transcribed text with intelligent filtering.
- **✅ Clean Architecture (MVVM)**: A clear separation of concerns between UI, business logic, and data layers.
- **✅ Dependency Injection**: Loose coupling and enhanced testability using `get_it`.
- **✅ State Management with BLoC/Cubit**: Predictable and scalable state management with real-time UI updates.
- **✅ Native Integration**: Deep integration with native APIs via Platform Channels and Dart FFI.
- **✅ GPU Acceleration**: Metal GPU support on Apple Silicon for fast AI inference.
- **📚 Comprehensive Documentation**: Complete guides for architecture, setup, and feature implementation.

## 🏛️ Project Architecture

The application is structured using a clean, layered architecture that separates concerns and promotes modularity.

### 📊 System Architecture Overview

```mermaid
graph TB
    %% Flutter App Architecture & Native Connections
    subgraph "Flutter Layer"
        UI["`**UI Layer**<br/>
        • HomeView (BlocConsumer)<br/>
        • VoiceRecorderButton<br/>
        • AudioVisualizer`"]
        
        BL["`**Business Logic**<br/>
        • HomeCubit (State Management)<br/>
        • Recording/Transcription Logic<br/>
        • Error Handling`"]
        
        Data["`**Data Layer**<br/>
        • VoiceMemoService<br/>
        • VoiceMemo Model<br/>
        • File I/O Operations`"]
    end
    
    subgraph "Platform Interface"
        PC["`**Platform Channels**<br/>
        • MethodChannel Communication<br/>
        • Audio Recording Control<br/>
        • Permission Management`"]
        
        FFI["`**Dart FFI**<br/>
        • Direct C++ Integration<br/>
        • Whisper.cpp Binding<br/>
        • Memory Management`"]
    end
    
    subgraph "iOS Native"
        iOS_Swift["`**Swift Implementation**<br/>
        • AVAudioRecorder<br/>
        • Audio Session Config<br/>
        • M4A Format`"]
        
        iOS_Metal["`**Metal GPU**<br/>
        • Hardware Acceleration<br/>
        • Neural Network Ops`"]
    end
    
    subgraph "Android Native"
        Android_Kotlin["`**Kotlin Implementation**<br/>
        • MediaRecorder<br/>
        • Audio Permissions<br/>
        • WAV Format`"]
        
        Android_GPU["`**GPU Acceleration**<br/>
        • OpenGL/Vulkan<br/>
        • Compute Shaders`"]
    end
    
    subgraph "Native C++ Layer"
        Whisper["`**Whisper.cpp**<br/>
        • OpenAI Whisper Model<br/>
        • GGML Backend<br/>
        • Audio Processing`"]
        
        Models["`**AI Models**<br/>
        • ggml-base.en.bin<br/>
        • Neural Networks<br/>
        • Language Processing`"]
    end
    
    %% Flutter Internal Flow
    UI --> BL
    BL --> Data
    BL --> PC
    BL --> FFI
    
    %% Platform Channel Connections
    PC --> iOS_Swift
    PC --> Android_Kotlin
    
    %% FFI Direct Connections
    FFI --> Whisper
    Whisper --> Models
    
    %% Native GPU Connections
    iOS_Swift --> iOS_Metal
    Android_Kotlin --> Android_GPU
    Whisper --> iOS_Metal
    Whisper --> Android_GPU
    
    %% Styling - Dark mode friendly
    classDef flutter fill:#1e3a8a,stroke:#3b82f6,stroke-width:2px,color:#ffffff
    classDef platform fill:#581c87,stroke:#a855f7,stroke-width:2px,color:#ffffff
    classDef native fill:#14532d,stroke:#22c55e,stroke-width:2px,color:#ffffff
    classDef cpp fill:#9a3412,stroke:#f97316,stroke-width:2px,color:#ffffff
    
    class UI,BL,Data flutter
    class PC,FFI platform
    class iOS_Swift,Android_Kotlin,iOS_Metal,Android_GPU native
    class Whisper,Models cpp
```

### 🔄 Recording & Transcription Flow

```mermaid
sequenceDiagram
    participant User
    participant UI as Flutter UI
    participant Cubit as HomeCubit
    participant AudioSvc as AudioService
    participant PC as Platform Channel
    participant Native as Native Layer
    participant FFI as Dart FFI
    participant Whisper as Whisper.cpp
    participant FS as File System
    
    Note over User,FS: 🎤 Voice Recording & Transcription Flow
    
    User->>UI: Tap Record Button
    UI->>Cubit: startRecording()
    
    activate Cubit
    Cubit->>AudioSvc: startRecording()
    AudioSvc->>PC: invokeMethod('startRecording')
    
    PC->>Native: Platform-specific call
    alt iOS
        Native->>Native: AVAudioRecorder.record()
        Note right of Native: Records to .m4a format
    else Android
        Native->>Native: MediaRecorder.start()
        Note right of Native: Records to .wav format
    end
    
    Native-->>PC: Recording started
    PC-->>AudioSvc: Success response
    AudioSvc-->>Cubit: Recording state
    Cubit-->>UI: Update to recording state
    UI-->>User: Show recording animation
    
    Note over User,FS: Recording in progress...
    
    User->>UI: Tap Stop Button
    UI->>Cubit: stopRecording()
    Cubit->>AudioSvc: stopRecording()
    AudioSvc->>PC: invokeMethod('stopRecording')
    
    PC->>Native: Stop recording call
    Native->>Native: Stop & save audio file
    Native->>FS: Write audio file
    Native-->>PC: File path returned
    PC-->>AudioSvc: Audio file path
    AudioSvc-->>Cubit: File saved
    
    Note over User,FS: 🤖 AI Transcription via FFI
    
    Cubit->>FFI: transcribeAudio(filePath)
    activate FFI
    FFI->>Whisper: Load audio file
    Whisper->>Whisper: Process with AI model
    
    alt Apple Silicon (iOS/macOS)
        Whisper->>Whisper: Use Metal GPU acceleration
        Note right of Whisper: Hardware neural network ops
    else Other platforms
        Whisper->>Whisper: CPU-based processing
    end
    
    Whisper->>Whisper: Generate transcription
    Whisper-->>FFI: Text result
    deactivate FFI
    FFI-->>Cubit: Transcription complete
    
    Cubit->>FS: Save VoiceMemo with transcription
    deactivate Cubit
    Cubit-->>UI: Update with transcription
    UI-->>User: Show transcribed text
    
    Note over User,FS: ✅ Complete workflow with native optimizations
```

### 🏗️ Architecture Layers

- **Presentation Layer**: Flutter widgets, UI components, and state management (BLoC/Cubit).
- **Business Logic Layer**: Application logic, use cases, and state orchestration.
- **Data Layer**: Abstract repositories and data sources.
- **Platform Layer**: Native integrations (Platform Channels, FFI) and device-specific services.

#### 📋 What These Diagrams Show

1. **System Architecture Overview**: The complete technology stack from Flutter UI down to native C++ libraries, showing how Platform Channels and FFI enable advanced native integration.

2. **Recording & Transcription Flow**: The end-to-end user journey from tapping record to seeing transcribed text, highlighting the sophisticated native processing pipeline.

3. **Clean Architecture Layers**: How the codebase maintains separation of concerns while enabling complex cross-platform functionality.

For a complete technical breakdown, including diagrams and design patterns, please see the [**Architecture Deep Dive (`ARCHITECTURE.md`)**](./ARCHITECTURE.md).

For detailed feature implementation status and checklist, see [**Feature Status (`FEATURE_STATUS.md`)**](./FEATURE_STATUS.md).

## 🚀 Getting Started

⚠️ **Important**: This project requires Whisper AI model files (~141MB) that are **excluded from the repository** due to GitHub's 100MB file size limit. You must download them separately during setup.

### 📋 Complete Setup Guide

**→ See [SETUP.md](SETUP.md) for complete installation instructions including:**
- Model file download and placement
- Platform-specific dependencies
- Build scripts and troubleshooting
- Alternative model options

### Quick Setup Summary

```bash
# 1. Clone repository
git clone https://github.com/your-username/flutter_voice_bridge.git
cd flutter_voice_bridge

# 2. Download required Whisper model (141MB)
mkdir -p assets/models android/app/src/main/assets/models ios/Runner/Models macos/Runner/Models
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" -o assets/models/ggml-base.en.bin
cp assets/models/ggml-base.en.bin android/app/src/main/assets/models/
cp assets/models/ggml-base.en.bin ios/Runner/Models/
cp assets/models/ggml-base.en.bin macos/Runner/Models/

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

### 1. Prerequisites

- **Flutter**: Ensure you have the Flutter SDK installed. [Installation Guide](https://flutter.dev/docs/get-started/install).
- **IDE**: Android Studio or Visual Studio Code with the Flutter plugin.
- **Platform-specific tools**:
  - **macOS/iOS**: Xcode and CocoaPods.
  - **Android**: Android SDK and NDK.
  - **Build tools**: `cmake` and `git` are required for building the native `whisper.cpp` library.

### 2. Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/flutter_voice_bridge.git
cd flutter_voice_bridge

# 2. Install Flutter packages
flutter pub get
```

### 3. Native Dependencies Setup (Whisper.cpp)

This project includes a **working** native `Whisper.cpp` library for offline transcription. The FFI integration is already configured and functional.

**Current Status**: Model files are **not included** in git due to size limits - you must download them using the instructions in [SETUP.md](SETUP.md).

```bash
# Model files must be downloaded separately (see SETUP.md)
# Native libraries are already configured and ready to use
```

**What's Included**:
1. ✅ FFI wrapper with proper memory management
2. ✅ Platform-specific integration ready to use
3. ✅ Build scripts for native libraries
4. ⚠️ Model files must be downloaded separately

**Current Support**:
- **iOS/macOS**: ✅ Full transcription support (WAV format)
- **Android**: ⚠️ Audio recording works, transcription needs format conversion

For implementation details, see [**Feature Status (`FEATURE_STATUS.md`)**](./FEATURE_STATUS.md).

### 4. Running the App

**After downloading model files** (see [SETUP.md](SETUP.md)), the app is ready to run with full transcription capabilities on iOS/macOS.

```bash
# Run on iOS/macOS for full transcription features
flutter run -d ios
flutter run -d macos

# Run on Android for audio recording and playback
flutter run -d android
```

**🎉 First Launch**: Once model files are in place, you can immediately start recording and transcribing voice memos!

## 🔧 Troubleshooting

### ✅ Transcription Working Status

**Current Status (July 2025)**:
- **iOS/macOS**: ✅ **Transcription fully working** - WAV format compatibility fixed
- **Android**: ⚠️ Audio recording works, transcription needs M4A→WAV conversion

### Android Recording Permissions

The app handles runtime audio recording permissions automatically:
1. Grant microphone permission when prompted
2. The app will guide you through any permission issues
3. Recording and playback work perfectly on Android

### iOS/macOS Transcription Success

**Fixed Issues**:
- ✅ Audio format compatibility (now uses WAV instead of M4A)
- ✅ Whisper model loading and extraction
- ✅ FFI memory management
- ✅ GPU acceleration on Apple Silicon

### Whisper Model Management

**Manual Model Setup Required**:
- ⚠️ Model files are not included in repository (too large for GitHub)
- 📋 Follow [SETUP.md](SETUP.md) for download instructions
- ✅ 147MB English model provides excellent quality
- ✅ Metal GPU acceleration enabled

### Performance Optimization

**Apple Silicon Benefits**:
- 🚀 M1/M2/M3 Mac: GPU-accelerated transcription
- ⚡ Fast inference with Metal backend
- 💾 Efficient memory usage with proper cleanup

## 🤝 Contributing

Contributions are welcome! If you have suggestions for improvements, please open an issue or submit a pull request.

**Model File Policy**: 
- Never commit model files (.bin files are gitignored)
- Document any model changes in [SETUP.md](SETUP.md)
- Include download instructions for any new dependencies

---

_This project is intended for educational purposes and as a demonstration of advanced Flutter capabilities._

