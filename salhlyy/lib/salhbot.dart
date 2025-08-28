import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'video.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isDarkMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _checkDarkMode();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getStringList('chat_history') ?? [];

    if (savedMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(
          savedMessages.map((msg) {
            final parts = msg.split('|||');
            return ChatMessage(
              text: parts[0],
              isUser: parts[1] == 'true',
              timestamp: DateTime.parse(parts[2]),
            );
          }),
        );
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = _messages
        .map(
          (msg) =>
              '${msg.text}|||${msg.isUser}|||${msg.timestamp.toIso8601String()}',
        )
        .toList();
    await prefs.setStringList('chat_history', savedMessages);
  }

  Future<void> _checkDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  void _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('dark_mode', _isDarkMode);
    });
  }

  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
    });

    const String apiKey = 'AIzaSyAR7yNe75gxGZnNb7_uoGhk9ObYxUI8kEY';
    const String modelName = 'gemini-1.5-flash';

    final String prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: prompt, isUser: true, timestamp: DateTime.now()),
      );
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final systemPrompt = Content.text(
        "You are SALحBOT 🤖, a helpful assistant for plumbing and electrical issues. "
        "If the user asks how to fix something, and a video tutorial is available, tell them: "
        "'You can also check the SALح Tutorials section 📹 for step-by-step help.' "
        "If they ask to see tutorials, simply reply with: 'Opening tutorials page now...'.",
      );

      final recentMessages = [
        systemPrompt,
        ..._messages
            .takeLast(6)
            .map(
              (msg) =>
                  Content.text(msg.isUser ? "User: ${msg.text}" : msg.text),
            ),
      ];

      // Add emoji-friendly prompt hint
      recentMessages.add(
        Content.text(
          "User: $prompt\n\nPlease give a short and specific answer. Avoid unnecessary explanation. Use a friendly tone with emojis when helpful 😊.",
        ),
      );

      final response = await model.generateContent(recentMessages);

      final fullText = response.text ?? "No response received";
      String animatedText = "";

      // Add empty bot message first
      setState(() {
        _messages.add(
          ChatMessage(text: "", isUser: false, timestamp: DateTime.now()),
        );
      });

      // Animate character by character
      for (int i = 0; i < fullText.length; i++) {
        await Future.delayed(
          const Duration(milliseconds: 5),
        ); // Adjust speed if needed
        animatedText += fullText[i];

        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            text: animatedText,
            isUser: false,
            timestamp: DateTime.now(),
          );
        });
      }
      // Check if Gemini wants to open the tutorials page
      if (fullText.toLowerCase().contains('opening tutorials page')) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VideoScreen(username: '',)),
          );
        });
      }

      // Mark loading as finished
      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();
      _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Error: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
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

  Widget _buildCommandButtons() {
    final List<String> commands = [
      "🧼 How to clean or change a filter?",
      "💡 How to replace a lamp?",
      "🔔 How to fix a doorbell?",
      "🧊 Fridge troubleshooting tips",
      "🚰 How to fix a water tap?",
      "🔥 How to use a water heater safely",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: commands.map((cmd) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                _controller.text = cmd;
                _sendRequest();
              },
              child: Text(
                cmd,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _saveChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size to ensure responsive design
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkMode
            ? const Color(0xFF1A1A1A)
            : Colors.blue[700],
        elevation: 2,
        titleSpacing: 12,
        title: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'SALحBOT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your home repair assistant',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Dark Mode',
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: _toggleDarkMode,
          ),
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _clearChat,
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          color: _isDarkMode
              ? const Color(0xFF121212)
              : const Color(0xFFF5F7FA),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: _isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.04,
                          vertical: screenSize.height * 0.01,
                        ),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),

                        itemBuilder: (context, index) {
                          if (_isLoading && index == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'SALحBOT is typing...',
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final message = _messages[index];
                          // Group messages by date
                          final bool showDate =
                              index == 0 ||
                              !_isSameDay(
                                _messages[index - 1].timestamp,
                                message.timestamp,
                              );

                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isDarkMode
                                            ? Colors.grey[850]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _formatDate(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ChatBubble(
                                message: message,
                                isDarkMode: _isDarkMode,
                              ),
                            ],
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildCommandButtons(),
              ),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.04,
                  vertical: screenSize.height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Message SALحBOT...',
                            hintStyle: TextStyle(
                              color: _isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenSize.width * 0.04,
                              vertical: screenSize.height * 0.015,
                            ),
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: _isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _controller.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: _controller.text.isEmpty
                            ? (_isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[300])
                            : (_isDarkMode
                                  ? Colors.blue[700]
                                  : Colors.blue[600]),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _controller.text.isEmpty
                            ? null
                            : _sendRequest,
                        icon: Icon(
                          Icons.send_rounded,
                          color: _controller.text.isEmpty
                              ? (_isDarkMode
                                    ? Colors.grey[600]
                                    : Colors.grey[500])
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDarkMode;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: message.isUser
                ? (isDarkMode ? Colors.blue[700] : Colors.blue[600])
                : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white),
            borderRadius: BorderRadius.circular(18.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: message.isUser
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                    fontSize: 16.0,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: message.isUser
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                  code: TextStyle(
                    fontFamily: 'monospace',
                    backgroundColor: isDarkMode
                        ? Colors.grey[850]
                        : Colors.grey[200],
                    color: isDarkMode ? Colors.grey[300] : Colors.black87,
                  ),
                  codeblockPadding: const EdgeInsets.all(8.0),
                  codeblockDecoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  blockquote: TextStyle(
                    color: message.isUser
                        ? Colors.white.withOpacity(0.9)
                        : (isDarkMode
                              ? Colors.white.withOpacity(0.9)
                              : Colors.black87.withOpacity(0.9)),
                    fontStyle: FontStyle.italic,
                  ),
                  h1: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: message.isUser
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                  h2: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: message.isUser
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                  h3: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: message.isUser
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: message.isUser
                        ? Colors.white.withOpacity(0.7)
                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension TakeLastExtension<E> on List<E> {
  List<E> takeLast(int n) => skip(length > n ? length - n : 0).toList();
}