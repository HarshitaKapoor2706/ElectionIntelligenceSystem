// chat_models.dart
//
// Simple chat message model + a placeholder reply function.
// Replace `mockAskElectionAI` with a real call to your FastAPI `/chat`
// endpoint (which forwards to Gemini per your architecture doc).

class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.fromUser,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

/// TODO: replace with:
///   final res = await http.post(
///     Uri.parse('$backendBaseUrl/chat'),
///     headers: {'Content-Type': 'application/json'},
///     body: jsonEncode({'question': question}),
///   );
///   return jsonDecode(res.body)['answer'];
Future<String> mockAskElectionAI(String question) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return "I don't have a live backend connected yet, so this is a "
      "placeholder answer. Once /chat is wired up, this will forward "
      "\"$question\" to Gemini along with the latest news context and "
      "return a real answer.";
}