// dialogue_model.dart

enum MessageSender { user, maldong }

class DialogueMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  DialogueMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}