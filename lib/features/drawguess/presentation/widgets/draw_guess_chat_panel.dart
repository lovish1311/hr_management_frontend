import 'package:flutter/material.dart';
import '../../data/models/draw_guess_models.dart';

class DrawGuessChatPanel extends StatefulWidget {
  final List<ChatMessageItem> messages;
  final bool isDrawer;
  final bool hasGuessedCorrectly;
  final ValueChanged<String> onSendGuess;

  const DrawGuessChatPanel({
    super.key,
    required this.messages,
    required this.isDrawer,
    required this.hasGuessedCorrectly,
    required this.onSendGuess,
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  'GUESS & CHAT FEED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.messages.length} messages',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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
                        fontSize: 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final msg = widget.messages[index];
                      return _buildMessageItem(context, msg);
                    },
                  ),
          ),

          // Input Box
          Container(
            padding: const EdgeInsets.all(12),
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
                    decoration: InputDecoration(
                      hintText: widget.isDrawer
                          ? 'You are drawing! No guessing.'
                          : (widget.hasGuessedCorrectly
                              ? 'You guessed correctly! Chat here...'
                              : 'Type your guess here...'),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: widget.isDrawer ? null : _submit,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessageItem msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (msg.isCorrectGuess) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${msg.senderName} guessed the word!',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (msg.isCloseGuess) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                msg.message,
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)),
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
