import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class AiChatPage extends StatefulWidget {
  final String? conversationId;

  const AiChatPage({super.key, this.conversationId});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _currentConversationId;
  bool _isLoadingHistory = true;

  // Groq API Key
  final String? groqApiKey = dotenv.env['GROQ_API_KEY'];

  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    setState(() {
      _isLoadingHistory = true;
    });

    if (widget.conversationId != null && uid != null) {
      _currentConversationId = widget.conversationId;

      // Load messages from Firebase
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ai_chats')
          .doc(_currentConversationId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final messages = data['messages'] as List<dynamic>? ?? [];

        setState(() {
          _messages = [];
          for (var msg in messages) {
            _messages.add({'role': msg['role'], 'text': msg['text']});
          }
        });
      } else {
        _addWelcomeMessage();
      }
    } else {
      _addWelcomeMessage();
    }

    setState(() {
      _isLoadingHistory = false;
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _addWelcomeMessage() {
    _messages.add({
      'role': 'ai',
      'text':
          'Hello! I am Medhack AI, your advanced health and wellness assistant powered by Groq\'s ultra-fast AI. I analyze symptoms, explain medications, and provide actionable health insights.\n\nWhat are you experiencing today?\n\n⚠️ Disclaimer: I am an AI, not a doctor. Please seek professional medical help for emergencies.',
    });
  }

  Future<void> _autoSaveConversation() async {
    if (uid == null || _messages.isEmpty) return;

    // Generate title from first user message or first few messages
    String title = 'Chat Conversation';
    for (var msg in _messages) {
      if (msg['role'] == 'user') {
        title = msg['text']!.length > 50
            ? msg['text']!.substring(0, 50)
            : msg['text']!;
        break;
      }
    }

    // Generate preview from last user message
    String preview = 'No messages';
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i]['role'] == 'user') {
        preview = _messages[i]['text']!.length > 60
            ? _messages[i]['text']!.substring(0, 60)
            : _messages[i]['text']!;
        break;
      }
    }

    final Map<String, dynamic> conversationData = {
      'title': title,
      'preview': preview,
      'messageCount': _messages.length,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messages': _messages,
    };

    if (_currentConversationId == null) {
      // Create new conversation
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ai_chats')
          .add(conversationData);
      _currentConversationId = docRef.id;
    } else {
      // Update existing conversation
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ai_chats')
          .doc(_currentConversationId)
          .update(conversationData);
    }
  }

  Future<void> _saveDiagnosis(String userMessage, String aiResponse) async {
    if (uid == null) return;

    // Extract key symptom from user message
    String symptom = userMessage.length > 100
        ? userMessage.substring(0, 100)
        : userMessage;

    // Extract diagnosis from AI response (first few lines)
    String diagnosis = aiResponse.split('\n').first.length > 80
        ? aiResponse.split('\n').first.substring(0, 80)
        : aiResponse.split('\n').first;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diagnoses')
        .add({
          'symptom': symptom,
          'result': diagnosis,
          'fullResponse': aiResponse,
          'createdAt': FieldValue.serverTimestamp(),
          'conversationId': _currentConversationId,
        });
  }

  void _showHistoryDrawer() {
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chat History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('ai_chats')
                      .orderBy('lastMessageTime', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No chat history found.",
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var chat = doc.data() as Map<String, dynamic>;

                        // Format date
                        String dateStr = "Recently";
                        if (chat['lastMessageTime'] != null) {
                          DateTime date = (chat['lastMessageTime'] as Timestamp)
                              .toDate();
                          dateStr = "${date.day}/${date.month}/${date.year}";
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          color: doc.id == _currentConversationId
                              ? AppTheme.lightGreen
                              : AppTheme.pureWhite,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _loadExistingChat(doc.id);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: doc.id == _currentConversationId
                                          ? AppTheme.primaryGreen.withOpacity(
                                              0.2,
                                            )
                                          : AppTheme.lightGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      doc.id == _currentConversationId
                                          ? Icons.chat_bubble_rounded
                                          : Icons.chat_rounded,
                                      color: doc.id == _currentConversationId
                                          ? AppTheme.primaryGreen
                                          : AppTheme.textGrey,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chat['title'] ?? 'Chat Conversation',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                doc.id == _currentConversationId
                                                ? AppTheme.primaryGreen
                                                : AppTheme.textDark,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          chat['preview'] ?? 'No messages',
                                          style: const TextStyle(
                                            color: AppTheme.textGrey,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            color: AppTheme.textGrey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (chat['messageCount'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: doc.id == _currentConversationId
                                            ? AppTheme.primaryGreen.withOpacity(
                                                0.2,
                                              )
                                            : AppTheme.lightGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${chat['messageCount']}',
                                        style: TextStyle(
                                          color:
                                              doc.id == _currentConversationId
                                              ? AppTheme.primaryGreen
                                              : AppTheme.textGrey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadExistingChat(String conversationId) async {
    setState(() {
      _isLoadingHistory = true;
      _messages = [];
    });

    _currentConversationId = conversationId;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('ai_chats')
        .doc(_currentConversationId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final messages = data['messages'] as List<dynamic>? ?? [];

      setState(() {
        _messages = [];
        for (var msg in messages) {
          _messages.add({'role': msg['role'], 'text': msg['text']});
        }
      });
    }

    setState(() {
      _isLoadingHistory = false;
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medhack AI"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // History Button
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: _showHistoryDrawer,
            tooltip: 'Chat History',
          ),
          // New Chat Button
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () {
              setState(() {
                _currentConversationId = null;
                _messages = [];
                _addWelcomeMessage();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New chat started'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading indicator for history
          if (_isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),

          // Chat messages area
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message['text']!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Loading indicator for AI response
          if (_isLoading && !_isLoadingHistory)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: (_isLoading || _isLoadingHistory)
                        ? null
                        : _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                    iconSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || _isLoadingHistory) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _messageController.clear();

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Auto-save conversation before sending
    await _autoSaveConversation();

    // Groq models to try
    final List<String> modelsToTry = [
      "llama-3.3-70b-versatile",
      "llama-3.1-8b-instant",
      "mixtral-8x7b-32768",
      "gemma2-9b-it",
    ];

    bool success = false;
    String lastError = "";

    for (var model in modelsToTry) {
      if (success) break;

      try {
        print("🔄 Trying Groq model: $model");
        final result = await _callGroq(model, text);

        if (result != null && result.isNotEmpty) {
          print("✅ Success with model: $model");
          setState(() {
            _messages.add({'role': 'ai', 'text': result});
          });

          // Auto-scroll after receiving response
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          // Save diagnosis to Firebase
          await _saveDiagnosis(text, result);

          // Auto-save conversation after receiving response
          await _autoSaveConversation();

          success = true;
          break;
        }
      } catch (e) {
        lastError = e.toString();
        print("❌ Model $model failed: $e");
        continue;
      }
    }

    if (!success) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'text':
              '⚠️ Unable to connect to AI. Please check:\n\n'
              '1. Your internet connection\n'
              '2. Groq API key is valid\n'
              '3. You haven\'t exceeded rate limit (30 req/min)\n\n'
              'Error: $lastError',
        });
      });

      // Auto-scroll after error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Auto-save conversation with error message
      await _autoSaveConversation();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String?> _callGroq(String model, String userMessage) async {
    try {
      final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

      List<Map<String, String>> messages = [
        {
          "role": "system",
          "content":
              """You are Medhack AI, a professional medical assistant. Follow these rules STRICTLY:

1. Be empathetic and caring
2. Analyze symptoms systematically
3. Suggest possible causes (never diagnose)
4. Recommend safe home remedies
5. Clearly state when to see a doctor
6. Use bullet points for clarity
7. Ask relevant follow-up questions
8. ALWAYS include at the end: "⚠️ Remember: I'm an AI, not a doctor. Please consult a healthcare professional for medical advice."

Keep responses helpful, concise, and warm. Use markdown formatting for better readability.""",
        },
      ];

      // Add last 10 messages for context
      int startIndex = _messages.length > 10 ? _messages.length - 10 : 0;
      for (int i = startIndex; i < _messages.length; i++) {
        var msg = _messages[i];
        messages.add({
          "role": msg['role'] == 'user' ? 'user' : 'assistant',
          "content": msg['text']!,
        });
      }

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $groqApiKey",
            },
            body: jsonEncode({
              "model": model,
              "messages": messages,
              "temperature": 0.7,
              "max_tokens": 1000,
              "top_p": 0.9,
              "stream": false,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.isNotEmpty) {
          return content;
        }
      } else if (response.statusCode == 429) {
        print("Rate limited, trying next model");
        return null;
      }
      return null;
    } catch (e) {
      print("Groq error: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
