enum ChatAuthor { user, model }

class ChatMessage {
  final String text;
  final ChatAuthor author;

  ChatMessage({required this.text, required this.author});
}