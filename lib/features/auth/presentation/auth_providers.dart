import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = SupabaseAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = StateProvider<AppUser?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  ref.listen<AsyncValue<AppUser?>>(authStateProvider, (_, next) {
    next.whenData((user) {
      ref.controller.state = user;
    });
  });
  return authRepo.currentUser;
});

final privacySettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final repo = ref.watch(authRepositoryProvider);
      return repo.getPrivacySettings();
    });
