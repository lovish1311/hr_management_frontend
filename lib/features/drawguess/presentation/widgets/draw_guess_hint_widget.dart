import 'package:flutter/material.dart';

class DrawGuessHintWidget extends StatelessWidget {
  final String? hintPattern;
  final int wordLength;
  final String category;
  final bool isDrawer;
  final String? secretWord;

  const DrawGuessHintWidget({
    super.key,
    this.hintPattern,
    this.wordLength = 0,
    this.category = 'GENERAL',
    this.isDrawer = false,
    this.secretWord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayText = isDrawer && secretWord != null && secretWord!.isNotEmpty
        ? secretWord!
        : (hintPattern != null && hintPattern!.isNotEmpty
            ? hintPattern!
            : (wordLength > 0 ? List.filled(wordLength, '_').join(' ') : ''));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Word / Hint Pattern
          Flexible(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: isDrawer ? 1.0 : 4.0,
                color: isDrawer ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (!isDrawer && wordLength > 0) ...[
            const SizedBox(width: 10),
            Text(
              '($wordLength)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
