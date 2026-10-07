import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';

class DrawGuessChatPanel extends StatefulWidget {
  final List<ChatMessageItem> messages;
  final bool isDrawer;
  final bool hasGuessedCorrectly;
  final ValueChanged<String> onSendGuess;
  final bool isCompact;

  const DrawGuessChatPanel({
    super.key,
    required this.messages,
    required this.isDrawer,
    required this.hasGuessedCorrectly,
    required this.onSendGuess,
    this.isCompact = false,
  });

  @override
  State<DrawGuessChatPanel> createState() => _DrawGuessChatPanelState();
}

class _DrawGuessChatPanelState extends State<DrawGuessChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant DrawGuessChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendGuess(text);
    _controller.clear();
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
    final isDark = theme.brightness == Brightness.dark;
    final compact = widget.isCompact;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 16,
              vertical: compact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: compact ? 14 : 18,
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(width: 6),
                Text(
                  compact ? 'GUESS & CHAT FEED' : 'GUESS & CHAT FEED',
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.messages.length}',
                    style: TextStyle(
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      'Type guesses below...',
                      style: TextStyle(
                        fontSize: compact ? 11 : 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 12,
                      vertical: compact ? 4 : 8,
                    ),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final msg = widget.messages[index];
                      return _buildMessageItem(context, msg, compact);
                    },
                  ),
          ),

          // Input Box
          Container(
            padding: EdgeInsets.all(compact ? 6 : 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !widget.isDrawer,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    style: TextStyle(fontSize: compact ? 12 : 13),
                    decoration: InputDecoration(
                      isDense: compact,
                      hintText: widget.isDrawer
                          ? 'You are drawing! No guessing.'
                          : (widget.hasGuessedCorrectly
                              ? 'You guessed correctly! Chat here...'
                              : 'Type your guess here...'),
                      hintStyle: TextStyle(
                        fontSize: compact ? 11 : 13,
                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 14,
                        vertical: compact ? 6 : 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 4 : 8),
                IconButton(
                  onPressed: widget.isDrawer ? null : _submit,
                  icon: Icon(Icons.send_rounded, size: compact ? 15 : 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    disabledForegroundColor: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                    padding: EdgeInsets.all(compact ? 6 : 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessageItem msg, bool compact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (msg.isCorrectGuess) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 1.5 : 3),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: const Color(0xFF10B981), size: compact ? 13 : 16),
            SizedBox(width: compact ? 4 : 6),
            Expanded(
              child: Text(
                '${msg.senderName} guessed the word!',
                style: TextStyle(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (msg.isCloseGuess) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 1.5 : 3),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: const Color(0xFFF59E0B), size: compact ? 13 : 16),
            SizedBox(width: compact ? 4 : 6),
            Expanded(
              child: Text(
                msg.message,
                style: TextStyle(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 1.5 : 2.5),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: compact ? 11 : 13,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
          children: [
            TextSpan(
              text: '${msg.senderName}: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            TextSpan(text: msg.message),
          ],
        ),
      ),
    );
  }
}
