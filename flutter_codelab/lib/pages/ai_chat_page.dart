import 'package:flutter/material.dart';
import 'package:code_play/models/user_data.dart';
import 'package:code_play/services/ai_chat_api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';
import 'package:code_play/controllers/locale_controller.dart';

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
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({String? text, bool? isTyping, bool? isError}) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      isError: isError ?? this.isError,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Safely handle null values - ensure all required fields have defaults
    final idValue = map['id'] ?? map['message_id'];
    final id = idValue != null && idValue.toString().isNotEmpty
        ? idValue.toString()
        : DateTime.now().millisecondsSinceEpoch.toString();

    // Handle content/message - ensure it's never null
    final contentValue = map['content'] ?? map['message'];
    final text = (contentValue != null && contentValue.toString().isNotEmpty)
        ? contentValue.toString()
        : '';

    // Handle role/sender - safely check for user role
    final role = map['role']?.toString() ?? '';
    final sender = map['sender']?.toString() ?? '';
    final isUser =
        role.toLowerCase() == 'user' || sender.toLowerCase() == 'user';

    // Handle timestamp - safely parse
    DateTime? timestamp;
    final createdAt = map['created_at'];
    if (createdAt != null) {
      try {
        final createdAtStr = createdAt.toString();
        if (createdAtStr.isNotEmpty) {
          timestamp = DateTime.tryParse(createdAtStr);
        }
      } catch (e) {
        // If parsing fails, timestamp remains null (will use default)
      }
    }

    return ChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: timestamp,
    );
  }
}

/// AI Chat Page - Main Widget
class AiChatPage extends StatefulWidget {
  final UserDetails? currentUser;
  final String? authToken;

  const AiChatPage({super.key, this.currentUser, this.authToken});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AiChatApiService _apiService;
  bool _isSending = false;
  bool _isInitialized = false;
  String? _currentSessionId;
  bool _isNewChat = false;
  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _sessions = [];
  bool _hasSentFirstMessage = false;

  // Selection State (for bulk delete)
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  // Getter for sessionId - assuming it should be generated or retrieved
  String get sessionId =>
      _currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _apiService = AiChatApiService(token: widget.authToken);
    _loadHistory();
    // _initializeChat(); // Removed as _loadHistory handles initial state better or user picks a chat
  }

  Future<void> _loadHistory() async {
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
        // Silent failure or log
        print('Error loading history: $e');
      }
    }
  }

  Future<void> _loadSessionMessages(String sessionId) async {
    if (sessionId.isEmpty) {
      _showSnackBar('Invalid session ID', Colors.red);
      return;
    }

    setState(() {
      _isSending = true;
      _currentSessionId = sessionId;
      _messages.clear();
      _isNewChat = false;
      _hasSentFirstMessage = false; // Reset when loading a session
    });

    try {
      final messages = await _apiService.getSessionMessages(sessionId);
      if (mounted) {
        setState(() {
          // Safely map messages, filtering out any that fail to parse
          final validMessages = <ChatMessage>[];
          for (final m in messages) {
            try {
              final message = ChatMessage.fromMap(m);
              // Only add messages with content or typing indicator
              if (message.text.isNotEmpty || message.isTyping) {
                validMessages.add(message);
              }
            } catch (e) {
              print('Error parsing message: $e, data: $m');
              // Skip invalid messages to prevent crashes
            }
          }
          _messages.addAll(validMessages);
          // Sort if needed, assuming API sends chronologically
          // _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _isSending = false;
          // If session has messages, hide input box (first message already sent)
          if (_messages.isNotEmpty) {
            _hasSentFirstMessage = true;
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          // Keep session ID so chat view is still shown even if loading fails
          // This allows user to see the error and potentially retry
        });
        _showSnackBar('Failed to load messages: ${e.toString()}', Colors.red);
        print('Error loading session messages: $e');
      }
    }
  }

  void _initializeChat() {
    // Legacy init, keeping for reference if needed but _loadHistory is primary now
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentSessionId = null;
      _isNewChat = true;
      _hasSentFirstMessage = false;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (_isSending || _hasSentFirstMessage) return;

    if (text.isEmpty) {
      _showSnackBar('Please enter a question', Colors.red);
      return;
    }

    // Set sending state and mark first message sent
    setState(() {
      _isSending = true;
      _hasSentFirstMessage = true;
    });

    final userMessage = ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.add(userMessage); // Add to end (chronological order)
      _textController.clear();
    });

    _scrollToBottom();
    _focusNode.unfocus();

    final typingMessage = ChatMessage(text: '', isUser: false, isTyping: true);
    setState(() => _messages.add(typingMessage)); // Add to end

    try {
      // Get current language from LocaleController
      final currentLocale = LocaleController.instance.value;
      final languageCode = currentLocale.languageCode; // 'en' or 'ms'

      final responseData = await _apiService.sendMessage(
        text,
        sessionId: _currentSessionId,
        language: languageCode, // Pass language code to API
      );

      final aiResponse = responseData['ai_response'] as String;
      final newSessionId = responseData['session_id'] as String?;

      if (mounted) {
        setState(() {
          _currentSessionId = newSessionId;
          _messages.removeWhere((msg) => msg.id == typingMessage.id);
          _messages.add(
            ChatMessage(text: aiResponse, isUser: false),
          ); // Add to end
          _isSending = false;
          // Keep _hasSentFirstMessage = true to hide input box after first message
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage =
            'Connection error. Please try again later.';

        // Provide more specific error messages
        final errorString = e.toString();
        if (errorString.contains('500') ||
            errorString.contains('Server error')) {
          errorMessage =
              'Server error. The AI service may not be configured correctly. Please contact the administrator.';
        } else if (errorString.contains('timeout')) {
          errorMessage =
              'Request timeout. Please check your internet connection and try again.';
        } else if (errorString.contains('401') ||
            errorString.contains('Authentication')) {
          errorMessage = 'Authentication required. Please login again.';
        } else if (errorString.contains('Network error')) {
          errorMessage =
              'Network error. Please check your connection and ensure the backend is running.';
        }

        setState(() {
          _messages.removeWhere((msg) => msg.id == typingMessage.id);
          _messages.add(
            ChatMessage(text: errorMessage, isUser: false, isError: true),
          ); // Add to end
          _isSending = false;
          // Keep _hasSentFirstMessage = true to hide input box after first message
        });
      }
    }
    _scrollToBottom();
  }

  void _handleSuggestedQuestion(String question) {
    _textController.text = question;
    _handleSendMessage();
  }

  // Selection methods
  void _toggleSelection(String sessionId) {
    setState(() {
      if (_selectedIds.contains(sessionId)) {
        _selectedIds.remove(sessionId);
      } else {
        _selectedIds.add(sessionId);
      }
    });
  }

  // Bulk delete function
  Future<void> _deleteSelectedSessions() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteChatSessionsTitle),
          content: Text(
            l10n.deleteChatSessionsConfirmation(_selectedIds.length),
          ),
          actions: [
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    setState(() {
      _isDeleting = true;
    });

    int successCount = 0;
    int failCount = 0;
    List<String> successfullyDeletedIds = [];

    for (final id in _selectedIds) {
      try {
        await _apiService.deleteSession(id);
        successCount++;
        successfullyDeletedIds.add(id);
      } catch (e) {
        print("Failed to delete session $id: $e");
        failCount++;
      }
    }

    if (mounted) {
      setState(() {
        _isDeleting = false;
        _selectedIds.removeWhere((id) => successfullyDeletedIds.contains(id));
        // Remove deleted sessions from list
        _sessions.removeWhere((s) {
          final sessionId = s['session_id'] ?? s['chatbot_session_id'];
          return successfullyDeletedIds.contains(sessionId?.toString());
        });
      });

      String message;
      Color snackColor;
      final l10n = AppLocalizations.of(context)!;
      if (failCount == 0) {
        message = l10n.chatSessionsDeletedSuccessfully(successCount);
        snackColor = Colors.green;
      } else {
        message = 'Deleted: $successCount, Failed: $failCount';
        snackColor = failCount > 0 ? Colors.red : Colors.orange;
      }

      _showSnackBar(message, snackColor);
    }
  }

  Widget _buildSelectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey("SelectionHeader"),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              ),
              Text(
                "${_selectedIds.length} ${AppLocalizations.of(context)!.selected}",
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          if (_isDeleting)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: _deleteSelectedSessions,
            ),
        ],
      ),
    );
  }

  Widget _buildSortHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey("SortHeader"),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${_sessions.length} Results",
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.clearHistory),
          content: Text(l10n.clearHistoryConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Check if there's a session to delete
      if (_currentSessionId == null || _currentSessionId!.isEmpty) {
        // If no session, just clear local messages
        if (mounted) {
          setState(() {
            _messages.clear();
            _currentSessionId = null;
            _hasSentFirstMessage = false;
          });
          _showSnackBar('Chat cleared successfully', Colors.green);
        }
        return;
      }

      try {
        await _apiService.deleteSession(_currentSessionId!);
        if (mounted) {
          setState(() {
            _messages.clear();
            _currentSessionId = null;
            _hasSentFirstMessage = false;
          });
          _loadHistory();
          // Show success message
          _showSnackBar('Chat deleted successfully', Colors.green);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            AppLocalizations.of(context)!.deleteFailed(e.toString()),
            Colors.red,
          );
        }
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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2.0, 2.0, 16.0, 16.0),
      child: Card(
        elevation: 2.0,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                (_currentSessionId == null && _messages.isEmpty && !_isNewChat)
                ? _buildLandingView(colorScheme)
                : _buildChatView(colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildLandingView(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.aiChatTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
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
                l10n.howCanIHelp,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startNewChat,
                icon: const Icon(Icons.add),
                label: Text(l10n.askQuestion),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSuggestedQuestions(colorScheme),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Text(
          l10n.recentQuestions,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (!_isLoadingHistory && _sessions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16.0,
              8.0,
              16.0,
              16.0,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedIds.isNotEmpty
                  ? _buildSelectionHeader(context)
                  : _buildSortHeader(context),
            ),
          ),
        Expanded(
          child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _sessions.isEmpty
              ? Center(child: Text(l10n.noQuestionsFound))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final sessionId = session['session_id'] ??
                        session['chatbot_session_id'];
                    final sessionIdStr = sessionId?.toString() ?? '';
                    final isSelected = _selectedIds.contains(sessionIdStr);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 1.0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(
                          (session['title'] == null ||
                                  session['title'].toString().isEmpty ||
                                  session['title'] == 'Untitled Question')
                              ? (session['last_message']?.toString() ??
                                    l10n.untitledQuestion)
                              : session['title'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          session['updated_at']?.toString().split('T')[0] ??
                              session['created_at']?.toString().split('T')[0] ??
                              '',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: colorScheme.primary)
                            : const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          // If any items are selected, toggle selection; otherwise load session
                          if (_selectedIds.isNotEmpty) {
                            _toggleSelection(sessionIdStr);
                          } else {
                            if (sessionIdStr.isNotEmpty) {
                              _loadSessionMessages(sessionIdStr);
                            } else {
                              _showSnackBar('Invalid session ID', Colors.red);
                            }
                          }
                        },
                        onLongPress: () {
                          _toggleSelection(sessionIdStr);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatView(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
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
                  tooltip: l10n.backToHistory,
                ),
                Text(
                  "KalmNest AI",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
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
                  tooltip: l10n.refreshQuestion,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _messages.isNotEmpty ? _clearChat : null,
                  tooltip: l10n.deleteChat,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _messages.length,
            itemBuilder: (context, index) =>
                _MessageBubble(message: _messages[index]),
          ),
        ),
        // Show input area only if first message hasn't been sent yet
        if (!_isSending && !_hasSentFirstMessage) _buildInputArea(colorScheme),
      ],
    );
  }

  Widget _buildSuggestedQuestions(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final suggestionPrefix = l10n.suggestionPrefix;
    final suggestedQuestions = [
      "${suggestionPrefix}HTML",
      "${suggestionPrefix}CSS",
      "${suggestionPrefix}JavaScript",
      "${suggestionPrefix}PHP",
      "${suggestionPrefix}Web Development",
    ];

    return Column(
      children: [
        Text(
          l10n.quickSuggestions,
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
          children: suggestedQuestions.map((question) {
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

            final label = question.replaceFirst(suggestionPrefix, "");

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () => _handleSuggestedQuestion(question),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI responds in the same language as your question',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.typeQuestionHint,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSending ? null : _handleSendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSending
                          ? colorScheme.outline
                          : colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: _isSending
                          ? []
                          : [
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
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (message.isTyping) {
      return _buildTypingIndicator(colorScheme);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withBlue(200),
                        ],
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
                  MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : message.isError
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
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

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          color: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.3 + (_animation.value * 0.7)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
