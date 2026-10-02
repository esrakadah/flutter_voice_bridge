# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - Unreleased

### Added
- Experimental on-device Gemma chat on iOS (merged from `experimental/flutter-gemma`), with the DevFest Berlin
  2025 talk material under `docs/talks/devfest-berlin-2025/`.
- Delete all recordings.
- CI workflow (format, analyze, test), issue templates, a home screen widget test and a macOS integration test.

### Changed
- whisper.cpp is pinned to v1.7.6 and built from a project-owned `native/whisper/CMakeLists.txt`; the build
  script is re-runnable and no longer edits upstream files.
- Minimum versions: Flutter 3.38, macOS 13.3, iOS 16.0. `pubspec.lock` is now committed.
- `flutter_markdown` replaced by `flutter_markdown_plus`; flutter_lints 6; unused dependencies removed.
- The Hugging Face token is read from `--dart-define=HF_TOKEN` instead of a source constant.
- The ffmpeg `Process.run` demo runs on tap instead of on every rebuild, and is debug-only on macOS.

### Removed
- Linux, Windows and web platform folders.
- `.github/README.md`, which GitHub showed instead of the root README.

### Fixed
- The macOS app did not build on current Xcode (deployment target 10.15).
- The native library embedded absolute build paths and was copied into the iOS project, where it cannot load.
- README and guides claimed iOS transcription, 4 visualization modes and a 2-3x GPU speedup; they now match
  the code.

## [1.0.1] - 2025-10-22

### Updated
- All dependencies to latest versions
- Deprecated API calls to modern Flutter APIs

### Fixed
- All analyzer warnings and lint issues
- Logging system using dart:developer

## [1.0.0] - 2025-07-29 - Initial Release

### ✨ Added
- **Offline AI Transcription**: Speech-to-text using Whisper.cpp with Metal GPU acceleration
- **Cross-Platform Audio Recording**: Native audio recording on iOS, macOS, and Android
- **Animation System**: 4 fullscreen visualization modes (Waveform, Spectrum, Particles, Radial)
- **Dynamic Animation Controls**: Real-time size (50%-300%) and speed (0.5x-2x) adjustment
- **Settings Persistence**: Animation preferences saved across sessions
- **Platform Channels Integration**: Bidirectional communication with native iOS/Android code
- **Dart FFI Implementation**: Direct C++ library integration for AI processing
- **Custom Renderer System**: Hardware-accelerated 60fps animations with Custom Painters
- **Clean Architecture**: MVVM pattern with dependency injection and BLoC state management
- **Comprehensive Documentation**: Setup guides, architecture docs, and learning materials

### 🔧 Technical Features
- **Memory Management**: Proper FFI resource cleanup and native memory handling
- **Error Handling**: Comprehensive error recovery and user feedback
- **Performance Optimization**: GPU acceleration on Apple Silicon (M1/M2/M3)
- **Build Automation**: Automated Whisper.cpp compilation and model download
- **Multi-Platform Support**: iOS, macOS, Android with platform-specific optimizations

### 📚 Documentation
- **README.md**: Complete project overview with quick start guide
- **SETUP.md**: Detailed setup instructions with troubleshooting
- **ARCHITECTURE.md**: Technical deep dive into system design
- **WORKSHOP_GUIDE.md**: Educational modules for learning advanced Flutter
- **CONTRIBUTING.md**: Guidelines for community contributions
- **FEATURE_STATUS.md**: Current implementation status across platforms

### 🎯 Educational Value
- Advanced Platform Channel patterns
- Dart FFI best practices with C++ integration
- Custom animation systems with hardware acceleration
- Clean Architecture implementation in Flutter
- Production-ready state management with BLoC
- Cross-platform native development techniques

### 🌟 Highlights
- **147MB AI Model**: Local Whisper model for completely offline transcription
- **Sub-second Processing**: GPU-accelerated AI inference on Apple Silicon
- **60fps Animations**: Smooth hardware-accelerated visualizations
- **Zero Network Dependencies**: Everything works offline
- **Production Quality**: Error handling, logging, and resource management

## [Planned] - Future Releases

### 🚀 Version 1.1.0 - Android Transcription
- [ ] Complete Android FFI integration for transcription
- [ ] Android-specific performance optimizations
- [ ] Cross-platform model loading improvements

### 🎨 Version 1.2.0 - Enhanced Animations
- [ ] Additional visualization modes (Oscilloscope, Mandala, Matrix)
- [ ] Real-time audio analysis for reactive animations
- [ ] Custom color themes and gradient options

### 🤖 Version 1.3.0 - Extended AI Features
- [ ] Multiple language model support
- [ ] Real-time transcription during recording
- [ ] Keyword highlighting and search functionality

### 🌐 Version 1.4.0 - Web Platform
- [ ] WebAssembly compilation of Whisper.cpp
- [ ] Web Audio API integration
- [ ] Progressive Web App features

### ☁️ Version 2.0.0 - Cloud Integration (Optional)
- [ ] Optional cloud backup with encryption
- [ ] Multi-device synchronization
- [ ] Collaborative features

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/esrakadah/flutter_voice_bridge/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/esrakadah/flutter_voice_bridge/discussions)
- 📧 **Email**: Create an issue for support questions 