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
  final FocusNode _focusNode = FocusNode();

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
    // Keep focus so the player can continue typing rapid guesses
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
              horizontal: compact ? 8 : 12,
              vertical: compact ? 6 : 8,
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
                  size: compact ? 13 : 15,
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'GUESSES & CHAT',
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.messages.length}',
                    style: TextStyle(
                      fontSize: compact ? 9 : 10,
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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.isDrawer ? 'Waiting for guesses...' : 'Type guesses below...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 10,
                      vertical: compact ? 4 : 6,
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
            padding: EdgeInsets.all(compact ? 6 : 8),
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
                    focusNode: _focusNode,
                    enabled: !widget.isDrawer,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    style: TextStyle(fontSize: compact ? 11 : 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.isDrawer
                          ? 'Drawing! No guessing.'
                          : (widget.hasGuessedCorrectly
                              ? 'Chat here...'
                              : 'Type your guess...'),
                      hintStyle: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                        overflow: TextOverflow.ellipsis,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
                        vertical: compact ? 6 : 8,
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
                SizedBox(width: compact ? 4 : 6),
                IconButton(
                  onPressed: widget.isDrawer ? null : _submit,
                  icon: Icon(Icons.send_rounded, size: compact ? 14 : 16),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    disabledForegroundColor: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                    padding: EdgeInsets.all(compact ? 6 : 7),
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
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '${msg.senderName} guessed the word!',
                style: TextStyle(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 10 : 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (msg.isCloseGuess) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                msg.message,
                style: TextStyle(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 10 : 11,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${msg.senderName}: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 12,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            TextSpan(
              text: msg.message,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: compact ? 11 : 12,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
        softWrap: true,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
