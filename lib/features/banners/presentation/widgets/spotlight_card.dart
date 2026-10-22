import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';
import 'package:hr_management/features/banners/presentation/widgets/emoji_reaction_bar.dart';

/// Festive, overflow-proof celebration spotlight card (Birthdays, Work Anniversaries, Milestones)
class SpotlightCard extends StatelessWidget {
  final BannerModel banner;
  final bool isHighlighted;
  final void Function(String reactionType)? onReactionTapped;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const SpotlightCard({
    super.key,
    required this.banner,
    this.isHighlighted = false,
    this.onReactionTapped,
    this.onDelete,
    this.onEdit,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canManage = AuthStorage.canManageBanners;

    final isBirthday = banner.isBirthday;
    final isAnniversary = banner.isAnniversary;

    // Elegant gradient themes based on celebration type
    final LinearGradient cardGradient = isBirthday
        ? const LinearGradient(
            colors: [Color(0xFFFF5E62), Color(0xFFFF9966)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : isAnniversary
            ? const LinearGradient(
                colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

    final String badgeLabel = isBirthday
        ? 'BIRTHDAY CELEBRATION 🎂'
        : isAnniversary
            ? 'WORK ANNIVERSARY 🎖️'
            : 'TEAM CELEBRATION 🎉';

    final String initials = (banner.targetEmployeeName != null &&
            banner.targetEmployeeName!.trim().isNotEmpty)
        ? banner.targetEmployeeName!
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : '🎉';

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? Colors.amberAccent
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
            width: isHighlighted ? 2.5 : 1.0,
          ),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Festive Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(gradient: cardGradient),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (banner.targetEmployeeName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              banner.targetEmployeeName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canManage)
                      Material(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: const CircleBorder(),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                          tooltip: 'Celebration Options',
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            if (value == 'delete') {
                              onDelete?.call();
                            } else if (value == 'edit') {
                              onEdit?.call();
                            } else if (value == 'toggle') {
                              onToggleStatus?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit Celebration'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    banner.isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(banner.isActive ? 'Hide Post' : 'Publish Post'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text('Delete Post', style: TextStyle(color: Colors.redAccent)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Celebration Greeting Body (natural vertical expansion)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    if (banner.subtitle != null && banner.subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        banner.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],

                    const Divider(height: 24, thickness: 0.8),

                    // 3. Teams-Style Social Reactions
                    EmojiReactionBar(
                      reactionCounts: banner.reactionCounts,
                      userReactions: banner.userReactions,
                      onReactionTapped: (type) => onReactionTapped?.call(type),
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
}
