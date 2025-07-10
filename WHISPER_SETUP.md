# Whisper FFI Integration Setup

This document explains how to set up and use Whisper.cpp with Dart FFI for offline speech-to-text transcription in the Flutter Voice Bridge app.

## Overview

The Whisper FFI integration provides:
- **Offline speech recognition** using OpenAI's Whisper models
- **Cross-platform support** (iOS, Android, macOS, Linux, Windows)
- **Clean Dart API** with proper memory management
- **Automatic transcription** after recording completion
- **Keyword extraction** from transcribed text

## Quick Start

### 1. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install system dependencies (macOS)
brew install cmake git

# Install system dependencies (Ubuntu/Debian)
sudo apt update && sudo apt install cmake git build-essential

# Install system dependencies (Windows)
# Install Visual Studio or MinGW, CMake, Git
```

### 2. Build Whisper.cpp

```bash
# Run the automated build script
./scripts/build_whisper.sh

# Or with help to see options
./scripts/build_whisper.sh --help
```

This script will:
- Download Whisper.cpp source code
- Compile the native library for your platform
- Download the default Whisper model (base.en)
- Set up FFI bindings
- Copy files to Flutter project directories

### 3. Enable Real Transcription

Edit `lib/di.dart` to switch from mock to real transcription:

```dart
// Change this line:
getIt.registerLazySingleton<TranscriptionService>(() => MockTranscriptionService());

// To this:
getIt.registerLazySingleton<TranscriptionService>(() => WhisperTranscriptionService());
```

### 4. Test the Integration

```bash
# Run the app
flutter run

# Record audio and check logs for transcription results
# Look for logs with tag: VoiceBridge.Transcription
```

## Architecture

### FFI Service Structure

```
lib/core/transcription/
├── whisper_ffi_service.dart       # Low-level FFI bindings
├── transcription_service.dart     # High-level service interface
└── [service implementations]
```

### Key Components

1. **WhisperFFIService**: Direct FFI interface to native library
2. **WhisperTranscriptionService**: High-level Dart service
3. **MockTranscriptionService**: Development/testing implementation
4. **TranscriptionState**: BLoC states for UI integration

### Service Interface

```dart
abstract class TranscriptionService {
  Future<void> initialize([String? modelPath]);
  Future<String> transcribeAudio(String audioFilePath);
  Future<List<String>> extractKeywords(String text);
  Future<bool> isInitialized();
  Future<void> dispose();
}
```

## FFI Implementation Details

### Native Function Bindings

The FFI service binds to these C functions:

```c
// Initialize Whisper with model file
whisper_context* whisper_init(const char* model_path);

// Transcribe audio file  
char* whisper_transcribe(whisper_context* ctx, const char* audio_path);

// Clean up resources
void whisper_free(whisper_context* ctx);
void whisper_free_string(char* str);
```

### Memory Management

- **Automatic cleanup** in service disposal
- **Proper string handling** with UTF-8 conversion
- **Resource tracking** to prevent memory leaks
- **Exception safety** with try-catch blocks

### Platform-Specific Libraries

| Platform | Library File | Location |
|----------|-------------|----------|
| iOS | `libwhisper.dylib` | `ios/Runner/` |
| Android | `libwhisper.so` | `android/app/src/main/jniLibs/` |
| macOS | `libwhisper.dylib` | `macos/Runner/` |
| Linux | `libwhisper.so` | `linux/` |
| Windows | `whisper.dll` | `windows/` |

## State Management Integration

### Transcription States

The app includes dedicated states for transcription:

```dart
// Transcription in progress
TranscriptionInProgress(audioFilePath: string)

// Transcription completed successfully  
TranscriptionCompleted(
  audioFilePath: string,
  transcribedText: string, 
  extractedKeywords: List<String>
)

// Transcription failed
TranscriptionError(audioFilePath: string, errorMessage: string)
```

### Automatic Workflow

1. **Recording completes** → `RecordingCompleted` state
2. **Auto-start transcription** → `TranscriptionInProgress` state
3. **Transcription succeeds** → `TranscriptionCompleted` state
4. **Results logged** to console (no UI changes yet)

## Model Management

### Default Model

The build script downloads `ggml-base.en.bin` (39MB):
- **Language**: English only
- **Size**: ~39MB
- **Speed**: Fast inference
- **Quality**: Good for most use cases

### Model Locations

Models are copied to platform-specific locations:

```
assets/models/ggml-base.en.bin           # Flutter assets
ios/Runner/Models/ggml-base.en.bin       # iOS bundle
android/app/src/main/assets/models/      # Android assets  
macos/Runner/Models/ggml-base.en.bin     # macOS bundle
```

### Using Different Models

To use a different model:

1. Download from [Hugging Face](https://huggingface.co/ggerganov/whisper.cpp)
2. Place in appropriate platform directories
3. Update model path in service initialization

```dart
// Custom model path
await transcriptionService.initialize('/path/to/custom-model.bin');
```

## Troubleshooting

### Common Issues

**Build Errors:**
```bash
# Check dependencies
cmake --version
git --version

# Clean and rebuild
rm -rf native/whisper
./scripts/build_whisper.sh
```

**Runtime Library Loading:**
```
Failed to load Whisper native library
```
- Verify library exists in platform directory
- Check library architecture matches target platform
- Ensure proper file permissions

**Model Loading Errors:**
```
Whisper model file not found
```
- Verify model file exists and is readable
- Check file size (should be ~39MB for base.en)
- Ensure proper model format (`.bin` file)

**FFI Binding Errors:**
```
Failed to bind Whisper native functions
```
- Verify library exports required functions
- Check C wrapper compilation
- Ensure proper symbol visibility

### Debug Logging

Enable detailed logging by checking these log tags:

```dart
// FFI service logs
developer.log('...', name: 'VoiceBridge.WhisperFFI');

// Transcription service logs  
developer.log('...', name: 'VoiceBridge.Transcription');

// Results logging
developer.log('...', name: 'VoiceBridge.Transcription');
```

### Performance Tips

1. **Model Loading**: Models are loaded lazily on first transcription
2. **Background Processing**: Consider using `compute()` for long transcriptions
3. **Model Size**: Use smaller models for faster inference
4. **Audio Format**: Ensure audio is in compatible format (.m4a works)

## Development Workflow

### Using Mock Service

During development, use `MockTranscriptionService`:

```dart
// lib/di.dart - Development mode
getIt.registerLazySingleton<TranscriptionService>(() => MockTranscriptionService());
```

Benefits:
- **No native dependencies** required
- **Predictable results** for testing
- **Fast development** iteration
- **Simulated delays** for realistic UX

### Testing Strategy

1. **Unit Tests**: Test service interfaces with mocks
2. **Integration Tests**: Test FFI bindings with real library  
3. **Widget Tests**: Test transcription state handling
4. **Manual Testing**: Record and transcribe real audio

### Adding Features

To extend transcription functionality:

1. **Add new states** in `home_state.dart`
2. **Update service interface** in `transcription_service.dart`
3. **Implement in services** (both real and mock)
4. **Update state management** in `home_cubit.dart`
5. **Add UI components** when ready

## Future Enhancements

### Planned Features

- **Background transcription** with isolates
- **Real-time transcription** during recording
- **Multiple language support** 
- **Custom model management**
- **Transcription confidence scores**
- **Audio preprocessing** (noise reduction)

### Integration Points

- **Search functionality** using transcribed text
- **Voice commands** recognition
- **Smart categorization** using keywords
- **Cloud sync** of transcriptions
- **Export functionality** (PDF, text files)

## Contributing

When contributing to Whisper FFI integration:

1. **Test on multiple platforms** before submitting
2. **Update documentation** for any API changes
3. **Include both real and mock implementations**
4. **Add proper error handling** and logging
5. **Follow memory management** best practices

## Resources

- [Whisper.cpp GitHub](https://github.com/ggerganov/whisper.cpp)
- [Flutter FFI Documentation](https://docs.flutter.dev/platform-integration/c-interop)
- [Dart FFI Package](https://pub.dev/packages/ffi)
- [OpenAI Whisper](https://openai.com/research/whisper)

---

**Status**: ✅ Core FFI integration complete, ready for development and testing
**Next**: UI integration and background processing with isolates 