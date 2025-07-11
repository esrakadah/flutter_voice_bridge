# Flutter Voice Bridge AI - Setup Guide

This guide helps you set up the Flutter Voice Bridge AI project locally with all required dependencies and working transcription capabilities.

## ✅ Quick Start (Recommended)

The fastest way to get up and running with **working transcription**:

```bash
# 1. Clone the repository
git clone <repository-url>
cd flutter_voice_bridge

# 2. Install Flutter dependencies
flutter pub get

# 3. Build native Whisper library (includes model download)
./scripts/build_whisper.sh

# 4. Run on macOS/iOS for full transcription features
flutter run -d macos    # Recommended - full GPU acceleration
flutter run -d ios      # iOS Simulator
flutter run -d android  # Android - audio recording only
```

**🎉 That's it!** The app will be fully functional with offline transcription on iOS/macOS.

## Prerequisites

- **Flutter SDK** (3.16.0 or later)
- **Dart SDK** (3.2.0 or later)
- **Xcode** (for iOS/macOS development)
- **Android Studio** (for Android development)
- **CMake** (for building native Whisper.cpp)

## What the Build Script Does

The `./scripts/build_whisper.sh` script automatically:

1. ✅ Downloads and compiles Whisper.cpp library
2. ✅ Downloads the Whisper model file (ggml-base.en.bin, ~147MB)
3. ✅ Copies native libraries to correct platform directories
4. ✅ Sets up FFI bindings
5. ✅ Configures app bundle integration

**No manual file downloads required!**

## Platform-Specific Setup

### iOS/macOS Setup (Recommended)

```bash
# Install CocoaPods dependencies
cd ios && pod install && cd ..
cd macos && pod install && cd ..

# Build native libraries (if not done already)
./scripts/build_whisper.sh

# Copy libraries to app bundle
./scripts/copy_native_libraries.sh
```

### Android Setup

```bash
# Ensure Android SDK is configured
flutter doctor -v

# Accept Android licenses
flutter doctor --android-licenses

# Build for Android
flutter build apk --debug
```

## Verify Installation

### Test Audio Recording
```bash
flutter run -d macos
# Tap record button → Should start recording immediately
# Tap stop → Should save audio file
```

### Test Transcription (iOS/macOS)
```bash
flutter run -d macos
# Record some speech → Stop recording
# Check console logs for transcription output
# Look for: "Transcription completed: [your text]"
```

### Expected Output
You should see logs like:
```
🤖 Initializing Whisper with model: [path]
✅ Whisper context initialized successfully
🎵 Starting transcription for: [audio file]
✅ Transcription completed successfully
📄 Result: "Your spoken text appears here"
```

## Project Structure After Setup

```
flutter_voice_bridge/
├── assets/models/
│   └── ggml-base.en.bin           # Main AI model (~147MB)
├── ios/Runner/
│   ├── libwhisper_ffi.dylib       # iOS native library
│   └── Models/
│       └── ggml-base.en.bin       # iOS model copy
├── macos/Runner/
│   ├── libwhisper_ffi.dylib       # macOS native library
│   └── Models/
│       └── ggml-base.en.bin       # macOS model copy
├── native/whisper/
│   ├── whisper.cpp/               # Whisper.cpp source
│   ├── whisper_wrapper.cpp        # C++ FFI wrapper
│   └── whisper_wrapper.h
└── lib/                           # Flutter source code
```

## Troubleshooting

### Build Script Issues

**Permission denied:**
```bash
chmod +x ./scripts/build_whisper.sh
./scripts/build_whisper.sh
```

**CMake not found:**
```bash
# macOS
brew install cmake

# Ubuntu/Debian
sudo apt install cmake

# Windows
# Install CMake from https://cmake.org/download/
```

### Transcription Not Working

**Check model file:**
```bash
ls -la assets/models/ggml-base.en.bin
# Should show ~147MB file
```

**Check native library:**
```bash
ls -la macos/Runner/libwhisper_ffi.dylib
# Should exist for macOS
```

**Check console logs:**
```bash
flutter run -d macos
# Look for Whisper initialization messages
# Look for "✅ WhisperFFI Service initialized successfully"
```

### Platform-Specific Issues

#### iOS/macOS
- **Xcode errors**: Ensure Xcode command line tools are installed: `xcode-select --install`
- **Signing issues**: Check your Apple Developer account and certificates
- **Metal GPU**: Requires Apple Silicon (M1/M2/M3) for GPU acceleration

#### Android
- **NDK issues**: Ensure Android NDK is installed via Android Studio
- **Build failures**: Try `flutter clean && flutter pub get`
- **Audio permissions**: Grant microphone permission when prompted

### Performance Issues

**Slow transcription:**
- Ensure you're on Apple Silicon for GPU acceleration
- Check available RAM (model requires ~200MB)
- Close other memory-intensive apps

**App crashes:**
- Check console for memory errors
- Verify model file integrity
- Try `flutter clean && flutter run`

## Alternative Model Options

If the default model is too large or slow:

| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| `ggml-tiny.en.bin` | ~39MB | Very Fast | Basic | Testing, low-end devices |
| `ggml-base.en.bin` | ~147MB | Fast | **Good** | **Default - Recommended** |
| `ggml-small.en.bin` | ~244MB | Medium | Better | High-quality transcription |
| `ggml-medium.en.bin` | ~769MB | Slow | Best | Professional use |

To use a different model:
```bash
# Download alternative model
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin" -o assets/models/ggml-tiny.en.bin

# Copy to platform directories
cp assets/models/ggml-tiny.en.bin ios/Runner/Models/
cp assets/models/ggml-tiny.en.bin macos/Runner/Models/
```

## Development Workflow

### Clean Setup
```bash
flutter clean
flutter pub get
./scripts/build_whisper.sh
flutter run -d macos
```

### Testing Changes
```bash
# After code changes
flutter hot reload    # For UI changes
flutter hot restart   # For logic changes
flutter run           # For native changes
```

### Debugging Transcription
```bash
# Enable verbose logging
flutter run -d macos --verbose

# Check for FFI issues
grep "WhisperFFI" logs.txt

# Check for platform channel issues
grep "Audio" logs.txt
```

## Git Workflow

### What's Included in Repository
- ✅ Flutter source code
- ✅ Native wrapper code (C++)
- ✅ Build scripts
- ✅ Platform configuration
- ❌ Model files (too large for Git)
- ❌ Build artifacts

### What to Ignore
The `.gitignore` excludes:
- `assets/models/*.bin` (AI models)
- `build/` (compilation outputs)
- `*.dylib`, `*.so`, `*.dll` (native libraries)

## Support & Documentation

- **[README.md](./README.md)** - Project overview and features
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical deep dive
- **[FEATURE_STATUS.md](./FEATURE_STATUS.md)** - Current capabilities
- **[WHISPER_SETUP.md](./WHISPER_SETUP.md)** - AI transcription details

---

## Quick Verification Checklist

After setup, verify everything works:

- [ ] `flutter doctor` shows no critical issues
- [ ] App launches without errors
- [ ] Audio recording works (tap record button)
- [ ] Audio playback works (tap play button)
- [ ] Transcription works (record speech, check logs)
- [ ] Console shows "✅ Transcription completed successfully"

**🎯 Success**: You should be able to record audio and see transcribed text in the logs within seconds!

---

**Need help?** Check the troubleshooting section above or review the logs for specific error messages. 