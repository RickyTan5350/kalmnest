import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/services/ai_chat_api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Model for chat messages
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final bool isTyping;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isError = false,
    this.isTyping = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['message_id']?.toString(),
      text: map['content'] ?? '',
      isUser: map['role'] == 'user',
      timestamp: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  ChatMessage copyWith({
    String? text,
    bool? isTyping,
    bool? isError,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      isError: isError ?? this.isError,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

/// AI Chat Page - Main Widget
class AiChatPage extends StatefulWidget {
  final UserDetails? currentUser;
  final String? authToken;

  const AiChatPage({
    super.key,
    this.currentUser,
    this.authToken,
  });

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  late AiChatApiService _apiService;
  bool _isSending = false;
  bool _isLoadingHistory = false;
  String? _currentSessionId;
  List<dynamic> _sessions = [];
  bool _isNewChat = false;

  @override
  bool get wantKeepAlive => true;

  final List<String> _suggestedQuestions = [
    "Give me Learning Suggestion for HTML",
    "Give me Learning Suggestion for CSS",
    "Give me Learning Suggestion for JavaScript",
    "Give me Learning Suggestion for PHP",
    "Give me Learning suggestion for Web development"
  ];

  @override
  void initState() {
    super.initState();
    _apiService = AiChatApiService(token: widget.authToken);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    try {
      final sessions = await _apiService.getSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        debugPrint('Error loading history: $e');
      }
    }
  }

  Future<void> _loadSessionMessages(String sessionId) async {
    setState(() {
      _isSending = true; // Use as blocker
      _messages.clear();
      _currentSessionId = sessionId;
      _isNewChat = false;
    });

    try {
      final messagesData = await _apiService.getSessionMessages(sessionId);
      if (mounted) {
        setState(() {
          for (var m in messagesData) {
            _messages.insert(0, ChatMessage.fromMap(m));
          }
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showSnackBar('Error loading messages: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentSessionId = null;
      _isNewChat = true;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final userMessage = ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.insert(0, userMessage);
      _textController.clear();
      _isSending = true;
    });

    _scrollToBottom();
    _focusNode.unfocus();

    final typingMessage = ChatMessage(text: '', isUser: false, isTyping: true);
    setState(() => _messages.insert(0, typingMessage));

    try {
      final responseData = await _apiService.sendMessage(
        text,
        sessionId: _currentSessionId,
      );

      final aiResponse = responseData['ai_response'] as String;
      final newSessionId = responseData['session_id'] as String?;

      if (mounted) {
        setState(() {
          _currentSessionId = newSessionId;
          _messages.removeWhere((msg) => msg.id == typingMessage.id);
          _messages.insert(0, ChatMessage(text: aiResponse, isUser: false));
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg.id == typingMessage.id);
          _messages.insert(0, ChatMessage(
            text: 'Error: $e',
            isUser: false,
            isError: true,
          ));
          _isSending = false;
        });
      }
    }
  }

  void _handleSuggestedQuestion(String question) {
    setState(() {
      _isNewChat = true;
      _textController.text = question;
    });
    _handleSendMessage();
  }

  Future<void> _clearChat() async {
    if (_currentSessionId == null) {
       setState(() => _messages.clear());
       return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete this chat session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteSession(_currentSessionId!);
        if (mounted) {
          setState(() {
            _messages.clear();
            _currentSessionId = null;
          });
          _loadHistory();
        }
      } catch (e) {
        _showSnackBar('Delete failed: $e', Colors.red);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2.0,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: (_currentSessionId == null && _messages.isEmpty && !_isNewChat)
                ? _buildLandingView(colorScheme)
                : _buildChatView(colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildLandingView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "KalmNest AI (Gemini-2.0-flash)",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadHistory,
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Icon(Icons.auto_awesome, size: 64, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                "How can I help you today?",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startNewChat,
                icon: const Icon(Icons.add),
                label: const Text("Ask Question"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              _buildSuggestedQuestions(colorScheme),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Text(
          "Recent Questions",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _sessions.isEmpty
                  ? const Center(child: Text("No previous questions found."))
                  : ListView.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            session['title'] ?? 'Untitled Question',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            session['updated_at']?.split('T')[0] ?? '',
                            style: const TextStyle(fontSize: 10),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => _loadSessionMessages(session['chatbot_session_id']),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildChatView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() {
                    _messages.clear();
                    _currentSessionId = null;
                    _isNewChat = false;
                    _loadHistory();
                  }),
                  tooltip: 'Back to History',
                ),
                Text(
                  "KalmNest AI",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: colorScheme.onSurface),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _currentSessionId != null 
                    ? () => _loadSessionMessages(_currentSessionId!) 
                    : null,
                  tooltip: 'Refresh Question',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _messages.isNotEmpty ? _clearChat : null,
                  tooltip: 'Delete Chat',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- CHAT CONTENT ---
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _messages.length,
            itemBuilder: (context, index) =>
                _MessageBubble(message: _messages[index]),
          ),
        ),
        if (_isNewChat && _messages.isEmpty) _buildInputArea(colorScheme),
      ],
    );
  }

  Widget _buildSuggestedQuestions(ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          "Quick Learning Suggestions",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _suggestedQuestions.map((question) {
            IconData icon;
            Color iconColor;
            
            if (question.contains('HTML')) {
              icon = Icons.html;
              iconColor = Colors.orange;
            } else if (question.contains('CSS')) {
              icon = Icons.css;
              iconColor = Colors.blue;
            } else if (question.contains('JavaScript')) {
              icon = Icons.javascript;
              iconColor = Colors.amber;
            } else if (question.contains('PHP')) {
              icon = Icons.php; 
              iconColor = Colors.indigo;
            } else {
              icon = Icons.web;
              iconColor = colorScheme.primary;
            }

            final label = question
                .replaceFirst("Give me Learning Suggestion for ", "")
                .replaceFirst("Give me Learning suggestion for ", "");

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () => _handleSuggestedQuestion(question),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20, color: iconColor),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type your question...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            GestureDetector(
              onTap: _isSending ? null : _handleSendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSending ? colorScheme.outline : colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: _isSending ? [] : [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isSending ? Icons.hourglass_empty : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (message.isTyping) {
      return _buildTypingIndicator(colorScheme);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(colorScheme, isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary.withBlue(200)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isUser
                    ? null
                    : message.isError
                        ? colorScheme.errorContainer
                        : colorScheme.surfaceContainerHighest.withOpacity(0.7),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  message.isUser
                      ? Text(
                          message.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: message.isError
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onSurface,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            listBullet: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(colorScheme, isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, {required bool isUser}) {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: isUser ? colorScheme.tertiary : colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_outline : Icons.smart_toy_outlined,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(colorScheme, isUser: false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 200),
                SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3 + (_animation.value * 0.7)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
