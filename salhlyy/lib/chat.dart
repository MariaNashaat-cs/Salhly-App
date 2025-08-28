import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:path_provider/path_provider.dart'; // For accessing device paths
import 'package:permission_handler/permission_handler.dart'; // For handling permissions
import 'package:record/record.dart'; // For audio recording
import 'dart:io'; // For file handling

// Your custom OrderDetails screen

void main() {
  runApp(const ChatApp(phoneNumber: ''));
}

class ChatApp extends StatefulWidget {
  final String phoneNumber;
  const ChatApp({super.key, required this.phoneNumber});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEE),
      body: SafeArea(
        child: Column(
          children: [
            HeaderComponent(
              onBack: () {
              //  Navigate to the OrderDetails screen
              //    Navigator.of(context).push(
              //      MaterialPageRoute(
              //      builder: (context) => OrderDetailsLayout(
              //          username: "Harry Style",
              //         paymentMethod: 'cash',
              //        phoneNumber: widget.phoneNumber,
              //       ),
              //     ),
              //    ); 
              },
            ),
            Expanded(
              child: MessageListComponent(scrollController: _scrollController),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderComponent extends StatelessWidget {
  final String userName;
  final String userImage;
  final VoidCallback onBack;

  const HeaderComponent({
    super.key,
    this.userName = 'Hassanen Ahmed',
    this.userImage =
        'https://dashboard.codeparrot.ai/api/image/Z7dfaq8BBwoP-o0r/repairma.png',
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // ignore: deprecated_member_use
          colors: [const Color(0xFF0C5FB3).withOpacity(0.9), const Color(0xFF0C5FB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Material(
            borderRadius: BorderRadius.circular(50),
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onBack,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User image
          ClipOval(
            child: Image.network(
              userImage,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.grey),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Online status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageListComponent extends StatefulWidget {
  final ScrollController scrollController;

  const MessageListComponent({
    super.key,
    required this.scrollController,
  });

  @override
  State<MessageListComponent> createState() => _MessageListComponentState();
}

class Message {
  final String text;
  final String time;
  final bool isSent;
  final MessageType type;
  final String? mediaPath;

  const Message({
    required this.text,
    required this.time,
    required this.isSent,
    this.type = MessageType.text,
    this.mediaPath,
  });
}

enum MessageType {
  text,
  image,
  audio,
}

class _MessageListComponentState extends State<MessageListComponent> {
  final List<Message> messages = [
    Message(
      text: "Hi there! I'm here to help you with your issue. 😊",
      time: _getCurrentTime(),
      isSent: false,
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  static String _getCurrentTime() {
    return DateFormat('h:mm a').format(DateTime.now());
  }

  void _sendMessage({String? text, String? mediaPath, MessageType type = MessageType.text}) {
    if ((text != null && text.isNotEmpty) || mediaPath != null) {
      setState(() {
        messages.add(Message(
          text: text ?? '',
          time: _getCurrentTime(),
          isSent: true,
          type: type,
          mediaPath: mediaPath,
        ));
        if (text == _controller.text) {
          _controller.clear();
        }
        _isTyping = false;
      });

      // Auto-reply after a short delay
      if (messages.length == 2) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              messages.add(Message(
                text: "I'll be right over to help with your issue. Is there anything specific I should know before arriving?",
                time: _getCurrentTime(),
                isSent: false,
              ));
            });
            _scrollToBottom();
          }
        });
      }

      // Scroll to bottom after sending a message
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: 320,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),
          // Typing indicator
          if (_isTyping)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  "Typing...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          InputComponent(
            controller: _controller,
            onSendText: () => _sendMessage(text: _controller.text),
            onSendMedia: (mediaPath, type) => _sendMessage(
              mediaPath: mediaPath,
              type: type,
              text: type == MessageType.image ? 'Image' : 'Voice Note',
            ),
            onTypingChanged: (isTyping) {
              setState(() {
                _isTyping = isTyping;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            message.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: message.isSent
                    ? [const Color(0xFF0C5FB3), const Color(0xFF1E88E5)]
                    : [const Color(0xFFD9D9D9), const Color(0xFFEEEEEE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildMessageContent(context),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 12,
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                if (message.isSent)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.check_circle,
                      size: 12,
                      // ignore: deprecated_member_use
                      color: Colors.green.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(message.mediaPath!),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
            if (message.text.isNotEmpty && message.text != 'Image')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: message.isSent ? Colors.white : const Color(0xFF0C5FB3),
                  ),
                ),
              ),
          ],
        );
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: message.isSent ? Colors.white : const Color(0xFF0C5FB3),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: message.isSent ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  child: LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '0:00',
              style: TextStyle(
                fontSize: 12,
                color: message.isSent ? Colors.white : const Color(0xFF0C5FB3),
              ),
            ),
          ],
        );
      case MessageType.text:
      return Text(
          message.text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: message.isSent ? Colors.white : const Color(0xFF0C5FB3),
          ),
        );
    }
  }
}

class InputComponent extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendText;
  final Function(String, MessageType) onSendMedia;
  final Function(bool) onTypingChanged;

  const InputComponent({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onSendMedia,
    required this.onTypingChanged,
  });

  @override
  State<InputComponent> createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  bool _isComposing = false;
  bool _isRecording = false;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final bool isNowComposing = widget.controller.text.isNotEmpty;
    if (isNowComposing != _isComposing) {
      setState(() {
        _isComposing = isNowComposing;
      });
      widget.onTypingChanged(isNowComposing);
    }
  }

  Future<void> _pickImage() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          widget.onSendMedia(image.path, MessageType.image);
        }
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to select images')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (!_isRecording) {
        final status = await Permission.microphone.request();
        if (status.isGranted) {
          final tempDir = await getTemporaryDirectory();
          _currentRecordingPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          
          // Ensure _currentRecordingPath is not null before passing it to start
          if (_currentRecordingPath != null) {
            await _audioRecorder.start(const RecordConfig(), path: _currentRecordingPath!);
            setState(() {
              _isRecording = true;
            });
          }
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to record audio')),
          );
        }
      } else {
        final path = _currentRecordingPath;
        final result = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
        });
        if (result != null && path != null) {
          widget.onSendMedia(path, MessageType.audio);
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record audio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Color(0xFF0C5FB3)),
            onPressed: _pickImage,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(_isRecording ? 8 : 0),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.white : const Color(0xFF0C5FB3),
              ),
            ),
            onPressed: _toggleRecording,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: widget.controller,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (_isComposing) {
                    widget.onSendText();
                  }
                },
                enabled: !_isRecording,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isComposing
                  ? const Color(0xFF0C5FB3)
                  // ignore: deprecated_member_use
                  : const Color(0xFF0C5FB3).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isComposing ? widget.onSendText : null,
            ),
          ),
        ],
      ),
    );
  }
}