// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Import the services package for Clipboard

class AIChatScreen extends StatefulWidget {
  final String userId;

  const AIChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _chatHistory = []; // Stores chat messages
  bool _isTyping = false; // Indicates if Lemo is typing
  String _selectedMessage = ""; // Track the selected message

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(); // Scroll to bottom when screen opens
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose(); // Dispose of the scroll controller
    super.dispose();
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent +
            50, // Small offset for safety
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'message': message, 'type': 'text'});
    });

    // Scroll only after the message is added to the chat list
    _scrollToBottom();

    setState(() {
      _isTyping = true; // Show "Lemo is Typing" indicator
    });

    try {
      Map<String, String> aiResponse = await _generateAIResponse(message);

      setState(() {
        _chatHistory.add(aiResponse);
      });
      _scrollToBottom(); // Scroll again after AI response

      // Save chat to Firestore
      await _saveChatToDatabase(message, aiResponse['message'] ?? '');
    } catch (e) {
      print("Error generating AI response: $e");
    } finally {
      setState(() {
        _isTyping = false; // Hide "Lemo is Typing" indicator
      });
    }

    _messageController.clear();
  }

  Future<Map<String, String>> _generateAIResponse(String userInput) async {
    const apiKey =
        'AIzaSyD351H5QhlzASi9ltgNK0t3ZioItg1STDE'; // Replace with your actual API key
    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": userInput}
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Gemini API Response: $data");

          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            final rawTextResponse =
                data['candidates'][0]['content']['parts'][0]['text'];
            final cleanTextResponse = _cleanResponseText(rawTextResponse);

            print("AI Response: $cleanTextResponse");

            return {'role': 'ai', 'message': cleanTextResponse, 'type': 'text'};
          } else {
            throw Exception("No candidates found in the response.");
          }
        } else if (response.statusCode == 429) {
          if (retryCount < maxRetries - 1) {
            retryCount++;
            print('Quota exceeded, retrying in ${retryCount * 2} seconds...');
            await Future.delayed(Duration(seconds: retryCount * 2));
          } else {
            throw Exception("Quota exceeded. Please try again later.");
          }
        } else {
          throw Exception(
              "Failed to get response from Gemini API: ${response.body}");
        }
      } catch (e) {
        print("Error: $e");
        throw e;
      }
    }

    throw Exception("Failed to generate response after retries.");
  }

  String _cleanResponseText(String responseText) {
    return responseText.replaceAll(RegExp(r'\*'), '').trim();
  }

  Future<void> _saveChatToDatabase(
      String userMessage, String aiResponse) async {
    try {
      final chatCollection = FirebaseFirestore.instance.collection('aichat');

      // Print message to verify what is being saved
      print(
          "Saving to Firestore: userMessage: $userMessage, aiResponse: $aiResponse");

      await chatCollection.add({
        'userId': widget.userId,
        'userMessage': userMessage,
        'aiResponse': aiResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Chat saved successfully!");
    } catch (e) {
      print("Error saving chat to Firestore: $e"); // Catch and print error
    }
  }

  void _copyToClipboard(String message) {
    Clipboard.setData(ClipboardData(text: message)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Copied to clipboard")),
      );
    });
  }

  void _showCopyOption(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Copy Message',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Do you want to copy this message?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _copyToClipboard(message);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Copy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Cancel'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              child: Lottie.asset(
                'assets/lemo.json',
                width: 120,
                height: 120,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "Lemo",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(106, 33, 149, 243),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5, // Adjust opacity as needed
              child: Lottie.asset(
                'assets/lemo.json',
              ),
            ),
          ),
          // Main content of the screen
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    final chat = _chatHistory[index];
                    bool isUser = chat['role'] == 'user';

                    return GestureDetector(
                      onLongPress: () {
                        _showCopyOption(context, chat['message'] ?? '');
                      },
                      child: Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(
                            isUser ? 50.0 : 0.0,
                            5.0,
                            isUser ? 0.0 : 50.0,
                            5.0,
                          ),
                          padding: const EdgeInsets.all(10.0),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color.fromARGB(87, 18, 101, 255)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isUser)
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      child: Lottie.asset(
                                        'assets/lemo.json',
                                        width: 120,
                                        height: 120,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text("Lemo",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              SizedBox(height: 5),
                              Text(chat['message'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Text(
                        "Lemo",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        "is typing...",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ), // Show loading indicator
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          minLines: 1,
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: CircleAvatar(
                                radius: 20,
                                child: Lottie.asset(
                                  'assets/lemo.json',
                                  width: 120,
                                  height: 120,
                                ),
                              ),
                            ),
                            hintText: "Ask Lemo ...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          onSubmitted: (value) {
                            _sendMessage(value);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: IconButton(
                        icon: Lottie.asset('assets/send.json',
                            height: 70, width: 70),
                        onPressed: () {
                          _sendMessage(_messageController.text.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
