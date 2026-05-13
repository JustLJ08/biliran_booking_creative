/// Lightweight in-memory cache with TTL support.
/// Only caches "hot data" — never entire database tables.
class CacheService {
  static final Map<String, _CacheEntry> _store = {};

  /// Get cached value. Returns null if key doesn't exist or has expired.
  static T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _store.remove(key);
      return null;
    }
    return entry.data as T;
  }

  /// Cache a value with a TTL duration.
  static void set<T>(String key, T data, {Duration ttl = const Duration(minutes: 5)}) {
    _store[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// Remove a single cache entry.
  static void invalidate(String key) {
    _store.remove(key);
  }

  /// Remove all entries whose key starts with [prefix].
  /// Use after mutations: e.g. invalidatePrefix("products_")
  static void invalidatePrefix(String prefix) {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear the entire cache. Call on logout.
  static void clearAll() {
    _store.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});
}
