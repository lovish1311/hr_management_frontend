import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';
import 'package:hr_management/features/banners/presentation/widgets/emoji_reaction_bar.dart';

/// Fluid, overflow-proof card widget for Company News posts in the Engage feed
class NewsFeedCard extends StatelessWidget {
  final BannerModel banner;
  final bool isHighlighted;
  final void Function(String reactionType)? onReactionTapped;
  final VoidCallback? onActionTapped;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const NewsFeedCard({
    super.key,
    required this.banner,
    this.isHighlighted = false,
    this.onReactionTapped,
    this.onActionTapped,
    this.onDelete,
    this.onEdit,
    this.onToggleStatus,
  });

  bool get _hasCustomAction {
    if (banner.isScheduled) return false;
    final text = banner.actionButtonText?.trim() ?? '';
    if (text.isEmpty) return false;
    if (text.toLowerCase() == 'view celebrations' || text.toLowerCase() == 'view schedule') {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canManage = AuthStorage.canManageBanners;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? theme.colorScheme.primary
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
            width: isHighlighted ? 2.5 : 1.0,
          ),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
              // 1. Cover Image Header (strictly bounded by AspectRatio 16/9)
              if (banner.resolvedImageUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image Loader (Asset or Network with Shimmer Placeholder)
                      banner.resolvedImageUrl!.startsWith('assets/')
                          ? Image.asset(
                              banner.resolvedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackBanner(theme),
                            )
                          : Image.network(
                              banner.resolvedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackBanner(theme),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        isDark ? const Color(0xFF232733) : const Color(0xFFE5E7EB),
                                        isDark ? const Color(0xFF2E3342) : const Color(0xFFF3F4F6),
                                        isDark ? const Color(0xFF232733) : const Color(0xFFE5E7EB),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_rounded,
                                      size: 36,
                                      color: isDark ? Colors.white24 : Colors.black26,
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Gradient overlay for contrast
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      // Top Row: Category Badge + Admin 3-Dot Overflow Menu
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24, width: 0.5),
                                ),
                                child: Text(
                                  banner.category.name.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            if (canManage) ...[
                              const SizedBox(width: 8),
                              _buildAdminMenu(context, theme),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (canManage) ...[
                // If there's no image, render top-right menu directly
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: _buildAdminMenu(context, theme),
                  ),
                ),
              ],

              // 2. Card Content Body (expands naturally, zero hardcoded heights)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status, Scheduled, and Department Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (banner.isScheduled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 13, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  'Scheduled • ${banner.startDate.day}/${banner.startDate.month}/${banner.startDate.year}',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isHighlighted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FEATURED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (banner.targetDepartment != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Dept: ${banner.targetDepartment}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      banner.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        height: 1.3,
                      ),
                    ),

                    // Subtitle
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

                    // Legitimate Action Button (only if genuine custom action)
                    if (_hasCustomAction) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: onActionTapped,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          icon: const Icon(Icons.arrow_outward_rounded, size: 16),
                          label: Text(banner.actionButtonText!),
                        ),
                      ),
                    ],

                    const Divider(height: 24, thickness: 0.8),

                    // 3. Teams-Style Interactive Emoji Reaction Bar
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

  Widget _buildAdminMenu(BuildContext context, ThemeData theme) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
        tooltip: 'Post Options',
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
                Text('Edit Post'),
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
    );
  }

  Widget _buildFallbackBanner(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.85),
            theme.colorScheme.secondary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.campaign_rounded, size: 48, color: Colors.white70),
      ),
    );
  }
}
