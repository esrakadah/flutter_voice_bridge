# 🎙️ Flutter Voice Bridge

**Flutter Voice Bridge** is a cross-platform application template demonstrating advanced integration of native device features and local AI capabilities within a Flutter app. It provides a robust foundation for building voice-powered applications, featuring audio recording, playback, and offline speech-to-text transcription using `Whisper.cpp`.

This project follows **Clean Architecture** principles and is designed for scalability, testability, and maintainability.

> This repository serves as a learning resource and a starter kit for developers looking to bridge the gap between Flutter and native code for high-performance applications.

## ✨ Features

- **Cross-Platform Audio Recording**: High-quality audio capture on iOS and Android.
- **Local Audio Playback**: Play recorded memos directly within the app.
- **Offline Speech-to-Text**: On-device transcription using `Whisper.cpp` via Dart FFI. No internet connection required.
- **Clean Architecture (MVVM-like)**: A clear separation of concerns between UI, business logic, and data layers.
- **Dependency Injection**: Loose coupling and enhanced testability using `get_it`.
- **State Management with BLoC/Cubit**: Predictable and scalable state management.
- **Native Integration**: Deep integration with native APIs via Platform Channels and Dart FFI.
- **Detailed Documentation**: Comprehensive guides for architecture and setup.

## 🏛️ Project Architecture

The application is structured using a clean, layered architecture that separates concerns and promotes modularity.

- **Presentation Layer**: Flutter widgets, UI components, and state management (BLoC/Cubit).
- **Business Logic Layer**: Application logic, use cases, and state orchestration.
- **Data Layer**: Abstract repositories and data sources.
- **Platform Layer**: Native integrations (Platform Channels, FFI) and device-specific services.

For a complete technical breakdown, including diagrams and design patterns, please see the [**Architecture Deep Dive (`ARCHITECTURE.md`)**](./ARCHITECTURE.md).

## 🚀 Getting Started

Follow these steps to get the project up and running on your local machine.

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

This project relies on a native `whisper.cpp` library for offline transcription. A setup script is provided to automate the build process.

```bash
# Run the build script to download and compile whisper.cpp
./scripts/build_whisper.sh
```

This script will:
1.  Clone the `whisper.cpp` repository into the `native/` directory.
2.  Compile the native library (`.so`, `.dylib`, `.dll`).
3.  Download the default English language model (`ggml-base.en.bin`).
4.  Copy the required assets to the correct platform-specific directories.

For detailed instructions and advanced options, refer to the [**Whisper FFI Integration Setup (`WHISPER_SETUP.md`)**](./WHISPER_SETUP.md).

### 4. Running the App

Once the setup is complete, you can run the application as you would with any other Flutter project.

```bash
# Run on a connected device or simulator
flutter run
```

## 🔧 Troubleshooting

### Android NDK Version Mismatch

If you encounter an error like `Your project is configured with Android NDK X, but plugin Y requires NDK Z`, you need to align the NDK version.

**Solution**: Open `android/app/build.gradle.kts` and set the `ndkVersion` to the one required by the plugins.

```kotlin
// android/app/build.gradle.kts
android {
    // ...
    ndkVersion = "27.0.12077973" // Or the version specified in the error message
    // ...
}
```

### Android Recording Permissions

The app handles runtime audio recording permissions, but if you face issues:
1.  **Uninstall the app** from your device/emulator to reset all permissions.
2.  **Re-run the app** and ensure you **grant** the microphone permission when prompted.

### Whisper Model Not Found

If the app reports that it cannot find the Whisper model file:
1.  Ensure you have run the `./scripts/build_whisper.sh` script successfully.
2.  Verify that the model file (`ggml-base.en.bin`) exists in the `assets/models/` directory and has been copied to the platform-specific asset locations (e.g., `ios/Runner/Models/`).

## 🤝 Contributing

Contributions are welcome! If you have suggestions for improvements, please open an issue or submit a pull request.

---

_This project is intended for educational purposes and as a demonstration of advanced Flutter capabilities._

