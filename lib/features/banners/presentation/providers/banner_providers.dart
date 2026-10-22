import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';
import 'package:hr_management/features/banners/data/services/banner_api_service.dart';

/// Singleton API service provider
final bannerApiServiceProvider = Provider<BannerApiService>((ref) {
  return const BannerApiService();
});

/// Dashboard carousel active banners provider
final activeBannersProvider = FutureProvider.autoDispose<List<BannerModel>>((ref) async {
  final api = ref.watch(bannerApiServiceProvider);
  return api.getActiveBanners();
});

/// Key helper to serialize tab and filter parameters for Riverpod family
String buildEngageFeedKey(BannerType? tab, CelebrationType? filter) {
  final t = tab?.toServerString() ?? 'ALL';
  final f = filter?.toServerString() ?? 'ALL';
  return '$t:$f';
}

/// Engage Social Hub feed notifier with optimistic reactions and server reconciliation
class EngageFeedNotifier extends AsyncNotifier<List<BannerModel>> {
  EngageFeedNotifier(this.arg);
  final String arg;

  @override
  Future<List<BannerModel>> build() async {
    final parts = arg.split(':');
    final tabStr = parts.isNotEmpty ? parts[0] : 'ALL';
    final filterStr = parts.length > 1 ? parts[1] : 'ALL';

    final tab = tabStr != 'ALL' ? BannerType.fromString(tabStr) : null;
    final filter = filterStr != 'ALL' ? CelebrationType.fromString(filterStr) : null;

    final api = ref.read(bannerApiServiceProvider);
    return api.getEngageFeed(tab: tab, filter: filter);
  }

  /// Optimistically updates emoji reaction counts and reconciles with server response
  Future<void> toggleReaction(int bannerId, String reactionType) async {
    final currentState = state.value;
    if (currentState == null) return;

    final bannerIndex = currentState.indexWhere((b) => b.id == bannerId);
    if (bannerIndex == -1) return;

    final targetBanner = currentState[bannerIndex];
    final wasReacted = targetBanner.userReactions.contains(reactionType);

    // 1. Calculate optimistic delta
    final newCounts = Map<String, int>.from(targetBanner.reactionCounts);
    final newUserReactions = Set<String>.from(targetBanner.userReactions);
    final currentCount = newCounts[reactionType] ?? 0;

    int newTotal = targetBanner.totalReactions;
    if (wasReacted) {
      newCounts[reactionType] = (currentCount > 0) ? currentCount - 1 : 0;
      newUserReactions.remove(reactionType);
      newTotal = (newTotal > 0) ? newTotal - 1 : 0;
    } else {
      newCounts[reactionType] = currentCount + 1;
      newUserReactions.add(reactionType);
      newTotal = newTotal + 1;
    }

    final optimisticBanner = targetBanner.copyWith(
      reactionCounts: newCounts,
      userReactions: newUserReactions,
      totalReactions: newTotal,
    );

    final updatedList = List<BannerModel>.from(currentState);
    updatedList[bannerIndex] = optimisticBanner;
    state = AsyncData(updatedList);

    // 2. Perform server mutation with explicit action for network retry idempotency
    try {
      final action = wasReacted ? 'REMOVE' : 'ADD';
      final summary = await ref.read(bannerApiServiceProvider).toggleReaction(
        bannerId,
        reactionType,
        action: action,
      );

      // 3. Reconcile with authoritative server counts
      final serverBanner = targetBanner.copyWith(
        reactionCounts: summary.reactionCounts,
        userReactions: summary.userReactions,
        totalReactions: summary.totalReactions,
      );

      final latestList = List<BannerModel>.from(state.value ?? updatedList);
      final idx = latestList.indexWhere((b) => b.id == bannerId);
      if (idx != -1) {
        latestList[idx] = serverBanner;
        state = AsyncData(latestList);
      }
    } catch (err, st) {
      // Rollback on network error
      final rollbackList = List<BannerModel>.from(state.value ?? currentState);
      final idx = rollbackList.indexWhere((b) => b.id == bannerId);
      if (idx != -1) {
        rollbackList[idx] = targetBanner;
        state = AsyncData(rollbackList);
      }
      state = AsyncError(err, st);
    }
  }

  /// Manually trigger a refresh
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// Optimistically deletes a banner from the feed and invokes server deletion
  Future<void> deleteBanner(int bannerId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final bannerIndex = currentState.indexWhere((b) => b.id == bannerId);
    if (bannerIndex == -1) return;
    final targetBanner = currentState[bannerIndex];

    // Optimistically remove from state
    final updatedList = List<BannerModel>.from(currentState)..removeAt(bannerIndex);
    state = AsyncData(updatedList);

    try {
      await ref.read(bannerApiServiceProvider).deleteBanner(bannerId);
      ref.invalidate(activeBannersProvider);
    } catch (err, st) {
      // Rollback on error
      final rollbackList = List<BannerModel>.from(state.value ?? updatedList);
      rollbackList.insert(bannerIndex, targetBanner);
      state = AsyncData(rollbackList);
      state = AsyncError(err, st);
      rethrow;
    }
  }
}

final engageFeedProvider =
    AsyncNotifierProvider.autoDispose.family<EngageFeedNotifier, List<BannerModel>, String>(
  EngageFeedNotifier.new,
);

/// Provider for unique corporate departments
final bannerDepartmentsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final api = ref.watch(bannerApiServiceProvider);
  return api.getDepartments();
});

/// Admin Management Console state notifier
class ManageBannersNotifier extends AsyncNotifier<List<BannerModel>> {
  @override
  Future<List<BannerModel>> build() async {
    ref.keepAlive();
    final api = ref.read(bannerApiServiceProvider);
    return api.getAllBannersForManagement();
  }

  Future<void> createBanner(Map<String, dynamic> payload) async {
    final api = ref.read(bannerApiServiceProvider);
    await api.createBanner(payload);
    if (!ref.mounted) return;
    ref.invalidate(activeBannersProvider);
    state = await AsyncValue.guard(() => api.getAllBannersForManagement());
  }

  Future<void> updateBanner(int id, Map<String, dynamic> payload) async {
    final api = ref.read(bannerApiServiceProvider);
    await api.updateBanner(id, payload);
    if (!ref.mounted) return;
    ref.invalidate(activeBannersProvider);
    state = await AsyncValue.guard(() => api.getAllBannersForManagement());
  }

  Future<void> toggleStatus(int id) async {
    final api = ref.read(bannerApiServiceProvider);
    await api.toggleBannerStatus(id);
    if (!ref.mounted) return;
    ref.invalidate(activeBannersProvider);
    state = await AsyncValue.guard(() => api.getAllBannersForManagement());
  }

  Future<void> deleteBanner(int id) async {
    final api = ref.read(bannerApiServiceProvider);
    await api.deleteBanner(id);
    if (!ref.mounted) return;
    ref.invalidate(activeBannersProvider);
    state = await AsyncValue.guard(() => api.getAllBannersForManagement());
  }
}

final manageBannersProvider =
    AsyncNotifierProvider<ManageBannersNotifier, List<BannerModel>>(
  ManageBannersNotifier.new,
);
