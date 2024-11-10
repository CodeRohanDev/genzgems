// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Import the image picker
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lottie/lottie.dart'; // Import Firebase storage

class MessageInputWidget extends StatefulWidget {
  final Function(String) onSendMessage;

  MessageInputWidget({required this.onSendMessage});

  @override
  _MessageInputWidgetState createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isEmojiPickerVisible = false;
  bool isUploading = false; // Track upload status

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        isUploading = true; // Show uploading status
      });

      final file = File(pickedFile.path);
      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';

      try {
        final storageRef =
            FirebaseStorage.instance.ref('chat_images/$fileName');
        await storageRef.putFile(file);

        final downloadUrl = await storageRef.getDownloadURL();
        widget.onSendMessage(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
      } finally {
        setState(() {
          isUploading = false; // Hide uploading status after completion
        });
      }
    }
  }

  void _sendMessage() {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isUploading) // Show "Uploading..." indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Lottie.asset(
                  'assets/upload.json',
                  height: 100,
                  width: 100,
                ),
                SizedBox(width: 10),
                Text("Uploading..."),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    hintStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          width: 2.0), // Default width
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          width: 2.5), // Width when focused
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          width: 2.5), // Width when not focused
                    ),
                    prefixIcon: IconButton(
                      icon: Icon(
                        Icons.emoji_emotions,
                        color: Colors.black,
                      ),
                      onPressed: () => setState(
                          () => _isEmojiPickerVisible = !_isEmojiPickerVisible),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: Colors.black,
                      ),
                      onPressed: _pickImage,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 5,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
        if (_isEmojiPickerVisible)
          EmojiPicker(
            onEmojiSelected: (category, emoji) {
              _controller
                ..text += emoji.emoji
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
            },
            onBackspacePressed: () {
              _controller.text =
                  _controller.text.characters.skipLast(1).toString();
            },
            textEditingController: _controller,
            config: Config(
              height: 315,
              checkPlatformCompatibility: true,
            ),
          ),
      ],
    );
  }
}

class _MediaOptionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaOptionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black87),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                  letterSpacing: 1,
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
