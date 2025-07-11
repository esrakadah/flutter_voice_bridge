# Flutter Voice Bridge - Setup Guide

This guide helps you set up the Flutter Voice Bridge project locally with all required dependencies and working transcription capabilities.

> 🎯 **Goal**: Get you from zero to working AI transcription in under 10 minutes!

## 🔍 System Requirements

### **Minimum Requirements**
- **Flutter SDK**: 3.16.0 or later ([Download](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: 3.2.0 or later (included with Flutter)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 2GB free space (for dependencies and AI models)
- **Internet**: Required for initial setup and model download

### **Platform-Specific Requirements**

#### **macOS (Recommended Platform)**
- **macOS**: 12.0 (Monterey) or later
- **Xcode**: 15.0 or later ([Download from App Store](https://apps.apple.com/app/xcode/id497799835))
- **Command Line Tools**: `xcode-select --install`
- **CMake**: `brew install cmake` ([Install Homebrew](https://brew.sh/))
- **Advantage**: Full GPU acceleration with Metal, best performance

#### **iOS Development**
- **Xcode**: 15.0 or later
- **iOS Simulator**: iOS 15.0+ target
- **Apple Developer Account**: For device deployment (optional)
- **Features**: Full audio recording + AI transcription

#### **Android Development**
- **Android Studio**: 2023.1.1 (Flamingo) or later
- **Android SDK**: API level 21 (Android 5.0) or later  
- **NDK**: 25.1.8937393 or later (for future native features)
- **Features**: Audio recording working, transcription coming soon

## ✅ Quick Start (Recommended)

The fastest way to get up and running with **working transcription**:

```bash
# 1. Clone the repository
git clone https://github.com/esrakadah/flutter_voice_bridge.git
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

## 📋 Quick Verification Checklist

After setup, verify everything works:

- [ ] `flutter doctor` shows no critical issues
- [ ] App launches without errors
- [ ] Audio recording works (tap record button)
- [ ] Audio playback works (tap play button)
- [ ] Transcription works (record speech, check logs)
- [ ] Console shows "✅ Transcription completed successfully"

**🎯 Success**: You should be able to record audio and see transcribed text in the logs within seconds!

## 🆘 Common Issues & Solutions

### **"Flutter not found" or "Command not found"**
```bash
# Add Flutter to your PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Or install via package manager
# macOS: brew install flutter
# Check installation: flutter doctor -v
```

### **"Xcode license not accepted"**
```bash
sudo xcodebuild -license accept
xcode-select --install
```

### **"CMake not found"**
```bash
# macOS
brew install cmake

# Ubuntu/Debian
sudo apt install cmake build-essential

# Windows
# Download from https://cmake.org/download/
```

### **"Permission denied" on build script**
```bash
chmod +x ./scripts/build_whisper.sh
./scripts/build_whisper.sh
```

### **"Git LFS not found" (Large File Storage)**
```bash
# Install Git LFS for large model files
brew install git-lfs              # macOS
sudo apt install git-lfs          # Ubuntu
git lfs install
```

### **Android build failures**
```bash
# Clean and retry
flutter clean
flutter pub get
flutter doctor --android-licenses
flutter build apk --debug
```

### **iOS/macOS build failures**
```bash
# Clean Xcode build cache
rm -rf ios/build/ macos/build/
cd ios && pod install && cd ..
cd macos && pod install && cd ..
flutter clean && flutter run -d macos
```

### **Model download failures**
```bash
# Manual model download
cd assets/models/
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" -o ggml-base.en.bin

# Copy to platform directories
cp ggml-base.en.bin ../ios/Runner/Models/
cp ggml-base.en.bin ../macos/Runner/Models/
```

### **Transcription not working**
1. **Check model file exists**:
   ```bash
   ls -la assets/models/ggml-base.en.bin
   # Should show ~147MB file
   ```

2. **Check native library**:
   ```bash
   ls -la macos/Runner/libwhisper_ffi.dylib
   # Should exist for macOS
   ```

3. **Enable verbose logging**:
   ```bash
   flutter run -d macos --verbose
   ```

4. **Check console for errors**:
   - Look for "WhisperFFI" initialization messages
   - Look for "✅ Transcription completed successfully"
   - Check for memory or file access errors

### **Performance issues**
- **Slow transcription**: Ensure you're on Apple Silicon for GPU acceleration
- **High memory usage**: Close other apps, model requires ~200MB RAM
- **App crashes**: Check available storage space and RAM

## 🔧 Development Tools Setup

### **VS Code Extensions** (Recommended)
```bash
# Install useful extensions
code --install-extension dart-code.dart-code
code --install-extension dart-code.flutter
code --install-extension ms-vscode.cmake-tools
```

### **Android Studio Plugins**
- Flutter Plugin
- Dart Plugin  
- CMake Support Plugin

### **Useful CLI Tools**
```bash
# macOS package manager
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter version management
dart pub global activate fvm
fvm install stable
```

## 🎯 Platform-Specific Notes

### **macOS Development**
- **Best Experience**: Full transcription + GPU acceleration
- **Metal GPU**: Automatic on Apple Silicon (M1/M2/M3/M4)
- **Rosetta**: Works on Intel Macs but slower transcription

### **iOS Development**  
- **Device vs Simulator**: Both work, device has better performance
- **Signing**: Automatic signing works for development
- **TestFlight**: Ready for distribution testing

### **Android Development**
- **Current Status**: Audio recording works perfectly
- **Transcription**: Coming soon (FFI integration in progress)
- **NDK**: Required for future native library support

## 🌐 Network & Firewall

### **Required Downloads During Setup**
- Whisper.cpp source code (~50MB)
- AI model file (~147MB)  
- CocoaPods dependencies (~100MB)
- Flutter packages (~50MB)

### **Firewall Considerations**
- Allow connections to GitHub (git clone)
- Allow connections to HuggingFace (model download)
- Allow connections to pub.dev (Flutter packages)

---

## 📞 Still Need Help?

If you encounter issues not covered here:

1. **Check our Issues**: [GitHub Issues](https://github.com/esrakadah/flutter_voice_bridge/issues)
2. **Read the Docs**: [Complete Documentation](./README.md)
3. **Create an Issue**: Describe your problem with:
   - Your operating system and version
   - Flutter doctor output
   - Error messages
   - Steps you tried

**We're here to help make this project accessible to everyone!** 🚀 