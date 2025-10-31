import 'dart:async';

import 'package:dhadkan/features/chat/chat_text_box.dart';
import 'package:dhadkan/features/chat/text_message.dart';
import 'package:dhadkan/features/common/top_bar.dart';

import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../auth/landing_screen.dart'; // Assuming landing_screen.dart is in this path

class ConversationScreen extends StatefulWidget {
  final String receiver_id;

  const ConversationScreen({super.key, required this.receiver_id});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  String _token = "";
  List<dynamic> _chats = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initialize();
    // Poll for new messages every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_token.isNotEmpty) { // Only reload if token is available
        _reloadChat();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  _initialize() async {
    String? token = await SecureStorageService.getData('authToken');
    if (token == null || token.isEmpty) {
      // If token is not found, navigate to LandingScreen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()), // Ensure LandingScreen is imported
            (route) => false,
      );
    } else {
      setState(() {
        _token = token;
      });
      // Initial load of chat messages
      _reloadChat();
    }
  }

  _reloadChat() async {
    // Ensure token is available before making the API call
    if (_token.isEmpty) return;

    try {
      Map<String, dynamic> response = await MyHttpHelper.private_post(
          '/chat/get-texts', {'receiver_id': widget.receiver_id}, _token);
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _chats = response['data'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Error in loading Texts")));
      }
    }
  }

  String _formatMessageTime(String timeString) {
    try {
      DateTime messageTime = DateTime.parse(timeString);
      // Show only time (no date)
      return DateFormat('HH:mm').format(messageTime);
    } catch (e) {
      return '';
    }
  }

  String _getDateHeader(DateTime messageDate) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);

    if (messageDay == today) {
      return "TODAY";
    } else if (messageDay == yesterday) {
      return "YESTERDAY";
    } else if (messageDay.isAfter(today.subtract(const Duration(days: 7)))) {
      // Within last 7 days, show day name
      return DateFormat('EEEE').format(messageDate).toUpperCase();
    } else {
      // Older than 7 days, show date
      return DateFormat('dd/MM/yyyy').format(messageDate);
    }
  }

  List<Widget> _buildMessageWidgets() {
    List<Widget> widgets = [];
    String? lastDateHeader;

    for (int i = 0; i < _chats.length; i++) {
      var item = _chats[i];

      if (item['message_type'] == 'text') {
        try {
          DateTime messageTime = DateTime.parse(item['time'] ?? '');
          String currentDateHeader = _getDateHeader(messageTime);

          // Add date header if it's different from the last one
          if (lastDateHeader != currentDateHeader) {
            widgets.add(
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF128C7E).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      currentDateHeader,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
            lastDateHeader = currentDateHeader;
          }

          // Add the message
          widgets.add(
            TextMessage(
              text: item['text']!,
              mine: item['mine'], // 'mine' flag distinguishes sender
              time: _formatMessageTime(item['time'] ?? ''),
            ),
          );
        } catch (e) {
          // If date parsing fails, just add the message without date header
          widgets.add(
            TextMessage(
              text: item['text']!,
              mine: item['mine'],
              time: _formatMessageTime(item['time'] ?? ''),
            ),
          );
        }
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MyDeviceUtils.getScreenWidth(context);
    double paddingWidth = screenWidth * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: const TopBar(title: "Chat Screen"), // Title can be customized further if needed
      ),
      body: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
                  reverse: true, // To keep the view at the bottom for new messages
                  padding: EdgeInsets.symmetric(horizontal: paddingWidth),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 10),
                        ..._buildMessageWidgets(),
                      ]))),
          // Display ChatTextBox only if token is available
          if (_token.isNotEmpty)
            ChatTextBox(receiver_id: widget.receiver_id, token: _token)
        ],
      ),
    );
  }
}