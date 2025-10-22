import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/chat_message_model.dart';
import 'package:atma_farm_app/services/ai_advisor_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final AiAdvisorService _advisorService = AiAdvisorService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsEnabled = true; // Assume TTS is enabled initially

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    // Add the initial greeting
    final initialMessage = ChatMessage(
      text: "Namaste! I am your AI farming assistant. How can I help you with your oil palm cultivation today?",
      author: ChatAuthor.model,
    );
    _messages.add(initialMessage);
    // Speak the initial message
    _speak(initialMessage.text);
  }

  // Initialize Speech to Text
  Future<void> _initSpeech() async {
    try {
      var micStatus = await Permission.microphone.request();
      if(micStatus.isGranted){
        _speechEnabled = await _speechToText.initialize(
          onError: (error) => print('STT Error: $error'),
          onStatus: (status) => print('STT Status: $status')
        );
      } else {
         print("Microphone permission denied");
         _speechEnabled = false;
      }
    } catch(e) {
      print("Could not initialize SpeechToText: $e");
      _speechEnabled = false;
    }
    setState(() {});
  }

  // Initialize Text to Speech
  Future<void> _initTts() async {
     // Basic setup, you might want language settings etc.
    await _flutterTts.awaitSpeakCompletion(true);
    // Set language (optional, defaults often work)
    // Example: await _flutterTts.setLanguage("en-IN"); 
  }

  // Start listening for speech
  void _startListening() async {
    if (!_speechEnabled) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available or permission denied.')),
      );
      return;
    }
    if (_isListening) return; // Prevent starting multiple times
    
    setState(() => _isListening = true);
    _textController.clear(); // Clear text field when starting voice input

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30), // Max listening duration
      localeId: "en_IN", // Specify locale for better accuracy if needed
      cancelOnError: true,
      partialResults: true, // Show results as they come in
      listenMode: ListenMode.confirmation, // Good for single commands/queries
    );
  }

  // Called when speech recognition provides a result
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _textController.text = result.recognizedWords;
       // If final result, stop listening animation, but keep text
      if (result.finalResult) {
         _isListening = false;
      }
    });
  }

  // Stop listening for speech
  void _stopListening() async {
     if (!_isListening) return;
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  // Speak the given text using TTS
  Future<void> _speak(String text) async {
    if (_ttsEnabled) {
      await _flutterTts.speak(text);
    }
  }


  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;
    if(_isListening) _stopListening(); // Stop listening if user hits send manually

    final messageText = _textController.text.trim();
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: messageText, author: ChatAuthor.user));
      _isLoading = true;
    });
    _scrollToBottom();

    final history = _messages.map((m) => {'author': m.author == ChatAuthor.user ? 'user' : 'model', 'text': m.text}).toList();
    history.removeLast();

    final response = await _advisorService.sendMessage(messageText, history);

    final modelMessage = ChatMessage(text: response, author: ChatAuthor.model);
    setState(() {
      _messages.add(modelMessage);
      _isLoading = false;
    });
    _scrollToBottom();
    await _speak(response); // Speak the response
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speechToText.cancel(); // Clean up STT
    _flutterTts.stop(); // Clean up TTS
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advisor'),
        actions: [
          // Add a toggle button for TTS on/off
          IconButton(
            icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: _ttsEnabled ? 'Mute Advisor' : 'Unmute Advisor',
            onPressed: () {
              setState(() {
                _ttsEnabled = !_ttsEnabled;
                if(!_ttsEnabled) _flutterTts.stop(); // Stop speaking if muted
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatMessageWidget(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Atma-Palm is typing...'),
                ],
              ),
            ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening...' : 'Ask about farming...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
            // Microphone button
            IconButton(
              icon: FaIcon(_isListening ? FontAwesomeIcons.stop : FontAwesomeIcons.microphone),
              color: _isListening ? Colors.red : Theme.of(context).primaryColor,
              tooltip: _isListening ? 'Stop listening' : 'Start voice input',
              onPressed: _speechEnabled ? (_isListening ? _stopListening : _startListening) : null,
            ),
            // Send button
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessageWidget(ChatMessage message) {
    final isUser = message.author == ChatAuthor.user;
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isUser ? Colors.green.shade700 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: TextStyle(color: isUser ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}

