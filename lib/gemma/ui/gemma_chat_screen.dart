import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/gemma_downloader_datasource.dart';
import '../domain/available_models.dart';
import 'gemma_settings_screen.dart';

/// Main chat screen for interacting with Gemma AI.
///
/// This screen provides a chat interface where users can:
/// - Send text messages to the AI
/// - Upload images for multimodal analysis (if supported by model)
/// - View AI responses with markdown formatting
/// - Access settings to change AI models
class GemmaChatScreen extends StatefulWidget {
  const GemmaChatScreen({super.key});

  @override
  State<GemmaChatScreen> createState() => _GemmaChatScreenState();
}

class _GemmaChatScreenState extends State<GemmaChatScreen> {
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;

  final List<Message> _messages = [];

  bool _isModelLoading = true;
  String _loadingMessage = 'Initializing...';
  double? _downloadProgress;
  bool _isAwaitingResponse = false;
  bool _modelSupportsImages = false;

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImage;

  final _textController = TextEditingController();

  late final GemmaDownloaderDataSource _downloaderDataSource;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Gets the selected model from SharedPreferences.
  Future<AvailableModel> _getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedFilename = prefs.getString('selected_gemma_model');

    if (selectedFilename != null) {
      return AvailableModel.values.firstWhere(
        (m) => m.filename == selectedFilename,
        orElse: () => AvailableModel.gemma1b,
      );
    }
    return AvailableModel.gemma1b; // Default to recommended model
  }

  /// Initializes the Gemma AI model.
  ///
  /// This method:
  /// 1. Checks which model is selected
  /// 2. Downloads it if not present
  /// 3. Initializes the inference engine
  /// 4. Creates a chat session
  Future<void> _initializeModel() async {
    try {
      final gemma = FlutterGemmaPlugin.instance;

      // Get selected model from settings
      final selectedModel = await _getSelectedModel();

      _downloaderDataSource = GemmaDownloaderDataSource(
        model: selectedModel.toDownloadModel(),
      );

      // Clean up old models to free up space
      await _downloaderDataSource.deleteOldModels();

      final isModelInstalled = await _downloaderDataSource.checkModelExistence();

      if (!isModelInstalled) {
        setState(() {
          _loadingMessage =
              'Downloading ${selectedModel.displayName} (${selectedModel.size})...';
        });

        await _downloaderDataSource.downloadModel(
          token: accessToken,
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress;
            });
          },
        );
      }

      setState(() {
        _loadingMessage = 'Initializing model...';
        _downloadProgress = null;
      });

      // Get the path to the downloaded model file
      final modelPath = await _downloaderDataSource.getFilePath();
      await gemma.modelManager.setModelPath(modelPath);

      // Use model's actual image support capability
      final supportsImages = selectedModel.supportsImages;

      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: supportsImages,
        maxTokens: 2048,
      );

      _chat = await _inferenceModel!.createChat(
        supportImage: supportsImages,
      );

      setState(() {
        _isModelLoading = false;
        _modelSupportsImages = supportsImages;
      });
    } catch (e) {
      debugPrint("Error initializing model: $e");
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to initialize AI model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isModelLoading = false;
      });
    }
  }

  /// Picks an image from the gallery for multimodal chat.
  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = bytes;
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Image selection error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Gemma'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GemmaSettingsScreen(),
                ),
              );
              // Reload model if settings changed
              setState(() {
                _isModelLoading = true;
                _messages.clear(); // Clear chat history
              });
              _initializeModel();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: _isModelLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      _loadingMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_downloadProgress != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 16.0,
                        ),
                        child: LinearProgressIndicator(value: _downloadProgress),
                      ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 16.0,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        return ChatMessageWidget(message: message);
                      },
                    ),
                  ),
                  if (_isAwaitingResponse)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Gemma is thinking...'),
                        ],
                      ),
                    ),
                  _buildChatInputArea(),
                ],
              ),
      ),
    );
  }

  /// Builds the chat input area with text field and action buttons.
  Widget _buildChatInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(13, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImage!,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() => _selectedImage = null);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: _modelSupportsImages ? _pickImage : null,
                    color: _modelSupportsImages
                        ? Colors.blue.shade700
                        : Colors.grey,
                    tooltip: _modelSupportsImages
                        ? 'Add image'
                        : 'Current model does not support images',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask Gemma anything...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    onPressed: _isAwaitingResponse ? null : _sendMessage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sends a message to Gemma AI and handles the response.
  void _sendMessage() async {
    final text = _textController.text.trim();
    final image = _selectedImage;

    if (text.isEmpty && image == null) {
      return;
    }

    // Check if trying to send image with text-only model
    if (image != null && !_modelSupportsImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current model does not support images. '
            'Please select a multimodal model in settings.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isAwaitingResponse) return;

    setState(() {
      _isAwaitingResponse = true;
    });

    // Create the user's message object
    final Message userMessage;
    if (image != null) {
      final prompt = text.isNotEmpty ? text : "What's in this image?";
      userMessage = Message.withImage(
        text: prompt,
        imageBytes: image,
        isUser: true,
      );
    } else {
      userMessage = Message(text: text, isUser: true);
    }

    // Add the user's message to the UI and clear input fields
    setState(() {
      _messages.add(userMessage);
      _selectedImage = null;
    });

    _textController.clear();
    FocusScope.of(context).unfocus();

    try {
      // Send the user's message to the Gemma chat instance
      await _chat!.addQueryChunk(userMessage);

      // Add an empty placeholder for the AI's response
      final responsePlaceholder = Message(text: '', isUser: false);
      setState(() {
        _messages.add(responsePlaceholder);
      });

      // Listen to the stream and aggregate the tokens
      final responseStream = _chat!.generateChatResponseAsync();

      await for (final token in responseStream) {
        if (!mounted) return;
        setState(() {
          final lastMessage = _messages.last;
          final updatedText = lastMessage.text + token;
          _messages[_messages.length - 1] = Message(
            text: updatedText,
            isUser: false,
          );
        });
      }
    } catch (e) {
      debugPrint("Error during chat generation: $e");
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error generating response: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Remove the empty AI message placeholder on error
        setState(() {
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.removeLast();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAwaitingResponse = false;
        });
      }
    }
  }
}

/// Widget for displaying individual chat messages.
class ChatMessageWidget extends StatelessWidget {
  final Message message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(16);
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? Colors.blue.shade600 : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: isUser ? radius : Radius.zero,
      bottomRight: isUser ? Radius.zero : radius,
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    message.imageBytes!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              MarkdownBody(
                data: message.text.replaceAll(r'\n', '\n'),
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  p: TextStyle(color: textColor, fontSize: 15),
                  code: TextStyle(
                    color: textColor,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                selectable: true,
              ),
          ],
        ),
      ),
    );
  }
}

