# 🎙️ Flutter Voice Bridge

**Flutter Voice Bridge** is a **production-ready** cross-platform application showcasing advanced integration of native device features and local AI capabilities within a Flutter app. It provides a robust foundation for building voice-powered applications, featuring audio recording, playback, and **fully working offline speech-to-text transcription** using `Whisper.cpp` with GPU acceleration.

This project follows **Clean Architecture** principles and demonstrates **real-world implementation** of complex Flutter concepts including FFI, Platform Channels, and AI integration.

> **🎯 Status**: **PRODUCTION READY** - Full iOS/macOS transcription with GPU acceleration working perfectly. Android audio recording fully functional.

## ✨ Features

- **✅ Cross-Platform Audio Recording**: High-quality audio capture on iOS, macOS, and Android with optimized formats (WAV 16kHz).
- **✅ Local Audio Playback**: Play recorded memos directly within the app across all platforms.
- **✅ Offline Speech-to-Text**: **FULLY WORKING** on-device transcription using `Whisper.cpp` via Dart FFI with Metal GPU acceleration on Apple Silicon.
- **✅ Real-time Audio Visualization**: Custom waveform, spectrum, and particle visualizations during recording.
- **✅ Keyword Extraction**: Automatic keyword detection from transcribed text with intelligent filtering.
- **✅ Clean Architecture (MVVM)**: A clear separation of concerns between UI, business logic, and data layers.
- **✅ Dependency Injection**: Loose coupling and enhanced testability using `get_it`.
- **✅ State Management with BLoC/Cubit**: Predictable and scalable state management with real-time UI updates.
- **✅ Native Integration**: Deep integration with native APIs via Platform Channels and Dart FFI.
- **✅ GPU Acceleration**: Metal GPU support on Apple Silicon (M1/M2/M3) for fast AI inference.
- **✅ Native Platform Views**: Custom native UI components integrated seamlessly with Flutter.
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
        • AudioVisualizer<br/>
        • NativeTextView (Platform View)`"]
        
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
        • Audio Recording Control<br/>
        • Permission Management<br/>
        • Platform View Integration`"]
        
        FFI["`**Dart FFI**<br/>
        • Direct C++ Integration<br/>
        • Whisper.cpp Binding<br/>
        • Memory Management`"]
    end
    
    subgraph "iOS/macOS Native"
        iOS_Swift["`**Swift Implementation**<br/>
        • AVAudioRecorder<br/>
        • Audio Session Config<br/>
        • WAV Format (16kHz)`"]
        
        iOS_Metal["`**Metal GPU**<br/>
        • Hardware Acceleration<br/>
        • Neural Network Ops<br/>
        • Apple M1/M2/M3 Support`"]
    end
    
    subgraph "Android Native"
        Android_Kotlin["`**Kotlin Implementation**<br/>
        • MediaRecorder<br/>
        • Audio Permissions<br/>
        • WAV Format`"]
        
        Android_GPU["`**GPU Support**<br/>
        • OpenGL/Vulkan<br/>
        • Compute Shaders`"]
    end
    
    subgraph "AI Processing Layer"
        Whisper["`**Whisper.cpp**<br/>
        • OpenAI Whisper Model<br/>
        • GGML Backend<br/>
        • 147MB Base Model<br/>
        • Real-time Processing`"]
        
        Models["`**AI Models**<br/>
        • ggml-base.en.bin<br/>
        • English Language Support<br/>
        • Offline Inference`"]
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
    
    %% GPU Acceleration Paths
    iOS_Swift --> iOS_Metal
    Android_Kotlin --> Android_GPU
    Whisper --> iOS_Metal
    Whisper --> Android_GPU
    
    %% Styling
    classDef flutter fill:#1e3a8a,stroke:#3b82f6,stroke-width:2px,color:#ffffff
    classDef platform fill:#581c87,stroke:#a855f7,stroke-width:2px,color:#ffffff
    classDef native fill:#14532d,stroke:#22c55e,stroke-width:2px,color:#ffffff
    classDef ai fill:#9a3412,stroke:#f97316,stroke-width:2px,color:#ffffff
    
    class UI,BL,Data flutter
    class PC,FFI platform
    class iOS_Swift,Android_Kotlin,iOS_Metal,Android_GPU native
    class Whisper,Models ai
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
    participant GPU as Metal GPU
    participant FS as File System
    
    Note over User,FS: 🎤 Complete Voice Recording & AI Transcription Pipeline
    
    User->>UI: Tap Record Button
    UI->>Cubit: startRecording()
    
    activate Cubit
    Cubit->>AudioSvc: startRecording()
    AudioSvc->>PC: invokeMethod('startRecording')
    
    PC->>Native: Platform-specific audio setup
    alt iOS/macOS
        Native->>Native: AVAudioRecorder.record()
        Note right of Native: 16kHz WAV format for Whisper
    else Android
        Native->>Native: MediaRecorder.start()
        Note right of Native: 16kHz WAV format
    end
    
    Native-->>PC: Recording started
    PC-->>AudioSvc: Success response
    AudioSvc-->>Cubit: Recording active
    Cubit-->>UI: RecordingInProgress state
    UI-->>User: Show waveform animation
    
    Note over User,FS: 🎵 Recording in progress...
    
    User->>UI: Tap Stop Button
    UI->>Cubit: stopRecording()
    Cubit->>AudioSvc: stopRecording()
    AudioSvc->>PC: invokeMethod('stopRecording')
    
    PC->>Native: Stop recording
    Native->>Native: Finalize audio file
    Native->>FS: Save WAV file (16kHz, 16-bit, mono)
    Native-->>PC: File path returned
    PC-->>AudioSvc: Audio file saved
    AudioSvc-->>Cubit: Recording completed
    
    Note over User,FS: 🤖 AI Transcription via FFI (WORKING)
    
    Cubit->>FFI: transcribeAudio(filePath)
    activate FFI
    FFI->>Whisper: Initialize model (if needed)
    FFI->>Whisper: Load & validate audio file
    Whisper->>Whisper: Read WAV samples
    
    alt Apple Silicon (M1/M2/M3)
        Whisper->>GPU: Metal GPU acceleration
        GPU->>GPU: Neural network inference
        GPU-->>Whisper: Accelerated results
        Note right of GPU: ~2-3x faster than CPU
    else Other platforms
        Whisper->>Whisper: CPU-based processing
        Note right of Whisper: Still very fast
    end
    
    Whisper->>Whisper: Generate text transcription
    Whisper-->>FFI: Return transcribed text
    deactivate FFI
    FFI-->>Cubit: Transcription completed
    
    Cubit->>FS: Save VoiceMemo with transcription
    deactivate Cubit
    Cubit-->>UI: TranscriptionCompleted state
    UI-->>User: Show transcribed text
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.16.0+
- Xcode (for iOS/macOS)
- Android Studio (for Android)
- CMake (for native libraries)

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd flutter_voice_bridge

# Install dependencies
flutter pub get

# Build native Whisper library
./scripts/build_whisper.sh

# Run on your platform
flutter run -d macos    # Recommended for full transcription
flutter run -d ios      # iOS Simulator
flutter run -d android  # Android
```

## 🎯 Key Features Demonstrated

### **✅ Working Features**
- **Audio Recording**: Full platform integration with native APIs
- **Speech-to-Text**: Offline transcription with 147MB Whisper model
- **GPU Acceleration**: Metal GPU support on Apple Silicon
- **Clean Architecture**: Production-ready code organization
- **State Management**: BLoC pattern with immutable states
- **Error Handling**: Comprehensive error recovery
- **Memory Management**: Proper FFI resource cleanup
- **Platform Views**: Native UI components in Flutter

### **🔧 Technical Achievements**
- **Platform Channels**: Bidirectional Flutter ↔ Native communication
- **Dart FFI**: Direct C++ library integration with memory safety
- **AI Integration**: Local Whisper.cpp with GPU acceleration
- **Audio Processing**: 16kHz WAV format optimized for speech recognition
- **Multi-threading**: Background transcription using isolates
- **Native Libraries**: Cross-platform C++ compilation and deployment

## 📱 Platform Status

| Platform | Audio Recording | Transcription | GPU Acceleration | Status |
|----------|----------------|---------------|------------------|---------|
| **iOS** | ✅ Working | ✅ Working | ✅ Metal | **Ready** |
| **macOS** | ✅ Working | ✅ Working | ✅ Metal | **Ready** |
| **Android** | ✅ Working | ⚠️ Partial | ⚠️ OpenGL | In Progress |

## 📚 Documentation

- **[SETUP.md](./SETUP.md)** - Complete setup instructions
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical architecture deep dive  
- **[FEATURE_STATUS.md](./FEATURE_STATUS.md)** - Current implementation status
- **[WHISPER_SETUP.md](./WHISPER_SETUP.md)** - AI transcription setup guide
- **[WORKSHOP_GUIDE.md](./WORKSHOP_GUIDE.md)** - Learning modules and tutorials

## 🏆 Learning Outcomes

This project demonstrates **production-grade Flutter development** including:

### **🔧 Technical Skills**
- Advanced Platform Channel implementation
- Dart FFI with C++ library integration
- AI model integration and optimization
- Clean Architecture patterns
- Advanced state management
- Memory management and resource cleanup
- Performance optimization techniques

### **🏗️ Architecture Patterns**
- Clean Architecture (MVVM)
- Dependency Injection
- Repository Pattern
- Observer Pattern (BLoC)
- Factory Pattern
- Service Locator Pattern

### **📱 Platform Integration**
- Native iOS/macOS Swift development
- Native Android Kotlin development
- Cross-platform native library compilation
- GPU acceleration integration
- Audio processing and optimization

## 🎯 Real-World Applications

The patterns and techniques demonstrated here are directly applicable to:

- **AI-powered mobile apps** (chatbots, voice assistants, image recognition)
- **Multimedia applications** (audio/video processing, streaming)
- **Performance-critical apps** (games, real-time processing)
- **Enterprise applications** (offline-first, native integration)
- **IoT and hardware integration** (sensor data, device communication)

## 🏅 Achievement Unlocked

✅ **Offline AI Integration**: Successfully implemented local speech recognition  
✅ **Platform Mastery**: Native audio integration across iOS, macOS, Android  
✅ **Architecture Excellence**: Clean, maintainable, and testable codebase  
✅ **Performance Optimization**: GPU-accelerated AI inference  
✅ **Production Ready**: Error handling, logging, and resource management  

---

**Built with ❤️ using Flutter, Dart FFI, and Whisper.cpp**

