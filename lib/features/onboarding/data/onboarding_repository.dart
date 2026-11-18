import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/auth_validators.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../domain/onboarding_models.dart';

abstract class OnboardingRepository {
  Future<AppUser> saveAdultEligibility({
    required AppUser currentUser,
    required DateTime dateOfBirth,
  });

  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
    String? localFallbackPath,
  });

  Future<OnboardingReferenceData> fetchReferenceOptions();

  Future<AppUser> completeProfileOnboarding({
    required AppUser currentUser,
    required OnboardingProfileDraft draft,
  });
}

class SupabaseOnboardingRepository implements OnboardingRepository {
  final AuthRepository _authRepository;

  SupabaseOnboardingRepository(this._authRepository);

  bool get _hasLiveSupabase =>
      SupabaseService.isConfigured && SupabaseService.client != null;

  bool get _isDebugMockAllowed => kDebugMode && !_hasLiveSupabase;

  void _ensureBackendAvailable() {
    if (!_hasLiveSupabase && !kDebugMode) {
      throw Exception(
        'Backend service is not configured. Please check Supabase environment settings.',
      );
    }
  }

  /// Seeded reference fallback matching `supabase/migrations/004_seed_data.sql`.
  static const List<OnboardingOption> defaultInterests = [
    OnboardingOption(name: 'Travel', category: 'lifestyle'),
    OnboardingOption(name: 'Cooking', category: 'food'),
    OnboardingOption(name: 'Reading', category: 'culture'),
    OnboardingOption(name: 'Fitness', category: 'sports'),
    OnboardingOption(name: 'Music', category: 'arts'),
    OnboardingOption(name: 'Photography', category: 'arts'),
    OnboardingOption(name: 'Hiking', category: 'outdoors'),
    OnboardingOption(name: 'Movies', category: 'entertainment'),
    OnboardingOption(name: 'Gaming', category: 'entertainment'),
    OnboardingOption(name: 'Yoga', category: 'wellness'),
    OnboardingOption(name: 'Dancing', category: 'arts'),
    OnboardingOption(name: 'Art', category: 'arts'),
    OnboardingOption(name: 'Technology', category: 'tech'),
    OnboardingOption(name: 'Volunteering', category: 'social'),
    OnboardingOption(name: 'Meditation', category: 'wellness'),
    OnboardingOption(name: 'Languages', category: 'culture'),
    OnboardingOption(name: 'Gardening', category: 'outdoors'),
    OnboardingOption(name: 'Coffee', category: 'food'),
  ];

  static const List<OnboardingOption> defaultIntentions = [
    OnboardingOption(
      name: 'Genuine friendship',
      description: 'Looking for authentic, lasting friendships',
      category: 'friendship',
    ),
    OnboardingOption(
      name: 'Activity partner',
      description: 'Seeking someone to share hobbies and activities with',
      category: 'friendship',
    ),
    OnboardingOption(
      name: 'Casual dating',
      description: 'Open to casual, low-pressure dating experiences',
      category: 'dating',
    ),
    OnboardingOption(
      name: 'Meaningful dating',
      description: 'Looking for deeper, more intentional dating connections',
      category: 'dating',
    ),
    OnboardingOption(
      name: 'Serious relationship',
      description: 'Seeking a committed, long-term relationship',
      category: 'dating',
    ),
    OnboardingOption(
      name: 'Marriage-minded',
      description: 'Looking for a life partner with marriage in mind',
      category: 'dating',
    ),
    OnboardingOption(
      name: 'Open to discovering',
      description:
          'No fixed expectations — open to whatever develops naturally',
      category: 'friendship',
    ),
  ];

  static const List<OnboardingOption> defaultActivityCategories = [
    OnboardingOption(name: 'Coffee & Conversation'),
    OnboardingOption(name: 'Board Games'),
    OnboardingOption(name: 'Nature Walks'),
    OnboardingOption(name: 'Sports & Fitness'),
    OnboardingOption(name: 'Photography'),
    OnboardingOption(name: 'Music'),
    OnboardingOption(name: 'Art & Creative Workshops'),
    OnboardingOption(name: 'Food Experiences'),
    OnboardingOption(name: 'Reading & Book Clubs'),
    OnboardingOption(name: 'Volunteering'),
    OnboardingOption(name: 'Learning & Skill-sharing'),
    OnboardingOption(name: 'Cultural Activities'),
  ];

  @override
  Future<AppUser> saveAdultEligibility({
    required AppUser currentUser,
    required DateTime dateOfBirth,
  }) async {
    _ensureBackendAvailable();

    if (!AuthValidators.isAdult(dateOfBirth)) {
      throw const UnderageUserException();
    }

    final isoDob = AuthValidators.formatIsoDate(dateOfBirth);

    if (_hasLiveSupabase) {
      final client = SupabaseService.client!;

      // Ensure parent profile row exists (handles users created before trigger was installed)
      final safeName =
          (currentUser.displayName != null &&
              currentUser.displayName!.trim().length >= 2)
          ? currentUser.displayName!.trim()
          : 'MELSAVA Member';

      await client
          .from('profiles')
          .upsert(
            {
              'id': currentUser.id,
              'display_name': safeName.length > 50
                  ? safeName.substring(0, 50)
                  : safeName,
            },
            onConflict: 'id',
            ignoreDuplicates: true,
          );

      // Save DOB strictly inside `profile_private` (protected by own-user RLS; never public)
      await client.from('profile_private').upsert({
        'user_id': currentUser.id,
        'email': currentUser.email,
        'date_of_birth': isoDob,
        'age_verified': true,
      }, onConflict: 'user_id');
    } else if (_isDebugMockAllowed) {
      await Future.delayed(const Duration(milliseconds: 250));
    }

    final updated = currentUser.copyWith(ageVerified: true);
    _authRepository.syncCachedUser(updated);
    return updated;
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
    String? localFallbackPath,
  }) async {
    _ensureBackendAvailable();

    final normalizedExt = fileExtension.toLowerCase().replaceAll('.', '');
    final ext = (normalizedExt == 'png' || normalizedExt == 'webp')
        ? normalizedExt
        : 'jpg';
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    if (_hasLiveSupabase) {
      final client = SupabaseService.client!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/avatar_$timestamp.$ext';

      await client.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
              cacheControl: '3600',
            ),
          );

      return client.storage.from('avatars').getPublicUrl(storagePath);
    }

    if (_isDebugMockAllowed) {
      await Future.delayed(const Duration(milliseconds: 250));
      return localFallbackPath ?? 'assets/images/sneha_avatar.png';
    }

    throw Exception('Photo upload service is unavailable.');
  }

  @override
  Future<OnboardingReferenceData> fetchReferenceOptions() async {
    if (!_hasLiveSupabase) {
      return const OnboardingReferenceData(
        interests: defaultInterests,
        intentions: defaultIntentions,
        activityCategories: defaultActivityCategories,
      );
    }

    final client = SupabaseService.client!;
    List<OnboardingOption> interests = defaultInterests;
    List<OnboardingOption> intentions = defaultIntentions;
    List<OnboardingOption> categories = defaultActivityCategories;

    try {
      final rows = await client
          .from('interests')
          .select('id, name, category')
          .order('name');
      final parsed = (rows as List)
          .map(
            (r) => OnboardingOption(
              id: r['id']?.toString(),
              name: r['name']?.toString() ?? '',
              category: r['category']?.toString(),
            ),
          )
          .where((o) => o.name.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) interests = parsed;
    } catch (e) {
      debugPrint('[OnboardingRepository] Using fallback interests: $e');
    }

    try {
      final rows = await client
          .from('intentions')
          .select('id, name, description, category');
      final parsed = (rows as List)
          .map(
            (r) => OnboardingOption(
              id: r['id']?.toString(),
              name: r['name']?.toString() ?? '',
              description: r['description']?.toString(),
              category: r['category']?.toString(),
            ),
          )
          .where((o) => o.name.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) intentions = parsed;
    } catch (e) {
      debugPrint('[OnboardingRepository] Using fallback intentions: $e');
    }

    try {
      final rows = await client
          .from('activity_categories')
          .select('id, name, description')
          .order('display_order');
      final parsed = (rows as List)
          .map(
            (r) => OnboardingOption(
              id: r['id']?.toString(),
              name: r['name']?.toString() ?? '',
              description: r['description']?.toString(),
            ),
          )
          .where((o) => o.name.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) categories = parsed;
    } catch (e) {
      debugPrint(
        '[OnboardingRepository] Using fallback activity categories: $e',
      );
    }

    return OnboardingReferenceData(
      interests: interests,
      intentions: intentions,
      activityCategories: categories,
    );
  }

  @override
  Future<AppUser> completeProfileOnboarding({
    required AppUser currentUser,
    required OnboardingProfileDraft draft,
  }) async {
    _ensureBackendAvailable();

    final nameError = AuthValidators.validateDisplayName(draft.displayName);
    if (nameError != null) throw Exception(nameError);

    final cityError = AuthValidators.validateCity(draft.city);
    if (cityError != null) throw Exception(cityError);

    final bioError = AuthValidators.validateBio(draft.bio);
    if (bioError != null) throw Exception(bioError);

    if (!draft.guidelinesAccepted) {
      throw Exception(
        'You must accept the MELSAVA Community Guidelines to continue.',
      );
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final trimmedName = draft.displayName.trim();
    final trimmedCity = draft.city.trim();
    final trimmedBio = draft.bio.trim();

    if (_hasLiveSupabase) {
      final client = SupabaseService.client!;

      // 1. Upsert public.profiles (never includes date_of_birth)
      await client.from('profiles').upsert({
        'id': draft.userId,
        'display_name': trimmedName,
        if (draft.avatarUrl != null && draft.avatarUrl!.isNotEmpty)
          'avatar_url': draft.avatarUrl,
        'bio': trimmedBio,
        'city': trimmedCity,
        'onboarding_completed': true,
        'updated_at': nowIso,
      }, onConflict: 'id');

      // 2. Upsert public.profile_private compliance timestamps
      await client.from('profile_private').upsert({
        'user_id': draft.userId,
        'email': draft.email,
        'age_verified': true,
        'terms_accepted_at': nowIso,
        'guidelines_accepted_at': nowIso,
      }, onConflict: 'user_id');

      // 2b. Save extended preferences to profile_private (migration 005)
      final discoveryPrefsMap = <String, dynamic>{
        'min_age': draft.discoveryMinAge,
        'max_age': draft.discoveryMaxAge,
        'max_distance_km': draft.discoveryMaxDistanceKm,
        'format': draft.discoveryFormat,
      };

      try {
        await client
            .from('profile_private')
            .update({
              'preferred_activity_categories':
                  draft.preferredActivityCategories,
              'availability_preferences': draft.availability,
              'discovery_preferences': discoveryPrefsMap,
            })
            .eq('user_id', draft.userId);
      } catch (e) {
        // Graceful fallback if migration 005 hasn't been applied to remote Supabase yet
        debugPrint(
          '[OnboardingRepository] Extended preference columns unavailable, saving to auth metadata: $e',
        );
        try {
          await client.auth.updateUser(
            UserAttributes(
              data: {
                'display_name': trimmedName,
                'preferred_activity_categories':
                    draft.preferredActivityCategories,
                'availability_preferences': draft.availability,
                'discovery_preferences': discoveryPrefsMap,
              },
            ),
          );
        } catch (_) {}
      }

      // 3. Replace profile_interests rows
      if (draft.interests.isNotEmpty) {
        try {
          final dbInterests = await client
              .from('interests')
              .select('id, name')
              .inFilter('name', draft.interests);
          final interestIds = (dbInterests as List)
              .map((r) => r['id']?.toString())
              .whereType<String>()
              .toList();

          await client
              .from('profile_interests')
              .delete()
              .eq('profile_id', draft.userId);

          if (interestIds.isNotEmpty) {
            await client
                .from('profile_interests')
                .insert(
                  interestIds
                      .map(
                        (id) => {'profile_id': draft.userId, 'interest_id': id},
                      )
                      .toList(),
                );
          }
        } catch (e) {
          debugPrint(
            '[OnboardingRepository] Failed saving profile_interests: $e',
          );
        }
      }

      // 4. Replace profile_intentions rows
      final allIntentions = <String>{
        if (draft.primaryIntention.isNotEmpty) draft.primaryIntention,
        ...draft.intentions,
      }.toList();

      if (allIntentions.isNotEmpty) {
        try {
          final dbIntentions = await client
              .from('intentions')
              .select('id, name')
              .inFilter('name', allIntentions);

          final rowsToInsert = <Map<String, dynamic>>[];
          for (final row in (dbIntentions as List)) {
            final id = row['id']?.toString();
            final name = row['name']?.toString();
            if (id == null || name == null) continue;
            rowsToInsert.add({
              'profile_id': draft.userId,
              'intention_id': id,
              'is_primary': name == draft.primaryIntention,
            });
          }

          await client
              .from('profile_intentions')
              .delete()
              .eq('profile_id', draft.userId);

          if (rowsToInsert.isNotEmpty) {
            await client.from('profile_intentions').insert(rowsToInsert);
          }
        } catch (e) {
          debugPrint(
            '[OnboardingRepository] Failed saving profile_intentions: $e',
          );
        }
      }
    } else if (_isDebugMockAllowed) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final secondaryIntents = draft.intentions
        .where((i) => i != draft.primaryIntention)
        .toList();

    final updatedUser = currentUser.copyWith(
      displayName: trimmedName,
      avatarUrl: draft.avatarUrl ?? currentUser.avatarUrl,
      city: trimmedCity,
      bio: trimmedBio,
      primaryIntent: draft.primaryIntention,
      secondaryIntents: secondaryIntents,
      interests: draft.interests,
      preferredActivityCategories: draft.preferredActivityCategories,
      availability: draft.availability,
      discoveryMinAge: draft.discoveryMinAge,
      discoveryMaxAge: draft.discoveryMaxAge,
      discoveryMaxDistanceKm: draft.discoveryMaxDistanceKm,
      discoveryFormat: draft.discoveryFormat,
      ageVerified: true,
      guidelinesAccepted: true,
      onboardingCompleted: true,
    );

    _authRepository.syncCachedUser(updatedUser);
    return updatedUser;
  }
}
