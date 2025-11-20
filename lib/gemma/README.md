# Gemma AI Integration

This module integrates Google's Gemma AI models for on-device inference in the Flutter Voice Bridge app.

## 🌟 Features

- **On-Device AI**: All inference happens locally, no internet required after model download
- **Multiple Models**: Choose from different Gemma models based on your needs:
  - Gemma 3 270M: Ultra-compact (300MB)
  - Gemma 3 1B: Recommended balance (500MB)
  - Gemma 3N E2B: Multimodal with image support (3.1GB)
- **Multimodal Chat**: Support for both text and image inputs (model dependent)
- **Privacy-Focused**: Your conversations never leave your device
- **iOS Only**: Currently only available on iOS platform

## 📁 Structure

```
lib/gemma/
├── data/
│   └── gemma_downloader_datasource.dart  # Handles model downloads
├── domain/
│   ├── available_models.dart             # Model definitions
│   └── download_model.dart               # Download model
└── ui/
    ├── gemma_chat_screen.dart            # Main chat interface
    └── gemma_settings_screen.dart        # Model management
```

## 🚀 Setup

### 1. Get Hugging Face Access Token

1. Visit [Hugging Face Settings](https://huggingface.co/settings/tokens)
2. Create a new access token with read permissions
3. Copy your token

### 2. Configure Token

Open `lib/gemma/data/gemma_downloader_datasource.dart` and replace:

```dart
const String accessToken = 'YOUR_HUGGING_FACE_TOKEN_HERE';
```

with your actual token:

```dart
const String accessToken = 'hf_YourActualTokenHere';
```

### 3. Platform Requirements

**iOS**: Requires iOS 16.0 or later ⚠️
- **Minimum deployment target: iOS 16.0** (already configured in Podfile)
- The integration automatically checks platform and only shows on iOS
- Models are optimized for Apple's Neural Engine
- Supports iPhone 8 and newer with iOS 16+

**Not Supported**: 
- Android (requires different model format)
- macOS (not covered by flutter_gemma)
- Web, Windows, Linux
- iOS versions below 16.0

## 📱 Usage

### Accessing Gemma Chat

1. Run the app on an iOS device or simulator
2. On the home screen, scroll down to find the "Chat with Gemma AI" card
3. Tap to open the chat interface

### First Time Setup

On first launch:
1. The app will download the default model (Gemma 1B - 500MB)
2. Wait for download to complete
3. Once initialized, you can start chatting

### Changing Models

1. In the chat screen, tap the settings icon (⚙️)
2. Browse available models
3. Download a new model if needed
4. Select "Use This" to switch models
5. Return to chat - the app will reload with the new model

### Multimodal Features

For models with image support (Gemma 3N E2B):
1. Tap the image icon (📷) in the chat input
2. Select an image from your gallery
3. Add optional text prompt
4. Send to get AI analysis of the image

## 🔧 Technical Details

### Model Download
- Models are downloaded from Hugging Face
- Stored in app's document directory
- Resumable downloads (supports partial downloads)
- Old models auto-deleted to save space

### Inference
- Uses `flutter_gemma` package v0.9.0
- Runs on device using TFLite
- Streaming responses for better UX
- Configurable max tokens (2048)

### Storage Requirements
- Gemma 270M: ~300MB
- Gemma 1B: ~500MB  ⭐ Recommended
- Gemma 3N E2B: ~3.1GB (with image support)

## 🎨 UI Components

### Chat Screen (`gemma_chat_screen.dart`)
- Message list with markdown rendering
- Image preview for multimodal inputs
- Loading states and progress indicators
- Error handling with user-friendly messages

### Settings Screen (`gemma_settings_screen.dart`)
- Model selection interface
- Download progress tracking
- Model deletion for space management
- Visual indicators for selected model

## 🔐 Privacy & Security

- **No Network After Download**: Models run 100% offline
- **Data Never Leaves Device**: All conversations are local
- **No Telemetry**: No usage data collected
- **Secure Storage**: Models stored in app sandbox

## 🐛 Troubleshooting

### Pod Install Error: "requires a higher minimum iOS deployment version"
- **Solution**: The Podfile is already configured for iOS 16.0
- If you still see this error:
  1. Clean: `cd ios && rm -rf Pods Podfile.lock`
  2. Reinstall: `pod install`
  3. Verify Podfile has `platform :ios, '16.0'`

### Model Download Fails
- Check internet connection
- Verify Hugging Face token is valid
- Ensure sufficient storage space
- Check token has read permissions

### Model Not Loading
- Restart the app
- Delete and re-download the model
- Check iOS version (requires 14.0+)
- Verify model file isn't corrupted

### Out of Memory
- Use smaller model (Gemma 1B instead of 3N E2B)
- Close other apps
- Restart device if persistent

### Image Upload Not Working
- Verify you're using a multimodal model
- Check camera/photos permissions
- Try smaller images (<1024x1024)

## 📚 Resources

- [flutter_gemma Package](https://pub.dev/packages/flutter_gemma)
- [Gemma Models on Hugging Face](https://huggingface.co/models?search=gemma)
- [Medium Article - Using Gemma for Flutter](https://medium.com/@vogelcsongorbenedek/using-gemma-for-flutter-apps-91f746e3347c)
- [Google Gemma Documentation](https://ai.google.dev/gemma)

## 🎯 Future Enhancements

Potential improvements:
- [ ] Android support (requires different model format)
- [ ] Voice input integration with existing transcription
- [ ] Context awareness using voice memo transcriptions
- [ ] Model quantization options
- [ ] Custom system prompts
- [ ] Conversation history persistence
- [ ] Export chat conversations

## 📄 License

This integration follows the same license as the main Flutter Voice Bridge project.
Gemma models are subject to their own license terms from Google.

