import 'dart:async';
import '../../../core/services/supabase_service.dart';
import '../domain/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppUser> signInWithEmail({required String email, required String password});
  Future<AppUser> signUpWithEmail({required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
}

/// Unified Auth Repository supporting both live Supabase and development mode
class SupabaseAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _cachedUser;

  SupabaseAuthRepository() {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      SupabaseService.client!.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          _cachedUser = AppUser(
            id: session.user.id,
            email: session.user.email ?? '',
            isEmailVerified: session.user.emailConfirmedAt != null,
            onboardingCompleted: true,
          );
        } else {
          _cachedUser = null;
        }
        _controller.add(_cachedUser);
      });
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      final res = await SupabaseService.client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Sign in failed');
      _cachedUser = AppUser(
        id: user.id,
        email: user.email ?? email,
        isEmailVerified: user.emailConfirmedAt != null,
        onboardingCompleted: true,
      );
      _controller.add(_cachedUser);
      return _cachedUser!;
    } else {
      // Local dev simulation
      await Future.delayed(const Duration(milliseconds: 600));
      _cachedUser = AppUser(
        id: 'dev-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        city: 'Mumbai',
        isEmailVerified: true,
        onboardingCompleted: true,
      );
      _controller.add(_cachedUser);
      return _cachedUser!;
    }
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      final res = await SupabaseService.client!.auth.signUp(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Sign up failed');
      _cachedUser = AppUser(
        id: user.id,
        email: user.email ?? email,
        isEmailVerified: user.emailConfirmedAt != null,
        onboardingCompleted: false,
      );
      _controller.add(_cachedUser);
      return _cachedUser!;
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      _cachedUser = AppUser(
        id: 'dev-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        city: 'Mumbai',
        isEmailVerified: true,
        onboardingCompleted: true,
      );
      _controller.add(_cachedUser);
      return _cachedUser!;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      await SupabaseService.client!.auth.resetPasswordForEmail(email);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Future<void> signOut() async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      await SupabaseService.client!.auth.signOut();
    }
    _cachedUser = null;
    _controller.add(null);
  }
}
