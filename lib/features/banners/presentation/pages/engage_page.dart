import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import 'package:hr_management/core/widgets/app_toast.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';
import 'package:hr_management/features/banners/presentation/providers/banner_providers.dart';
import 'package:hr_management/features/banners/presentation/widgets/banner_management_dialog.dart';
import 'package:hr_management/features/banners/presentation/widgets/news_feed_card.dart';
import 'package:hr_management/features/banners/presentation/widgets/spotlight_card.dart';

/// Engage Social Hub Page (/engage)
/// Deep-link safe, URL query-param aware, and responsive across phones, tablets, and desktop.
class EngagePage extends ConsumerStatefulWidget {
  final String? initialTab;
  final String? initialFilter;
  final int? highlightId;

  const EngagePage({
    super.key,
    this.initialTab,
    this.initialFilter,
    this.highlightId,
  });

  @override
  ConsumerState<EngagePage> createState() => _EngagePageState();
}

class _EngagePageState extends ConsumerState<EngagePage> {
  late BannerType _selectedTab;
  CelebrationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedTab = (widget.initialTab?.toLowerCase() == 'celebrations')
        ? BannerType.celebration
        : BannerType.news;

    if (widget.initialFilter != null) {
      final f = widget.initialFilter!.toLowerCase();
      if (f == 'birthday') {
        _selectedFilter = CelebrationType.birthday;
      } else if (f == 'anniversary') {
        _selectedFilter = CelebrationType.anniversary;
      }
    }
  }

  String get _feedKey => buildEngageFeedKey(_selectedTab, _selectedFilter);

  void _openManageDialog() {
    BannerManagementDialog.show(context);
  }

  void _confirmDeleteBanner(BannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: Text('Are you sure you want to delete "${banner.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(engageFeedProvider(_feedKey).notifier).deleteBanner(banner.id);
        if (mounted) AppToast.success(context, 'Post deleted successfully.');
      } catch (e) {
        if (mounted) AppToast.error(context, 'Failed to delete post', rawError: e);
      }
    }
  }

  void _editBanner(BannerModel banner) {
    BannerManagementDialog.show(context, initialBanner: banner);
  }

  void _toggleBannerStatus(BannerModel banner) async {
    try {
      await ref.read(bannerApiServiceProvider).toggleBannerStatus(banner.id);
      await ref.read(engageFeedProvider(_feedKey).notifier).refresh();
      if (mounted) {
        AppToast.success(context, banner.isActive ? 'Post hidden from feed.' : 'Post published.');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Failed to toggle post status', rawError: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedAsync = ref.watch(engageFeedProvider(_feedKey));
    final canManage = AuthStorage.canManageBanners;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Engage Social Hub 🌟'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Create Banner or Post',
              onPressed: _openManageDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Feed',
            onPressed: () {
              ref.read(engageFeedProvider(_feedKey).notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Controls: Tabs and Sub-Filters
            _buildFilterHeader(theme),

            // Feed Content Body: Single-Column Feed Clamped to 720dp
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(engageFeedProvider(_feedKey).notifier).refresh();
                },
                child: feedAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load engage feed',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppToast.sanitizeErrorMessage(err),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(engageFeedProvider(_feedKey).notifier).refresh();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (banners) {
                    if (banners.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    // Highlight Pinning: Sort highlighted ID to index 0
                    final sortedBanners = List<BannerModel>.from(banners);
                    if (widget.highlightId != null) {
                      final targetIdx = sortedBanners.indexWhere((b) => b.id == widget.highlightId);
                      if (targetIdx != -1) {
                        final highlightedItem = sortedBanners.removeAt(targetIdx);
                        sortedBanners.insert(0, highlightedItem);
                      }
                    }

                    return _buildSingleColumnFeed(sortedBanners);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Primary Tab Switcher (News vs Celebrations)
          SegmentedButton<BannerType>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment<BannerType>(
                value: BannerType.news,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Company News 📰',
                    maxLines: 1,
                  ),
                ),
              ),
              ButtonSegment<BannerType>(
                value: BannerType.celebration,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Celebrations 🎉',
                    maxLines: 1,
                  ),
                ),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedTab = selection.first;
              });
            },
          ),

          // 2. Celebration Sub-filter chips
          if (_selectedTab == BannerType.celebration) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('All Celebrations', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Birthdays 🎂', CelebrationType.birthday),
                  const SizedBox(width: 8),
                  _buildFilterChip('Work Anniversaries 🎖️', CelebrationType.anniversary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CelebrationType? type) {
    final isSelected = _selectedFilter == type;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        debugPrint('[EngagePage] Chip tapped: $type');
        setState(() => _selectedFilter = type);
      },
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          debugPrint('[EngagePage] ChoiceChip onSelected: $type');
          setState(() => _selectedFilter = type);
        },
      ),
    );
  }

  /// Single-column scrollable feed, strictly one card per row across all devices
  Widget _buildSingleColumnFeed(List<BannerModel> banners) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: banners.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final banner = banners[index];
            final isHighlighted = widget.highlightId != null && banner.id == widget.highlightId;
            return _renderCard(banner, isHighlighted);
          },
        ),
      ),
    );
  }

  Widget _renderCard(BannerModel banner, bool isHighlighted) {
    if (banner.isCelebration) {
      return SpotlightCard(
        banner: banner,
        isHighlighted: isHighlighted,
        onReactionTapped: (type) {
          ref.read(engageFeedProvider(_feedKey).notifier).toggleReaction(banner.id, type);
        },
        onDelete: () => _confirmDeleteBanner(banner),
        onEdit: () => _editBanner(banner),
        onToggleStatus: () => _toggleBannerStatus(banner),
      );
    }

    return NewsFeedCard(
      banner: banner,
      isHighlighted: isHighlighted,
      onReactionTapped: (type) {
        ref.read(engageFeedProvider(_feedKey).notifier).toggleReaction(banner.id, type);
      },
      onActionTapped: () {
        if (banner.actionUrl != null && banner.actionUrl!.startsWith('/')) {
          Navigator.pushNamed(context, banner.actionUrl!);
        } else if (banner.actionUrl != null) {
          AppToast.info(context, 'Navigating to: ${banner.actionUrl}');
        }
      },
      onDelete: () => _confirmDeleteBanner(banner),
      onEdit: () => _editBanner(banner),
      onToggleStatus: () => _toggleBannerStatus(banner),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedTab == BannerType.celebration
                  ? Icons.celebration_rounded
                  : Icons.newspaper_rounded,
              size: 48,
              color: theme.disabledColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedTab == BannerType.celebration
                  ? 'No celebrations scheduled right now'
                  : 'No news announcements right now',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Check back soon or pull down to refresh!',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
