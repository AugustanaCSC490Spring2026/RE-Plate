import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/services/chat_service.dart';

class ChatBox extends StatefulWidget {
  const ChatBox({super.key});

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text('Recipe Assistant',
              style: GoogleFonts.raleway(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const Divider(),
          Expanded(
            child: Center(
              child: Text('Coming soon!',
                  style: GoogleFonts.raleway(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}