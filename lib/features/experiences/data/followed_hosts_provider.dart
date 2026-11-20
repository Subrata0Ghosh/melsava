import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FollowedHostsNotifier extends StateNotifier<Set<String>> {
  FollowedHostsNotifier() : super(<String>{}) {
    _load();
  }

  static const _storageKey = 'melsava_followed_hosts';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      state = list.toSet();
    } catch (_) {}
  }

  Future<bool> toggleFollow(String hostIdentifier) async {
    final trimmed = hostIdentifier.trim();
    if (trimmed.isEmpty) return false;
    final newState = Set<String>.from(state);
    final isFollowing = newState.contains(trimmed);
    if (isFollowing) {
      newState.remove(trimmed);
    } else {
      newState.add(trimmed);
    }
    state = newState;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, newState.toList());
    } catch (_) {}
    return !isFollowing; // true = now following, false = unfollowed
  }

  bool isFollowing(String? hostIdentifier) {
    if (hostIdentifier == null || hostIdentifier.trim().isEmpty) return false;
    return state.contains(hostIdentifier.trim());
  }
}

final followedHostsProvider =
    StateNotifierProvider<FollowedHostsNotifier, Set<String>>((ref) {
  return FollowedHostsNotifier();
});
