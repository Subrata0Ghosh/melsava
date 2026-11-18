import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppUser> signInWithEmail({required String email, required String password});
  Future<AppUser> signUpWithEmail({required String email, required String password});
  Future<AppUser?> signInWithGoogle();
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
  Future<void> restoreSession();
  Future<void> updateProfile(AppUser updatedUser);
}

/// Unified Auth Repository supporting Email, Native Google Sign-In,
/// Supabase Auth, and session persistence across app launches.
class SupabaseAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _cachedUser;

  static Future<void>? _googleInitFuture;
  static bool _googleInitialized = false;

  SupabaseAuthRepository() {
    _initAuth();
  }

  AppUser _mapSupabaseUser(User user, {String? fallbackName, String? fallbackAvatar}) {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email ?? '';
    final displayName =
        (meta['display_name'] as String?) ??
        (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        fallbackName ??
        (email.isNotEmpty ? email.split('@').first : 'MELSAVA Member');
    final avatarUrl =
        (meta['avatar_url'] as String?) ??
        (meta['picture'] as String?) ??
        fallbackAvatar;

    return AppUser(
      id: user.id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      city: 'Mumbai',
      isEmailVerified: user.emailConfirmedAt != null || true,
      onboardingCompleted: true,
    );
  }

  Future<void> _persistUserLocally(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('melsava_user_id', user.id);
    await prefs.setString('melsava_user_email', user.email);
    if (user.displayName != null) {
      await prefs.setString('melsava_user_name', user.displayName!);
    }
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      await prefs.setString('melsava_user_avatar', user.avatarUrl!);
    }
    await prefs.setString('melsava_user_city', user.city ?? 'Mumbai');
  }

  Future<void> _initAuth() async {
    // 1. Check live Supabase session
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      final session = SupabaseService.client!.auth.currentSession;
      if (session != null) {
        _cachedUser = _mapSupabaseUser(session.user);
        _controller.add(_cachedUser);
      }

      SupabaseService.client!.auth.onAuthStateChange.listen((data) {
        final currentSession = data.session;
        if (currentSession != null) {
          _cachedUser = _mapSupabaseUser(currentSession.user);
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
          avatarUrl: prefs.getString('melsava_user_avatar') ?? 'assets/images/sneha_avatar.png',
          city: prefs.getString('melsava_user_city') ?? 'Mumbai',
          bio: prefs.getString('melsava_user_bio') ?? 'Nature lover | Coffee enthusiast | Explorer',
          primaryIntent: prefs.getString('melsava_user_intent') ?? 'Friend',
          isEmailVerified: true,
          onboardingCompleted: true,
        );
        _controller.add(_cachedUser);
      }
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleInitialized) return;
    _googleInitFuture ??= _initGoogleSignIn();
    try {
      await _googleInitFuture;
    } catch (_) {
      _googleInitFuture = null;
      rethrow;
    }
  }

  Future<void> _initGoogleSignIn() async {
    String webClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    String iosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

    if (dotenv.isInitialized) {
      webClientId = dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID') ?? webClientId;
      iosClientId = dotenv.maybeGet('GOOGLE_IOS_CLIENT_ID') ?? iosClientId;
    }

    if (webClientId.isEmpty || webClientId.contains('your-web-client-id')) {
      throw Exception(
        'Google Sign-In is not configured. Please set GOOGLE_WEB_CLIENT_ID in .env.',
      );
    }

    await GoogleSignIn.instance.initialize(
      clientId: iosClientId.isNotEmpty ? iosClientId : null,
      serverClientId: webClientId,
    );
    _googleInitialized = true;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null; // User cancelled picker
      }
      throw Exception(
        e.description ?? 'Google Sign-In failed (${e.code.name}).',
      );
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Could not obtain Google ID token. Verify GOOGLE_WEB_CLIENT_ID and Android SHA-1.',
      );
    }

    // Request optional access token without forcing an extra consent prompt
    String? accessToken;
    try {
      final authz = await googleUser.authorizationClient
          .authorizationForScopes(const ['email', 'profile']);
      accessToken = authz?.accessToken;
    } catch (_) {
      // Optional when authenticating with Supabase via ID token
    }

    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      final res = await SupabaseService.client!.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = res.user;
      if (user == null) {
        throw Exception('Google sign-in with Supabase failed.');
      }
      _cachedUser = _mapSupabaseUser(
        user,
        fallbackName: googleUser.displayName,
        fallbackAvatar: googleUser.photoUrl,
      );
    } else {
      _cachedUser = AppUser(
        id: 'google-${googleUser.id}',
        email: googleUser.email,
        displayName:
            googleUser.displayName ?? googleUser.email.split('@').first,
        avatarUrl: googleUser.photoUrl,
        city: 'Mumbai',
        isEmailVerified: true,
        onboardingCompleted: true,
      );
    }

    await _persistUserLocally(_cachedUser!);
    _controller.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<void> updateProfile(AppUser updatedUser) async {
    _cachedUser = updatedUser;
    final prefs = await SharedPreferences.getInstance();
    if (updatedUser.displayName != null) {
      await prefs.setString('melsava_user_name', updatedUser.displayName!);
    }
    if (updatedUser.city != null) {
      await prefs.setString('melsava_user_city', updatedUser.city!);
    }
    if (updatedUser.avatarUrl != null) {
      await prefs.setString('melsava_user_avatar', updatedUser.avatarUrl!);
    }
    if (updatedUser.bio != null) {
      await prefs.setString('melsava_user_bio', updatedUser.bio!);
    }
    if (updatedUser.primaryIntent != null) {
      await prefs.setString('melsava_user_intent', updatedUser.primaryIntent!);
    }
    _controller.add(_cachedUser);
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
      _cachedUser = _mapSupabaseUser(
        user,
        fallbackName: email.split('@').first,
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

    await _persistUserLocally(_cachedUser!);
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
      _cachedUser = _mapSupabaseUser(
        user,
        fallbackName: email.split('@').first,
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

    await _persistUserLocally(_cachedUser!);
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
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

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
    await prefs.remove('melsava_user_avatar');
    await prefs.remove('melsava_user_city');

    _cachedUser = null;
    _controller.add(null);
  }
}
