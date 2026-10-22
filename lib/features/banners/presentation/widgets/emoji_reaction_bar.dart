import 'package:flutter/material.dart';

/// Teams-style interactive social emoji bar with dynamic active pills and a reaction palette.
class EmojiReactionBar extends StatelessWidget {
  final Map<String, int> reactionCounts;
  final Set<String> userReactions;
  final void Function(String reactionType) onReactionTapped;

  const EmojiReactionBar({
    super.key,
    required this.reactionCounts,
    required this.userReactions,
    required this.onReactionTapped,
  });

  static const List<({String key, String emoji, String label})> availableReactions = [
    (key: 'LIKE', emoji: '👍', label: 'Like'),
    (key: 'LOVE', emoji: '❤️', label: 'Love'),
    (key: 'CELEBRATE', emoji: '🎉', label: 'Celebrate'),
    (key: 'WISH', emoji: '🎂', label: 'Wish'),
    (key: 'CLAP', emoji: '👏', label: 'Clap'),
  ];

  void _showPalette(BuildContext context, TapDownDetails details) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        details.globalPosition,
        details.globalPosition,
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF252A37)
          : Colors.white,
      items: [
        _ReactionPaletteEntry(
          reactions: availableReactions,
          userReactions: userReactions,
        ),
      ],
    );

    if (selected != null) {
      onReactionTapped(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter to only active reactions (count > 0 or reacted by current user)
    final activeReactions = availableReactions.where((r) {
      final count = reactionCounts[r.key] ?? 0;
      return count > 0 || userReactions.contains(r.key);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Render Active Reaction Pills
          ...activeReactions.map((r) {
            final isSelected = userReactions.contains(r.key);
            final count = reactionCounts[r.key] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onReactionTapped(r.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 5),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // 2. Teams-style Add Reaction (+) Pill
          GestureDetector(
            onTapDown: (details) => _showPalette(context, details),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_reaction_outlined,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    if (activeReactions.isEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        'React',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom PopupMenuEntry rendering horizontal reaction options without IgnorePointer restrictions
class _ReactionPaletteEntry extends PopupMenuEntry<String> {
  const _ReactionPaletteEntry({
    required this.reactions,
    required this.userReactions,
  });

  final List<({String key, String emoji, String label})> reactions;
  final Set<String> userReactions;

  @override
  double get height => 48.0;

  @override
  bool represents(String? value) => false;

  @override
  State<_ReactionPaletteEntry> createState() => _ReactionPaletteEntryState();
}

class _ReactionPaletteEntryState extends State<_ReactionPaletteEntry> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.reactions.map((r) {
          final isChosen = widget.userReactions.contains(r.key);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).pop(r.key);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isChosen
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    r.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
