import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  String? get pendingVerificationEmail;
  bool get isDebugMockMode;

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<AppUser?> signInWithGoogle();
  Future<void> sendMagicLinkEmail({required String email});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> updatePassword({required String newPassword});
  Future<void> resendVerificationEmail({required String email});
  Future<AppUser?> refreshEmailVerificationStatus();
  Future<AppUser?> refreshCurrentUser();
  Future<AppUser?> debugVerifyEmailIfAllowed();
  Future<void> signOut();
  Future<void> deactivateAccount();
  Future<void> deleteAccountPermanent();
  Future<void> restoreSession();
  Future<void> updateProfile(AppUser updatedUser);
  Future<String?> uploadAvatar(dynamic file);
  Future<Map<String, dynamic>> getPrivacySettings();
  Future<void> updatePrivacySettings(Map<String, dynamic> settings);
  void syncCachedUser(AppUser user);
}

/// Unified Auth Repository backed by Supabase Auth & PostgreSQL (`profiles` + `profile_private`).
///
/// - Uses the live Supabase session as the single source of authentication truth.
/// - Never restores a fake authenticated user from SharedPreferences.
/// - Mock fallback is strictly restricted to `kDebugMode` when Supabase is unconfigured,
///   and will never authenticate users in release builds.
class SupabaseAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _cachedUser;
  String? _pendingVerificationEmail;
  StreamSubscription<AuthState>? _authSubscription;
  bool _listenerAttached = false;

  static Future<void>? _googleInitFuture;
  static bool _googleInitialized = false;

  SupabaseAuthRepository() {
    _attachSupabaseListener();
  }

  bool get _hasLiveSupabase =>
      SupabaseService.isConfigured && SupabaseService.client != null;

  @override
  bool get isDebugMockMode => kDebugMode && !_hasLiveSupabase;

  @override
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _cachedUser;

  void _ensureBackendAvailable() {
    if (!_hasLiveSupabase && !kDebugMode) {
      throw Exception(
        'Authentication service is not configured. Please provide valid Supabase credentials.',
      );
    }
  }

  void _attachSupabaseListener() {
    if (_listenerAttached || !_hasLiveSupabase) return;
    _listenerAttached = true;

    _authSubscription = SupabaseService.client!.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      if (session == null) {
        _cachedUser = null;
        _controller.add(null);
      } else {
        final hydrated = await _hydrateUserFromSupabase(session.user);
        _cachedUser = hydrated;
        if (hydrated.isEmailVerified) {
          _pendingVerificationEmail = null;
        }
        _controller.add(_cachedUser);
      }
    });
  }

  /// Hydrates real profile completion, age verification, interests & intentions
  /// from `public.profiles` and `public.profile_private` without exposing `date_of_birth`.
  Future<AppUser> _hydrateUserFromSupabase(
    User user, {
    String? fallbackName,
    String? fallbackAvatar,
  }) async {
    final client = SupabaseService.client!;
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email ?? '';

    String? displayName =
        (meta['display_name'] as String?) ??
        (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        fallbackName;
    String? avatarUrl =
        (meta['avatar_url'] as String?) ??
        (meta['picture'] as String?) ??
        fallbackAvatar;
    String? city;
    String? bio;
    bool onboardingCompleted = false;
    bool ageVerified = false;
    bool isVerified = false;
    bool isSuspended = false;
    bool guidelinesAccepted = false;
    List<String> preferredActivityCategories = const [];
    List<String> availability = const [];
    int minAge = 21;
    int maxAge = 40;
    int maxDistanceKm = 25;
    String discoveryFormat = 'Both';
    List<String> interests = const [];
    String? primaryIntent;
    List<String> secondaryIntents = const [];

    // 1. Read public.profiles row
    try {
      final profileRow = await client
          .from('profiles')
          .select(
            'display_name, avatar_url, bio, city, onboarding_completed, is_verified, is_suspended',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow != null) {
        final dbName = profileRow['display_name'] as String?;
        if (dbName != null &&
            dbName.trim().isNotEmpty &&
            dbName != 'New User') {
          displayName = dbName;
        }
        avatarUrl = (profileRow['avatar_url'] as String?) ?? avatarUrl;
        bio = profileRow['bio'] as String?;
        city = profileRow['city'] as String?;
        onboardingCompleted =
            (profileRow['onboarding_completed'] as bool?) ?? false;
        isVerified = (profileRow['is_verified'] as bool?) ?? false;
        isSuspended = (profileRow['is_suspended'] as bool?) ?? false;
      }
    } catch (e) {
      debugPrint('[SupabaseAuthRepository] Failed to fetch profiles: $e');
    }

    // 2. Read private verification & preference flags (never expose date_of_birth)
    try {
      final privateRow = await client
          .from('profile_private')
          .select('age_verified, guidelines_accepted_at, terms_accepted_at')
          .eq('user_id', user.id)
          .maybeSingle();

      if (privateRow != null) {
        ageVerified = (privateRow['age_verified'] as bool?) ?? false;
        guidelinesAccepted = privateRow['guidelines_accepted_at'] != null;
      }
    } catch (e) {
      debugPrint(
        '[SupabaseAuthRepository] Failed to fetch profile_private: $e',
      );
    }

    // 2b. Optional extended preference columns from migration 005
    try {
      final prefRow = await client
          .from('profile_private')
          .select(
            'preferred_activity_categories, availability_preferences, discovery_preferences',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      if (prefRow != null) {
        final rawCats = prefRow['preferred_activity_categories'];
        if (rawCats is List) {
          preferredActivityCategories = rawCats
              .map((e) => e.toString())
              .toList();
        }
        final rawAvail = prefRow['availability_preferences'];
        if (rawAvail is List) {
          availability = rawAvail.map((e) => e.toString()).toList();
        }
        final rawDisc = prefRow['discovery_preferences'];
        if (rawDisc is Map) {
          minAge = (rawDisc['min_age'] as num?)?.toInt() ?? minAge;
          maxAge = (rawDisc['max_age'] as num?)?.toInt() ?? maxAge;
          maxDistanceKm =
              (rawDisc['max_distance_km'] as num?)?.toInt() ?? maxDistanceKm;
          discoveryFormat = (rawDisc['format'] as String?) ?? discoveryFormat;
        }
      }
    } catch (_) {
      // Fallback to userMetadata if migration 005 columns are not yet applied
      final metaCats = meta['preferred_activity_categories'];
      if (metaCats is List) {
        preferredActivityCategories = metaCats
            .map((e) => e.toString())
            .toList();
      }
      final metaAvail = meta['availability_preferences'];
      if (metaAvail is List) {
        availability = metaAvail.map((e) => e.toString()).toList();
      }
      final metaDisc = meta['discovery_preferences'];
      if (metaDisc is Map) {
        minAge = (metaDisc['min_age'] as num?)?.toInt() ?? minAge;
        maxAge = (metaDisc['max_age'] as num?)?.toInt() ?? maxAge;
        maxDistanceKm =
            (metaDisc['max_distance_km'] as num?)?.toInt() ?? maxDistanceKm;
        discoveryFormat = (metaDisc['format'] as String?) ?? discoveryFormat;
      }
    }

    // 3. Read selected interests
    try {
      final interestRows = await client
          .from('profile_interests')
          .select('interests(name)')
          .eq('profile_id', user.id);

      interests = (interestRows as List)
          .map((row) {
            final nested = row['interests'];
            if (nested is Map) return nested['name']?.toString();
            return null;
          })
          .whereType<String>()
          .toList();
    } catch (_) {}

    // 4. Read selected intentions
    try {
      final intentionRows = await client
          .from('profile_intentions')
          .select('is_primary, intentions(name)')
          .eq('profile_id', user.id);

      final others = <String>[];
      for (final row in (intentionRows as List)) {
        final nested = row['intentions'];
        final name = nested is Map ? nested['name']?.toString() : null;
        if (name == null) continue;
        if (row['is_primary'] == true) {
          primaryIntent = name;
        } else {
          others.add(name);
        }
      }
      secondaryIntents = others;
    } catch (_) {}

    // OAuth providers (like Google) confirm email automatically
    final isOAuth =
        user.appMetadata['provider'] == 'google' ||
        (user.identities?.any((id) => id.provider == 'google') ?? false);
    final isEmailVerified = user.emailConfirmedAt != null || isOAuth;

    return AppUser(
      id: user.id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      city: city,
      bio: bio,
      primaryIntent: primaryIntent,
      secondaryIntents: secondaryIntents,
      interests: interests,
      preferredActivityCategories: preferredActivityCategories,
      availability: availability,
      discoveryMinAge: minAge,
      discoveryMaxAge: maxAge,
      discoveryMaxDistanceKm: maxDistanceKm,
      discoveryFormat: discoveryFormat,
      isEmailVerified: isEmailVerified,
      ageVerified: ageVerified,
      isVerified: isVerified,
      isSuspended: isSuspended,
      guidelinesAccepted: guidelinesAccepted,
      onboardingCompleted: onboardingCompleted,
    );
  }

  @override
  Future<void> restoreSession() async {
    _attachSupabaseListener();

    // Always use actual Supabase session as source of authentication truth.
    // Never restore a fake authenticated user from SharedPreferences.
    if (_hasLiveSupabase) {
      final session = SupabaseService.client!.auth.currentSession;
      if (session == null) {
        _cachedUser = null;
        _controller.add(null);
        return;
      }

      try {
        final userResponse = await SupabaseService.client!.auth.getUser();
        final activeUser = userResponse.user ?? session.user;
        _cachedUser = await _hydrateUserFromSupabase(activeUser);
        _controller.add(_cachedUser);
      } catch (_) {
        // Session expired or invalid on server — treat as unauthenticated
        _cachedUser = null;
        _controller.add(null);
      }
      return;
    }

    // Without live Supabase, do not fabricate a persisted session.
    _controller.add(_cachedUser);
  }

  @override
  Future<AppUser?> refreshCurrentUser() async {
    if (_hasLiveSupabase) {
      final session = SupabaseService.client!.auth.currentSession;
      if (session == null) {
        _cachedUser = null;
        _controller.add(null);
        return null;
      }
      final userRes = await SupabaseService.client!.auth.getUser();
      final user = userRes.user ?? session.user;
      _cachedUser = await _hydrateUserFromSupabase(user);
      _controller.add(_cachedUser);
      return _cachedUser;
    }
    return _cachedUser;
  }

  @override
  void syncCachedUser(AppUser user) {
    _cachedUser = user;
    _controller.add(_cachedUser);
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
    _ensureBackendAvailable();
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
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

    String? accessToken;
    try {
      final authz = await googleUser.authorizationClient.authorizationForScopes(
        const ['email', 'profile'],
      );
      accessToken = authz?.accessToken;
    } catch (_) {
      // Optional when authenticating with Supabase via ID token
    }

    if (_hasLiveSupabase) {
      final res = await SupabaseService.client!.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = res.user;
      if (user == null) {
        throw Exception('Google sign-in with Supabase failed.');
      }
      _cachedUser = await _hydrateUserFromSupabase(
        user,
        fallbackName: googleUser.displayName,
        fallbackAvatar: googleUser.photoUrl,
      );
    } else if (isDebugMockMode) {
      _cachedUser = AppUser(
        id: 'debug-google-${googleUser.id}',
        email: googleUser.email,
        displayName:
            googleUser.displayName ?? googleUser.email.split('@').first,
        avatarUrl: googleUser.photoUrl,
        isEmailVerified: true,
        ageVerified: false,
        onboardingCompleted: false,
      );
    }

    _pendingVerificationEmail = null;
    _controller.add(_cachedUser);
    return _cachedUser;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureBackendAvailable();

    if (_hasLiveSupabase) {
      final res = await SupabaseService.client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Sign in failed. Please try again.');
      _cachedUser = await _hydrateUserFromSupabase(
        user,
        fallbackName: email.split('@').first,
      );
      if (!_cachedUser!.isEmailVerified) {
        _pendingVerificationEmail = email;
      } else {
        _pendingVerificationEmail = null;
      }
    } else if (isDebugMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
      _cachedUser = AppUser(
        id: 'debug-user-${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
        isEmailVerified: true,
        ageVerified: false,
        onboardingCompleted: false,
      );
    } else {
      throw Exception('Authentication service unavailable in release mode.');
    }

    _controller.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureBackendAvailable();

    if (_hasLiveSupabase) {
      final res = await SupabaseService.client!.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': email.split('@').first},
      );
      final user = res.user;
      if (user == null) {
        throw Exception('Could not create account. Please try again.');
      }

      final isVerified = user.emailConfirmedAt != null;
      if (res.session != null) {
        _cachedUser = await _hydrateUserFromSupabase(
          user,
          fallbackName: email.split('@').first,
        );
      } else {
        // Supabase requires email confirmation before issuing a session
        _cachedUser = AppUser(
          id: user.id,
          email: user.email ?? email,
          displayName: email.split('@').first,
          isEmailVerified: isVerified,
          ageVerified: false,
          onboardingCompleted: false,
        );
      }

      _pendingVerificationEmail = isVerified ? null : email;
    } else if (isDebugMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
      _cachedUser = AppUser(
        id: 'debug-user-${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
        isEmailVerified: false, // Never silently bypass email verification
        ageVerified: false,
        onboardingCompleted: false,
      );
      _pendingVerificationEmail = email;
    } else {
      throw Exception('Authentication service unavailable in release mode.');
    }

    _controller.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<void> sendMagicLinkEmail({required String email}) async {
    _ensureBackendAvailable();

    if (_hasLiveSupabase) {
      await SupabaseService.client!.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'melsava://auth-callback',
      );
    } else if (isDebugMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    _ensureBackendAvailable();

    if (_hasLiveSupabase) {
      await SupabaseService.client!.auth.resetPasswordForEmail(
        email,
        redirectTo: 'melsava://reset-password',
      );
    } else if (isDebugMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    _ensureBackendAvailable();

    if (_hasLiveSupabase) {
      await SupabaseService.client!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } else if (isDebugMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    _ensureBackendAvailable();

    if (_hasLiveSupabase) {
      await SupabaseService.client!.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } else if (isDebugMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Future<AppUser?> refreshEmailVerificationStatus() async {
    _ensureBackendAvailable();

    if (_hasLiveSupabase) {
      final client = SupabaseService.client!;
      final session = client.auth.currentSession;
      if (session == null) {
        return _cachedUser;
      }

      try {
        await client.auth.refreshSession();
      } catch (_) {
        // Proceed to check getUser() even if refreshSession did not rotate
      }

      final userRes = await client.auth.getUser();
      final user = userRes.user;
      if (user == null) return _cachedUser;

      _cachedUser = await _hydrateUserFromSupabase(user);
      if (_cachedUser!.isEmailVerified) {
        _pendingVerificationEmail = null;
      }
      _controller.add(_cachedUser);
      return _cachedUser;
    }

    // In debug mock mode, do not silently auto-verify without explicit user action
    return _cachedUser;
  }

  @override
  Future<AppUser?> debugVerifyEmailIfAllowed() async {
    if (!isDebugMockMode || _cachedUser == null) {
      return null;
    }
    _cachedUser = _cachedUser!.copyWith(isEmailVerified: true);
    _pendingVerificationEmail = null;
    _controller.add(_cachedUser);
    return _cachedUser;
  }

  @override
  Future<void> updateProfile(AppUser updatedUser) async {
    _ensureBackendAvailable();
    if (_hasLiveSupabase) {
      // Validate and persist atomically via update_user_profile RPC only.
      // Direct-table fallback removed to prevent partial updates and data corruption.
      await SupabaseService.client!.rpc(
        'update_user_profile',
        params: {
          'p_display_name': updatedUser.displayName ?? '',
          'p_avatar_url': updatedUser.avatarUrl ?? '',
          'p_bio': updatedUser.bio ?? '',
          'p_city': updatedUser.city ?? '',
          'p_interests': updatedUser.interests ?? <String>[],
          'p_primary_intent': updatedUser.primaryIntent ?? '',
          'p_secondary_intents': updatedUser.secondaryIntents,
          'p_preferred_categories': updatedUser.preferredActivityCategories,
          'p_discovery_preferences': {
            'min_age': updatedUser.discoveryMinAge,
            'max_age': updatedUser.discoveryMaxAge,
            'max_distance_km': updatedUser.discoveryMaxDistanceKm,
            'format': updatedUser.discoveryFormat,
          },
        },
      );
    }

    _cachedUser = updatedUser;
    _controller.add(_cachedUser);
  }

  @override
  Future<Map<String, dynamic>> getPrivacySettings() async {
    if (!_hasLiveSupabase) {
      return const {
        'public_radar': true,
        'ghost_mode': false,
        'show_city': true,
      };
    }
    try {
      final res = await SupabaseService.client!.rpc('get_privacy_settings');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return const {
        'public_radar': true,
        'ghost_mode': false,
        'show_city': true,
      };
    } catch (e) {
      debugPrint('[SupabaseAuthRepository] getPrivacySettings error: $e');
      return const {
        'public_radar': true,
        'ghost_mode': false,
        'show_city': true,
      };
    }
  }

  @override
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    _ensureBackendAvailable();
    if (_hasLiveSupabase) {
      await SupabaseService.client!.rpc(
        'update_privacy_settings',
        params: {'p_settings': settings},
      );
    }
  }

  @override
  Future<String?> uploadAvatar(dynamic file) async {
    if (!_hasLiveSupabase) return null;
    final user = _cachedUser ?? currentUser;
    if (user == null) {
      throw Exception('Authentication required to upload avatar.');
    }

    Uint8List bytes;
    String extension = 'jpg';

    if (file is Uint8List) {
      bytes = file;
    } else if (file != null) {
      try {
        bytes = await (file as dynamic).readAsBytes();
        final path = (file as dynamic).path?.toString() ?? '';
        if (path.toLowerCase().endsWith('.png')) {
          extension = 'png';
        } else if (path.toLowerCase().endsWith('.webp')) {
          extension = 'webp';
        }
      } catch (e) {
        throw Exception('Failed to read image bytes: $e');
      }
    } else {
      throw Exception('Invalid image file.');
    }

    final fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = '${user.id}/$fileName';

    try {
      await SupabaseService.client!.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: true,
            ),
          );

      final publicUrl = SupabaseService.client!.storage
          .from('avatars')
          .getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseAuthRepository] uploadAvatar error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    if (_hasLiveSupabase) {
      try {
        await SupabaseService.client!.auth.signOut();
      } catch (_) {}
    }

    _cachedUser = null;
    _pendingVerificationEmail = null;
    _controller.add(null);
  }

  @override
  Future<void> deactivateAccount() async {
    _ensureBackendAvailable();
    if (_hasLiveSupabase) {
      // Must succeed via deactivate_user_account RPC; do not swallow error or fallback
      await SupabaseService.client!.rpc('deactivate_user_account');
    }
    // Only sign out on confirmed deactivation
    await signOut();
  }

  @override
  Future<void> deleteAccountPermanent() async {
    _ensureBackendAvailable();
    if (_hasLiveSupabase) {
      // Single permanent deletion mechanism: Supabase Edge Function 'delete-account'
      final res = await SupabaseService.client!.functions.invoke(
        'delete-account',
        body: {'confirmation': 'DELETE'},
      );

      if (res.status != 200) {
        final err = res.data?['error']?.toString() ?? 'Status: ${res.status}';
        throw Exception(err);
      }
    }

    // Only sign out after confirmed permanent server deletion
    await signOut();
  }

  void dispose() {
    _authSubscription?.cancel();
    _controller.close();
  }
}
