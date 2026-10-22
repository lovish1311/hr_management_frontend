import 'package:flutter/material.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';
import 'package:hr_management/features/banners/presentation/widgets/emoji_reaction_bar.dart';

/// Modal dialog for popup broadcast / featured banner presentation with top-right 'X' button
class BannerPopupDialog extends StatelessWidget {
  final BannerModel banner;
  final void Function(String reactionType)? onReactionTapped;
  final VoidCallback? onActionTapped;

  const BannerPopupDialog({
    super.key,
    required this.banner,
    this.onReactionTapped,
    this.onActionTapped,
  });

  static Future<void> show(
    BuildContext context, {
    required BannerModel banner,
    void Function(String reactionType)? onReactionTapped,
    VoidCallback? onActionTapped,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BannerPopupDialog(
        banner: banner,
        onReactionTapped: onReactionTapped,
        onActionTapped: onActionTapped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header image with top-right close 'X'
              Stack(
                children: [
                  if (banner.resolvedImageUrl != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        banner.resolvedImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackHeader(theme),
                      ),
                    )
                  else
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildFallbackHeader(theme),
                    ),

                  // Top-right Close X button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Body content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1.3,
                      ),
                    ),
                    if (banner.subtitle != null && banner.subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        banner.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                          height: 1.45,
                        ),
                      ),
                    ],

                    if (banner.actionButtonText != null &&
                        banner.actionButtonText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onActionTapped?.call();
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: Text(banner.actionButtonText!),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],

                    const Divider(height: 28, thickness: 0.8),

                    // Reactions
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

  Widget _buildFallbackHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.campaign_rounded, size: 54, color: Colors.white60),
      ),
    );
  }
}
