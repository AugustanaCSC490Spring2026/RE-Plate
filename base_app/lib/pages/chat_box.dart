import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/services/chat_service.dart';

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}

class ChatBox extends StatefulWidget {
  const ChatBox({super.key});

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final _chatService = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isLoading = false;

  static const List<String> _suggestions = [
    'What is a substitute for milk? 🥛',
    'Is lamb meat halal? 🥩',
    'What are high-protein breakfast ideas? 🍳',
    'Is olive oil healthier than butter? 🫒',
    'How do I make a recipe gluten-free? 🌾',
    'What foods are high in iron?',
  ];

  Future<void> _sendSuggestion(String suggestion) async {
    // Strip the emoji before sending to the AI
    final clean = suggestion.replaceAll(RegExp(r'\s?\p{So}+$', unicode: true), '').trim();
    _controller.text = clean;
    await _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await _chatService.sendMessage(text);
      setState(() {
        _messages.add(_Message(text: reply, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message(
          text: 'Something went wrong. Please try again.',
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'FoodieAI',
            style: GoogleFonts.raleway(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(),

          // Message list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu,
                            size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me about nutrition,\nsubstitutions, or any recipe!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                              color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Try asking:',
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _suggestions.map((s) {
                            return GestureDetector(
                              onTap: () => _sendSuggestion(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: GoogleFonts.raleway(
                                    fontSize: 12.5,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _ChatBubble(
                          message: msg.text, isUser: msg.isUser);
                    },
                  ),
          ),

          // Typing indicator
          if (_isLoading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Thinking...',
                      style: GoogleFonts.raleway(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          const Divider(height: 1),

          // Input row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.raleway(fontSize: 14),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask about nutrition or substitutions…',
                      hintStyle: GoogleFonts.raleway(
                          fontSize: 13, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(
          message,
          style: GoogleFonts.raleway(
            fontSize: 13.5,
            color: isUser ? Colors.white : Colors.black87,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}