import 'dart:async';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';
import 'package:hr_management/features/banners/presentation/providers/banner_providers.dart';

/// Responsive, lifecycle-safe auto-sliding banner carousel with touch/hover pause
class BannerCarouselWidget extends ConsumerStatefulWidget {
  final double? height;
  final void Function(BannerModel banner)? onBannerTapped;

  const BannerCarouselWidget({
    super.key,
    this.height,
    this.onBannerTapped,
  });

  @override
  ConsumerState<BannerCarouselWidget> createState() => _BannerCarouselWidgetState();
}

/// Silky-smooth page scroll physics optimized for responsive finger sliding and gesture flings
class SmoothPageScrollPhysics extends PageScrollPhysics {
  const SmoothPageScrollPhysics({super.parent});

  @override
  SmoothPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 110.0,
    ratio: 1.1,
  );
}

class _BannerCarouselWidgetState extends ConsumerState<BannerCarouselWidget> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _startAutoSlide(int itemCount) {
    _autoSlideTimer?.cancel();
    if (itemCount <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _isUserInteracting) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Resets the 5-second auto-slide timer whenever the user slides, drags, or clicks navigation
  void _resetAutoSlideCooldown(int itemCount) {
    _startAutoSlide(itemCount);
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleBannerClick(BannerModel banner) {
    debugPrint('[BannerCarouselWidget] Banner clicked: ${banner.id} - ${banner.title}');
    if (widget.onBannerTapped != null) {
      widget.onBannerTapped!(banner);
      return;
    }

    // Default: Navigate to /engage with news tab and highlighted banner ID
    final tab = banner.isCelebration ? 'celebrations' : 'news';
    final filter = banner.isBirthday ? 'birthday' : (banner.isAnniversary ? 'anniversary' : null);

    Navigator.pushNamed(
      context,
      '/engage',
      arguments: {
        'tab': tab,
        'filter': filter,
        'highlightId': banner.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBannersAsync = ref.watch(activeBannersProvider);

    return activeBannersAsync.when(
      loading: () => _buildShimmerPlaceholder(context),
      error: (err, stack) {
        debugPrint('[BannerCarouselWidget] Error loading active banners: $err\n$stack');
        return const SizedBox.shrink();
      },
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        // Restart timer safely if item count changed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _autoSlideTimer == null) {
            _startAutoSlide(banners.length);
          }
        });

        final screenWidth = MediaQuery.of(context).size.width;
        // Responsive aspect ratio: 16:9 on phone (<600px), 18:9 on tablet, 21:9 on desktop
        final double aspectRatio = screenWidth < 600
            ? (16 / 9)
            : screenWidth < 900
                ? (18 / 9)
                : (21 / 9);

        final Widget carouselCard = Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Carousel View with Touch & Mouse Drag Support and NotificationListener
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is UserScrollNotification) {
                      if (notification.direction != ScrollDirection.idle) {
                        _isUserInteracting = true;
                        _autoSlideTimer?.cancel();
                      } else {
                        _isUserInteracting = false;
                        _resetAutoSlideCooldown(banners.length);
                      }
                    } else if (notification is ScrollEndNotification) {
                      _isUserInteracting = false;
                      _resetAutoSlideCooldown(banners.length);
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: banners.length,
                    physics: const SmoothPageScrollPhysics(),
                    scrollBehavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _resetAutoSlideCooldown(banners.length);
                    },
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return _buildSlide(context, banner);
                    },
                  ),
                ),

                // Interactive Prev / Next Navigation Arrows at edges with subtle opacity
                if (banners.length > 1) ...[
                  // Previous Arrow
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.20),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            final prevPage = (_currentPage - 1 + banners.length) % banners.length;
                            _pageController.animateToPage(
                              prevPage,
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                            );
                            _resetAutoSlideCooldown(banners.length);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white.withValues(alpha: 0.80),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Next Arrow
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.20),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            final nextPage = (_currentPage + 1) % banners.length;
                            _pageController.animateToPage(
                              nextPage,
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                            );
                            _resetAutoSlideCooldown(banners.length);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withValues(alpha: 0.80),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Dot Indicators at bottom center
                if (banners.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(banners.length, (index) {
                        final isCurrent = index == _currentPage;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                            _resetAutoSlideCooldown(banners.length);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isCurrent ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        );

        final Widget responsiveContainer = widget.height != null
            ? SizedBox(height: widget.height, child: carouselCard)
            : AspectRatio(aspectRatio: aspectRatio, child: carouselCard);

        return MouseRegion(
          onEnter: (_) {
            setState(() => _isUserInteracting = true);
            _autoSlideTimer?.cancel();
          },
          onExit: (_) {
            setState(() => _isUserInteracting = false);
            _resetAutoSlideCooldown(banners.length);
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 240),
              child: responsiveContainer,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlide(BuildContext context, BannerModel banner) {
    final hasImage = banner.resolvedImageUrl != null;
    final resolvedUrl = banner.resolvedImageUrl;
    final isLocalAsset = resolvedUrl != null && !resolvedUrl.startsWith('http') && !resolvedUrl.startsWith('/api');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleBannerClick(banner),
        mouseCursor: SystemMouseCursors.click,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage && resolvedUrl != null)
              isLocalAsset
                  ? Image.asset(
                      resolvedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackGradient(banner),
                    )
                  : Image.network(
                      resolvedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackGradient(banner),
                    )
            else
              _buildFallbackGradient(banner),

            // 2. Dark Gradient Scrim Overlay for contrast
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Category/Type Badge in top right
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: Text(
                  banner.isCelebration
                      ? (banner.celebrationType?.displayName ?? 'CELEBRATION')
                      : banner.category.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // 4. Content (Title, Subtitle, Action Indicator) - inset with safe horizontal padding so arrows never overlap
            Positioned(
              bottom: 22,
              left: 36,
              right: 36,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (banner.subtitle != null && banner.subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackGradient(BannerModel banner) {
    if (banner.isCelebration) {
      if (banner.isBirthday) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF5E62), Color(0xFFFF9966)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.cake_rounded, size: 54, color: Colors.white30),
          ),
        );
      }
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.military_tech_rounded, size: 54, color: Colors.white30),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.campaign_rounded, size: 54, color: Colors.white30),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232734) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
