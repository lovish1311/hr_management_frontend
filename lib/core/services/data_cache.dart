import 'dart:collection';

/// Entry containing cached data and expiration timestamp.
class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  const _CacheEntry({
    required this.data,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// In-memory Type-Safe TTL Cache Service for stable frontend data.
/// 
/// High-throughput, zero-dependency caching layer to eliminate redundant
/// HTTP round trips for consistent/historical datasets (e.g., holiday calendars,
/// employee directories, payroll histories).
/// 
/// Real-time/transient datasets (attendance status, leave balances, live counts)
/// MUST NOT be cached here.
class DataCache {
  static final DataCache instance = DataCache._();

  DataCache._();

  final Map<String, _CacheEntry> _cache = HashMap<String, _CacheEntry>();

  /// Retrieves cached item if present and non-expired.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    try {
      return entry.data as T;
    } catch (_) {
      _cache.remove(key);
      return null;
    }
  }

  /// Sets an item in cache with a defined Time-To-Live (TTL).
  void set<T>(String key, T data, Duration ttl) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// Explicitly invalidates an item by exact key.
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalidates all entries matching a specific prefix (e.g. 'employees_').
  void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clears the entire cache store.
  void clear() {
    _cache.clear();
  }

  /// Returns total number of active non-expired entries.
  int get activeCount {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
    return _cache.length;
  }
}
