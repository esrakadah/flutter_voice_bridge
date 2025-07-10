# Flutter Voice Bridge AI - Local Setup Guide

This guide helps you set up the Flutter Voice Bridge AI project locally with all required dependencies and model files.

## Prerequisites

- **Flutter SDK** (3.16.0 or later)
- **Dart SDK** (3.2.0 or later)
- **Xcode** (for iOS/macOS development)
- **Android Studio** (for Android development)
- **CMake** (for building native Whisper.cpp)
- **Git LFS** (optional, for large file handling)

## Required Model Files

Due to GitHub's 100MB file size limit, the Whisper AI model files are not included in the repository. You need to download them manually.

### Download Whisper Base English Model

The app requires the `ggml-base.en.bin` model file (~141MB). Download it using one of these methods:

#### Method 1: Direct Download (Recommended)

```bash
# Create model directories
mkdir -p assets/models
mkdir -p android/app/src/main/assets/models
mkdir -p ios/Runner/Models
mkdir -p macos/Runner/Models

# Download the model file (choose one location first)
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" -o assets/models/ggml-base.en.bin

# Copy to platform-specific locations
cp assets/models/ggml-base.en.bin android/app/src/main/assets/models/
cp assets/models/ggml-base.en.bin ios/Runner/Models/
cp assets/models/ggml-base.en.bin macos/Runner/Models/
```

#### Method 2: Using Whisper.cpp Repository

```bash
# Clone whisper.cpp submodule
git submodule update --init --recursive

# Download model using whisper.cpp script
cd native/whisper/whisper.cpp
./models/download-ggml-model.sh base.en

# Copy to Flutter asset locations
cp models/ggml-base.en.bin ../../../assets/models/
cp models/ggml-base.en.bin ../../../android/app/src/main/assets/models/
cp models/ggml-base.en.bin ../../../ios/Runner/Models/
cp models/ggml-base.en.bin ../../../macos/Runner/Models/
```

### Verify Model Files

After downloading, verify the files are in place:

```bash
ls -la assets/models/ggml-base.en.bin                    # Should show ~141MB
ls -la android/app/src/main/assets/models/ggml-base.en.bin
ls -la ios/Runner/Models/ggml-base.en.bin
ls -la macos/Runner/Models/ggml-base.en.bin
```

## Platform Setup

### iOS/macOS Setup

1. **Install CocoaPods dependencies:**
   ```bash
   cd ios && pod install && cd ..
   cd macos && pod install && cd ..
   ```

2. **Build native Whisper library:**
   ```bash
   chmod +x scripts/build_whisper.sh
   ./scripts/build_whisper.sh
   ```

3. **Copy native libraries:**
   ```bash
   chmod +x scripts/copy_native_libraries.sh
   ./scripts/copy_native_libraries.sh
   ```

### Android Setup

1. **Ensure Android SDK is configured:**
   ```bash
   flutter doctor -v  # Check Android toolchain
   ```

2. **Accept Android licenses:**
   ```bash
   flutter doctor --android-licenses
   ```

## Project Dependencies

Install Flutter dependencies:

```bash
flutter pub get
```

## Build and Run

### Test the Setup

```bash
# Check everything is configured
flutter doctor

# Run on your preferred platform
flutter run -d macos      # macOS
flutter run -d ios        # iOS Simulator
flutter run -d android    # Android
```

## Project Structure with Models

```
flutter_voice_bridge/
├── assets/models/
│   └── ggml-base.en.bin           # Main model file (~141MB)
├── android/app/src/main/assets/models/
│   └── ggml-base.en.bin           # Android copy
├── ios/Runner/Models/
│   └── ggml-base.en.bin           # iOS copy
├── macos/Runner/Models/
│   └── ggml-base.en.bin           # macOS copy
├── native/whisper/
│   ├── whisper.cpp/               # Whisper.cpp submodule
│   ├── whisper_wrapper.cpp        # C++ wrapper
│   └── whisper_wrapper.h
└── lib/                           # Flutter source code
```

## Troubleshooting

### Model File Issues

- **"Model file not found"**: Ensure model files are in the correct platform directories
- **"Failed to load model"**: Check file permissions and sizes (should be ~141MB)
- **Build errors**: Make sure all dependencies are installed and paths are correct

### Platform-Specific Issues

#### iOS/macOS
- Run `pod install` in ios/ and macos/ directories
- Check Xcode is properly configured
- Verify signing certificates for device deployment

#### Android
- Ensure Android SDK and NDK are installed
- Check `android/local.properties` has correct SDK path
- Run `flutter clean` and `flutter pub get` if gradle issues occur

### Memory Issues

- **Low memory devices**: Consider using `ggml-tiny.en.bin` (~39MB) instead
- **App crashes**: Monitor memory usage during transcription

## Git Workflow

The `.gitignore` file excludes all model files and build artifacts. To contribute:

1. **Never commit model files** - they're too large for GitHub
2. **Document any model changes** in this README
3. **Include setup instructions** for any new dependencies

## Model Alternatives

If the base model is too large for your use case:

| Model | Size | Quality | Use Case |
|-------|------|---------|----------|
| `ggml-tiny.en.bin` | ~39MB | Basic | Testing, low-end devices |
| `ggml-base.en.bin` | ~141MB | Good | **Recommended for production** |
| `ggml-small.en.bin` | ~244MB | Better | High-quality transcription |
| `ggml-medium.en.bin` | ~769MB | Best | Professional use |

## Support

- Check [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
- Review [FEATURE_STATUS.md](FEATURE_STATUS.md) for current capabilities
- Open issues for bugs or feature requests

---

## Quick Start Checklist

- [ ] Flutter SDK installed and configured
- [ ] Download `ggml-base.en.bin` model file
- [ ] Copy model to all platform directories
- [ ] Run `flutter pub get`
- [ ] Build native libraries (iOS/macOS)
- [ ] Test with `flutter run`

Once these steps are complete, you should have a fully functional offline AI voice transcription app! 🎉 