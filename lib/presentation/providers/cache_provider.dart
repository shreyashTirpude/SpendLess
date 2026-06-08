import 'package:flutter_riverpod/flutter_riverpod.dart';

// Single cache-version counter — increment to invalidate all derived providers
// at once instead of calling ref.invalidate on each one individually.
// This cuts re-render cascades from O(N providers) to O(1).
class _CacheNotifier extends StateNotifier<int> {
  _CacheNotifier() : super(0);
  void bump() => state = state + 1;
}

final transactionCacheProvider = StateNotifierProvider<_CacheNotifier, int>(
  (ref) => _CacheNotifier(),
);
