import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/chat_message_model.dart';
import 'package:atma_farm_app/services/ai_advisor_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Add the initial greeting from the AI
    _messages.add(ChatMessage(
      text: "Namaste! I am your AI farming assistant. How can I help you with your oil palm cultivation today?",
      author: ChatAuthor.model,
    ));
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final messageText = _textController.text.trim();
    _textController.clear();

    // Add user message to UI
    setState(() {
      _messages.add(ChatMessage(text: messageText, author: ChatAuthor.user));
      _isLoading = true;
    });
    _scrollToBottom();

    // Create history for the API call
    final history = _messages.map((m) {
      return {
        'author': m.author == ChatAuthor.user ? 'user' : 'model',
        'text': m.text
      };
    }).toList();
    // Remove the last message (the one we just added) from the history
    history.removeLast();

    // Send to Gemini and get response
    final response = await _advisorService.sendMessage(messageText, history);

    // Add model response to UI
    setState(() {
      _messages.add(ChatMessage(text: response, author: ChatAuthor.model));
      _isLoading = false;
    });
    _scrollToBottom();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advisor'),
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
                decoration: const InputDecoration(
                  hintText: 'Ask about farming...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
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
