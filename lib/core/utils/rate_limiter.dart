class RateLimiter {
  final int _maxAttempts;
  final Duration _window;
  final Map<String, List<DateTime>> _attempts = {};

  RateLimiter({int maxAttempts = 5, Duration? window})
      : _maxAttempts = maxAttempts,
        _window = window ?? const Duration(minutes: 1);

  bool isRateLimited(String key) {
    _cleanExpired(key);
    final attempts = _attempts[key] ?? [];
    return attempts.length >= _maxAttempts;
  }

  void recordAttempt(String key) {
    _attempts.putIfAbsent(key, () => []).add(DateTime.now());
    _cleanExpired(key);
  }

  int remainingAttempts(String key) {
    _cleanExpired(key);
    final attempts = _attempts[key] ?? [];
    return _maxAttempts - attempts.length;
  }

  void _cleanExpired(String key) {
    final now = DateTime.now();
    final cutoff = now.subtract(_window);
    _attempts[key]?.removeWhere((t) => t.isBefore(cutoff));
    if (_attempts[key]?.isEmpty ?? false) {
      _attempts.remove(key);
    }
  }

  void reset(String key) {
    _attempts.remove(key);
  }
}
