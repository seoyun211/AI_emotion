import 'flutter_application\lib\models\dialogue_model.dart';Widget build(BuildContext context) {
  return Column(
    children: [
      // 1. 대화 목록 표시
      Expanded(
        child: ListView.builder(
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            return Align(
              alignment: message.sender == MessageSender.user 
                  ? Alignment.centerRight 
                  : Alignment.centerLeft,
              child: Card(
                color: message.sender == MessageSender.user ? Colors.blue[100] : Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(message.text),
                ),
              ),
            );
          },
        ),
      ),
      
      // 2. 채팅 버튼 (버튼 텍스트를 상태에 따라 변경)
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _handleChatButtonPress,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.red : Colors.green,
          ),
          child: Text(_isRecording ? '녹음 중 (눌러서 종료)' : '대화 시작'),
        ),
      ),
    ],
  );
}