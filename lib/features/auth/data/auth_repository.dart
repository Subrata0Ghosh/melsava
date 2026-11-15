import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppUser> signInWithEmail({required String email, required String password});
  Future<AppUser> signUpWithEmail({required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
  Future<void> restoreSession();
}

/// Unified Auth Repository supporting session persistence across app launches
class SupabaseAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _cachedUser;

  SupabaseAuthRepository() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // 1. Check live Supabase session
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      final session = SupabaseService.client!.auth.currentSession;
      if (session != null) {
        _cachedUser = AppUser(
          id: session.user.id,
          email: session.user.email ?? '',
          displayName: session.user.userMetadata?['display_name'] ?? session.user.email?.split('@').first,
          isEmailVerified: session.user.emailConfirmedAt != null,
          onboardingCompleted: true,
        );
        _controller.add(_cachedUser);
      }

      SupabaseService.client!.auth.onAuthStateChange.listen((data) {
        final currentSession = data.session;
        if (currentSession != null) {
          _cachedUser = AppUser(
            id: currentSession.user.id,
            email: currentSession.user.email ?? '',
            displayName: currentSession.user.userMetadata?['display_name'] ?? currentSession.user.email?.split('@').first,
            isEmailVerified: currentSession.user.emailConfirmedAt != null,
            onboardingCompleted: true,
          );
        } else {
          _cachedUser = null;
        }
        _controller.add(_cachedUser);
      });
    }

    // 2. Check local persistence
    if (_cachedUser == null) {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('melsava_user_email');
      if (savedEmail != null) {
        _cachedUser = AppUser(
          id: prefs.getString('melsava_user_id') ?? 'user-saved',
          email: savedEmail,
          displayName: prefs.getString('melsava_user_name') ?? savedEmail.split('@').first,
          city: prefs.getString('melsava_user_city') ?? 'Mumbai',
          isEmailVerified: true,
          onboardingCompleted: true,
        );
        _controller.add(_cachedUser);
      }
    }
  }

  @override
  Future<void> restoreSession() async {
    await _initAuth();
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
        displayName: user.userMetadata?['display_name'] ?? email.split('@').first,
        city: 'Mumbai',
        isEmailVerified: user.emailConfirmedAt != null,
        onboardingCompleted: true,
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      _cachedUser = AppUser(
        id: 'user-${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
        city: 'Mumbai',
        isEmailVerified: true,
        onboardingCompleted: true,
      );
    }

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('melsava_user_id', _cachedUser!.id);
    await prefs.setString('melsava_user_email', _cachedUser!.email);
    if (_cachedUser!.displayName != null) {
      await prefs.setString('melsava_user_name', _cachedUser!.displayName!);
    }
    await prefs.setString('melsava_user_city', _cachedUser!.city ?? 'Mumbai');

    _controller.add(_cachedUser);
    return _cachedUser!;
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
        data: {'display_name': email.split('@').first},
      );
      final user = res.user;
      if (user == null) throw Exception('Sign up failed');
      _cachedUser = AppUser(
        id: user.id,
        email: user.email ?? email,
        displayName: email.split('@').first,
        city: 'Mumbai',
        isEmailVerified: user.emailConfirmedAt != null,
        onboardingCompleted: true,
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      _cachedUser = AppUser(
        id: 'user-${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
        city: 'Mumbai',
        isEmailVerified: true,
        onboardingCompleted: true,
      );
    }

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('melsava_user_id', _cachedUser!.id);
    await prefs.setString('melsava_user_email', _cachedUser!.email);
    if (_cachedUser!.displayName != null) {
      await prefs.setString('melsava_user_name', _cachedUser!.displayName!);
    }
    await prefs.setString('melsava_user_city', _cachedUser!.city ?? 'Mumbai');

    _controller.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      await SupabaseService.client!.auth.resetPasswordForEmail(email);
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  Future<void> signOut() async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.auth.signOut();
      } catch (_) {}
    }

    // Clear local persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('melsava_user_id');
    await prefs.remove('melsava_user_email');
    await prefs.remove('melsava_user_name');
    await prefs.remove('melsava_user_city');

    _cachedUser = null;
    _controller.add(null);
  }
}
