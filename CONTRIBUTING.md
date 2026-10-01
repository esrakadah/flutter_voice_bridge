# 🤝 Contributing to Flutter Voice Bridge

Thank you for your interest in contributing! This project serves both as a production app and an educational resource for the Flutter community.

## 🎯 Ways to Contribute

### 🐛 **Bug Reports**
Found something broken? Help us fix it!
- Search [existing issues](https://github.com/esrakadah/flutter_voice_bridge/issues) first
- Use our [bug report template](https://github.com/esrakadah/flutter_voice_bridge/issues/new?template=bug_report.md)
- Include your environment details (`flutter doctor -v`)

### ✨ **Feature Requests**
Have a great idea? We'd love to hear it!
- Check [existing feature requests](https://github.com/esrakadah/flutter_voice_bridge/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
- Use our [feature request template](https://github.com/esrakadah/flutter_voice_bridge/issues/new?template=feature_request.md)
- Explain the use case and potential implementation

### 📝 **Documentation**
Help make this project more accessible!
- Fix typos or improve clarity
- Add examples or tutorials
- Translate documentation
- Create video tutorials or blog posts

### 🔧 **Code Contributions**
Ready to get your hands dirty?
- Fix bugs or implement features
- Improve performance or add tests
- Enhance platform compatibility
- Add new animation modes or AI models

### 🎓 **Educational Content**
Share your knowledge!
- Add workshop modules
- Create learning examples
- Write technical blog posts
- Record tutorial videos

## 🚀 Getting Started

### 1. **Fork & Clone**
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/flutter_voice_bridge.git
cd flutter_voice_bridge
git remote add upstream https://github.com/esrakadah/flutter_voice_bridge.git
```

### 2. **Setup Development Environment**
```bash
# Install dependencies
flutter pub get

# Build native libraries
./scripts/build_whisper.sh

# Verify everything works
flutter test
flutter run -d macos  # or ios/android
```

### 3. **Create a Branch**
```bash
git checkout -b feature/amazing-new-feature
# or
git checkout -b fix/nasty-bug
```

## 📋 Development Guidelines

### **Code Style**
- Follow [Dart/Flutter style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comprehensive documentation for public APIs
- Keep functions small and focused (< 20 lines when possible)

### **Testing Requirements**
- Add unit tests for new business logic
- Add widget tests for new UI components
- Test on multiple platforms (iOS, macOS, Android)
- Ensure all existing tests pass

### **Commit Guidelines**
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```bash
feat: add new animation mode for particles
fix: resolve memory leak in FFI service
docs: improve setup instructions for Windows
test: add unit tests for transcription service
```

### **Platform Considerations**
- **iOS/macOS**: Test on both simulator and device
- **Android**: Test on different API levels (21+)
- **Native Code**: Ensure memory safety in FFI/Platform Channels
- **Performance**: Profile memory usage and rendering performance

## 🔍 Code Review Process

### **Before Submitting**
- [ ] Code follows style guidelines
- [ ] All tests pass locally
- [ ] Documentation is updated
- [ ] No merge conflicts with main branch

### **Pull Request Template**
```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Test addition

## Testing
- [ ] Tested on iOS
- [ ] Tested on macOS  
- [ ] Tested on Android
- [ ] Added/updated tests
- [ ] All tests pass

## Screenshots (if applicable)
Add screenshots or videos of new features
```

### **Review Process**
1. **Automated Checks**: CI/CD runs tests and builds
2. **Code Review**: Maintainers review code quality
3. **Platform Testing**: Test on multiple platforms
4. **Documentation**: Verify docs are complete
5. **Merge**: Approved PRs are merged to main

## 🏗️ Project Structure

Understanding the codebase:
```
lib/
├── core/                    # Platform abstractions
│   ├── audio/              # Audio recording/playback
│   ├── transcription/      # AI services (Whisper)
│   └── platform/           # Platform Channel interfaces
├── data/                   # Data layer (models, services)
├── ui/                     # Presentation layer
│   ├── views/             # Pages/screens
│   ├── components/        # Reusable UI components
│   └── widgets/           # Atomic UI elements
├── di.dart                # Dependency injection setup
└── main.dart              # App entry point

native/                    # Native C++ code
├── whisper/              # Whisper.cpp integration
└── ...

ios/, macos/, android/     # Platform-specific code
```

## 🎯 Priority Areas

### **High Priority**
- Android transcription support (FFI integration)
- Performance optimizations
- Memory leak fixes
- Test coverage improvements

### **Medium Priority**
- Additional animation modes
- More AI model options
- Web platform support (WebAssembly)
- CI/CD improvements

### **Educational Priority**
- More workshop modules
- Video tutorials
- Blog post examples
- Conference talk materials

## 🐛 Bug Triage

### **Severity Levels**
- **Critical**: App crashes, data loss, security issues
- **High**: Major features broken, significant performance issues
- **Medium**: Minor features broken, UI glitches
- **Low**: Documentation issues, nice-to-have improvements

### **Platform Priorities**
1. **macOS**: Primary development platform, full features
2. **iOS**: Production target, high priority
3. **Android**: Important but transcription pending
4. **Web**: Future consideration

## 🔒 Security Guidelines

### **Sensitive Data**
- Never commit API keys, tokens, or credentials
- Use environment variables for configuration
- Keep model files in `.gitignore`
- Follow secure coding practices

### **Dependencies**
- Keep dependencies updated
- Review security advisories
- Use official packages when possible
- Audit native code changes carefully

## 📞 Getting Help

### **For Contributors**
- 💬 **Questions**: open an [issue](https://github.com/esrakadah/flutter_voice_bridge/issues)
- 📧 **Direct Contact**: Create an issue for private questions
- 🎓 **Learning**: Start at the [documentation hub](docs/README.md)

### **For Maintainers**
- 🔧 **Development Setup**: [setup guide](docs/guides/setup.md)
- 🏗️ **Architecture**: [architecture guide](docs/guides/architecture.md)
- 📊 **Status**: [feature status](docs/guides/feature_status.md)

## 🎉 Recognition

Contributors will be:
- Listed in our README acknowledgments
- Mentioned in release notes
- Given GitHub repository permissions (for regular contributors)
- Invited to be maintainers (for significant contributors)

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping make Flutter Voice Bridge better for everyone!** 🚀 