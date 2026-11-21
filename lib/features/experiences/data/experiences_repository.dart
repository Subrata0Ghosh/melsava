import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/experience_model.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/circle_creation_model.dart';

/// Upcoming date filter for live experience discovery.
enum ExperienceDateFilter { any, today, thisWeek, thisWeekend }

/// Format filter for live experience discovery.
enum ExperienceFormatFilter { all, inPerson, online }

/// Filter parameters for Discover and Experiences screens.
class ExperienceFilter {
  final String searchQuery;
  final String category;
  final String city;
  final ExperienceDateFilter dateFilter;
  final ExperienceFormatFilter format;
  final bool onlyAvailablePlaces;

  const ExperienceFilter({
    this.searchQuery = '',
    this.category = 'All',
    this.city = '',
    this.dateFilter = ExperienceDateFilter.any,
    this.format = ExperienceFormatFilter.all,
    this.onlyAvailablePlaces = false,
  });

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      category != 'All' ||
      city.trim().isNotEmpty ||
      dateFilter != ExperienceDateFilter.any ||
      format != ExperienceFormatFilter.all ||
      onlyAvailablePlaces;

  ExperienceFilter copyWith({
    String? searchQuery,
    String? category,
    String? city,
    ExperienceDateFilter? dateFilter,
    ExperienceFormatFilter? format,
    bool? onlyAvailablePlaces,
  }) {
    return ExperienceFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      city: city ?? this.city,
      dateFilter: dateFilter ?? this.dateFilter,
      format: format ?? this.format,
      onlyAvailablePlaces: onlyAvailablePlaces ?? this.onlyAvailablePlaces,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExperienceFilter &&
        other.searchQuery == searchQuery &&
        other.category == category &&
        other.city == city &&
        other.dateFilter == dateFilter &&
        other.format == format &&
        other.onlyAvailablePlaces == onlyAvailablePlaces;
  }

  @override
  int get hashCode => Object.hash(
    searchQuery,
    category,
    city,
    dateFilter,
    format,
    onlyAvailablePlaces,
  );
}

/// Result returned by server-side atomic `join_experience` RPC.
class JoinExperienceResult {
  final MembershipStatus status;
  final bool alreadyMember;
  final int currentParticipants;
  final int? maxParticipants;
  final int waitlistCount;

  const JoinExperienceResult({
    required this.status,
    required this.alreadyMember,
    required this.currentParticipants,
    this.maxParticipants,
    this.waitlistCount = 0,
  });

  bool get isJoined => status == MembershipStatus.joined;
  bool get isWaitlisted => status == MembershipStatus.waitlisted;

  String get userMessage {
    if (alreadyMember) {
      return isWaitlisted
          ? 'You are already on the waitlist for this experience.'
          : 'You have already joined this experience.';
    }
    return isWaitlisted
        ? 'You\'re on the waitlist.'
        : 'You have joined this experience.';
  }
}

/// Result returned by server-side atomic `cancel_experience_membership` RPC.
class CancelMembershipResult {
  final MembershipStatus previousStatus;
  final String? promotedUserId;
  final int currentParticipants;
  final int? maxParticipants;
  final int waitlistCount;

  const CancelMembershipResult({
    required this.previousStatus,
    this.promotedUserId,
    required this.currentParticipants,
    this.maxParticipants,
    this.waitlistCount = 0,
  });
}

/// Structured sections for My Experiences / My Circles.
class MyExperiencesBundle {
  final List<ExperienceModel> upcoming;
  final List<ExperienceModel> waitlisted;
  final List<ExperienceModel> attended;
  final List<ExperienceModel> past;

  const MyExperiencesBundle({
    this.upcoming = const [],
    this.waitlisted = const [],
    this.attended = const [],
    this.past = const [],
  });

  bool get isEmpty =>
      upcoming.isEmpty &&
      waitlisted.isEmpty &&
      attended.isEmpty &&
      past.isEmpty;

  int get totalCount =>
      upcoming.length + waitlisted.length + attended.length + past.length;

  int get totalActiveCount => upcoming.length + waitlisted.length;
}

/// Abstract repository contract for live experiences discovery, details,
/// atomic joining/waitlisting, cancellation, and My Circles management.
abstract class ExperiencesRepository {
  Future<List<ExperienceModel>> fetchPublishedUpcomingExperiences({
    ExperienceFilter filter = const ExperienceFilter(),
    AppUser? currentUser,
    int limit = 30,
    int offset = 0,
  });

  Future<ExperienceModel> fetchExperienceById(String experienceId);

  Future<MyExperiencesBundle> fetchMyExperiences();

  Future<JoinExperienceResult> joinExperience(String experienceId);

  Future<CancelMembershipResult> cancelMembership(String experienceId);

  Future<List<String>> fetchAvailableCategories();

  Future<List<({String id, String name, String icon})>>
  fetchCategoriesWithIds();

  Future<CircleCreationResult> createCircle(CircleCreationInput input);

  Future<List<ExperienceModel>> fetchNewInYourArea({
    String? city,
    String? area,
  });

  Future<List<ExperienceModel>> fetchPendingExperiences();

  DateTime? get lastSyncedAt;
  bool get isServingCachedOfflineData;
}

/// Production Supabase-backed implementation of [ExperiencesRepository].
///
/// - Queries only real rows from `public.experiences`, `public.activity_categories`,
///   `public.profiles`, and `public.experience_members`.
/// - Never falls back to fake sample data in production.
/// - Uses server-side atomic RPCs (`join_experience`, `cancel_experience_membership`,
///   `get_experience_participant_counts`) so capacity and FIFO waitlist order
///   cannot be bypassed by clients.
class SupabaseExperiencesRepository implements ExperiencesRepository {
  static const int defaultPageLimit = 30;

  DateTime? _lastSyncedAt;
  bool _isServingCachedOfflineData = false;

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  @override
  bool get isServingCachedOfflineData => _isServingCachedOfflineData;

  static const String _cacheKey = 'cached_published_experiences_v1';
  static const String _cacheTimestampKey =
      'cached_published_experiences_time_v1';

  Future<void> _persistCachedExperiences(
    List<ExperienceModel> experiences,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = experiences.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint(
        '[SupabaseExperiencesRepository] Error persisting offline cache: $e',
      );
    }
  }

  Future<List<ExperienceModel>> _loadCachedExperiences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_cacheTimestampKey);
      if (timeStr != null) {
        _lastSyncedAt = DateTime.tryParse(timeStr);
      }
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        return decoded
            .whereType<Map>()
            .map((m) => ExperienceModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint(
        '[SupabaseExperiencesRepository] Error loading offline cache: $e',
      );
    }
    return const [];
  }

  bool get _hasLiveSupabase =>
      SupabaseService.isConfigured && SupabaseService.client != null;

  SupabaseClient _requireClient() {
    if (!_hasLiveSupabase) {
      throw Exception(
        'Live experience service is not configured. Please check your internet connection or Supabase settings.',
      );
    }
    return SupabaseService.client!;
  }

  static String _iconForCategory(String? iconKey, String categoryName) {
    final key = (iconKey ?? categoryName).toLowerCase();
    if (key.contains('coffee') || key.contains('social')) return '☕';
    if (key.contains('game') || key.contains('board')) return '🎲';
    if (key.contains('hik') ||
        key.contains('nature') ||
        key.contains('outdoor')) {
      return '🥾';
    }
    if (key.contains('sport') || key.contains('fitness')) return '🏸';
    if (key.contains('photo') || key.contains('camera')) return '📸';
    if (key.contains('music')) return '🎸';
    if (key.contains('art') || key.contains('palette')) return '🎨';
    if (key.contains('food') || key.contains('restaurant')) return '🍽️';
    if (key.contains('book') || key.contains('read')) return '📚';
    if (key.contains('volunteer') || key.contains('heart')) return '🤝';
    if (key.contains('learn') || key.contains('lightbulb')) return '💡';
    if (key.contains('cultur') || key.contains('museum')) return '🏛️';
    if (key.contains('yoga') || key.contains('well')) return '🧘';
    return '✨';
  }

  Future<Map<String, ({int joined, int waitlisted})>> _fetchCounts(
    SupabaseClient client,
    List<String> experienceIds,
  ) async {
    if (experienceIds.isEmpty) return const {};

    try {
      final rows = await client.rpc(
        'get_experience_participant_counts',
        params: {'p_experience_ids': experienceIds},
      );

      final result = <String, ({int joined, int waitlisted})>{};
      if (rows is List) {
        for (final row in rows) {
          if (row is Map) {
            final id = row['experience_id']?.toString();
            if (id == null) continue;
            final joined = (row['joined_count'] as num?)?.toInt() ?? 0;
            final waitlisted = (row['waitlisted_count'] as num?)?.toInt() ?? 0;
            result[id] = (joined: joined, waitlisted: waitlisted);
          }
        }
      }
      return result;
    } catch (e) {
      debugPrint(
        '[SupabaseExperiencesRepository] Participant counts RPC unavailable: $e',
      );
      return const {};
    }
  }

  Future<Map<String, ({MembershipStatus status, DateTime? joinedAt})>>
  _fetchUserMemberships(
    SupabaseClient client,
    List<String> experienceIds,
  ) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null || experienceIds.isEmpty) return const {};

    try {
      final rows = await client
          .from('experience_members')
          .select('experience_id, status, joined_at')
          .eq('user_id', uid)
          .inFilter('experience_id', experienceIds);

      final map = <String, ({MembershipStatus status, DateTime? joinedAt})>{};
      for (final row in (rows as List)) {
        final id = row['experience_id']?.toString();
        if (id == null) continue;
        map[id] = (
          status: MembershipStatus.fromDb(row['status']?.toString()),
          joinedAt: row['joined_at'] != null
              ? DateTime.tryParse(row['joined_at'].toString())
              : null,
        );
      }
      return map;
    } catch (e) {
      debugPrint('[SupabaseExperiencesRepository] Membership lookup error: $e');
      return const {};
    }
  }

  ExperienceModel _mapRowToModel(
    Map<String, dynamic> row, {
    int joinedCount = 0,
    int waitlistCount = 0,
    MembershipStatus membershipStatus = MembershipStatus.none,
    DateTime? joinedAt,
  }) {
    final categoryMap = row['activity_categories'] is Map
        ? Map<String, dynamic>.from(row['activity_categories'] as Map)
        : const <String, dynamic>{};
    final hostMap = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : const <String, dynamic>{};

    final categoryName =
        (categoryMap['name'] as String?)?.trim().isNotEmpty == true
        ? (categoryMap['name'] as String).trim()
        : 'Community';
    final categoryIcon = _iconForCategory(
      categoryMap['icon'] as String?,
      categoryName,
    );

    final startsAt =
        DateTime.tryParse(row['starts_at']?.toString() ?? '')?.toLocal() ??
        DateTime.now().add(const Duration(days: 1));
    final endsAt = row['ends_at'] != null
        ? DateTime.tryParse(row['ends_at'].toString())?.toLocal()
        : null;
    final statusStr = (row['status'] as String?) ?? 'published';

    return ExperienceModel(
      id: row['id'].toString(),
      title: (row['title'] as String?)?.trim() ?? 'Untitled Experience',
      description: (row['description'] as String?)?.trim() ?? '',
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      coverImageUrl: (row['cover_image_url'] as String?)?.trim() ?? '',
      city: (row['city'] as String?)?.trim() ?? '',
      venueName: (row['venue_name'] as String?)?.trim() ?? '',
      venueAddress: (row['venue_address'] as String?)?.trim() ?? '',
      isOnline: (row['is_online'] as bool?) ?? false,
      startsAt: startsAt,
      endsAt: endsAt,
      durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 0,
      maxParticipants: (row['max_participants'] as num?)?.toInt() ?? 0,
      currentParticipants: joinedCount,
      waitlistCount: waitlistCount,
      hostId: row['host_id']?.toString() ?? hostMap['id']?.toString(),
      hostName: (hostMap['display_name'] as String?)?.trim().isNotEmpty == true
          ? (hostMap['display_name'] as String).trim()
          : 'MELSAVA Host',
      hostAvatar: (hostMap['avatar_url'] as String?)?.trim() ?? '',
      hostBio: (hostMap['bio'] as String?)?.trim(),
      cancellationPolicy: (row['cancellation_policy'] as String?)?.trim(),
      attendeeAvatars: const [],
      experienceStatus: statusStr,
      membershipStatus: membershipStatus,
      joinedAt: joinedAt,
      area: (row['area'] as String?)?.trim(),
      isFree: (row['is_free'] as bool?) ?? true,
      priceAmount: (row['price_amount'] as num?)?.toDouble() ?? 0.0,
      isRecurring: (row['is_recurring'] as bool?) ?? false,
      moderationStatus: (row['moderation_status'] as String?) ?? 'approved',
      reputationLevel: row['reputation_level'] as String?,
      isNewHost: row['is_new_host'] as bool?,
    );
  }

  /// Pure, inexpensive personalization & filter helper (also directly unit-tested).
  static List<ExperienceModel> applyFiltersAndRanking(
    List<ExperienceModel> input, {
    ExperienceFilter filter = const ExperienceFilter(),
    AppUser? currentUser,
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final query = filter.searchQuery.trim().toLowerCase();
    final catFilter = filter.category.trim().toLowerCase();
    final cityFilter = filter.city.trim().toLowerCase();

    final filtered = input.where((exp) {
      // Never show draft, cancelled, or past experiences in upcoming discovery
      if (exp.experienceStatus != 'published') return false;
      if (!exp.startsAt.isAfter(now)) return false;

      if (query.isNotEmpty) {
        final inTitle = exp.title.toLowerCase().contains(query);
        final inDesc = exp.description.toLowerCase().contains(query);
        final inCity = exp.city.toLowerCase().contains(query);
        final inVenue = exp.venueName.toLowerCase().contains(query);
        if (!inTitle && !inDesc && !inCity && !inVenue) return false;
      }

      if (catFilter.isNotEmpty && catFilter != 'all') {
        final expCat = exp.categoryName.toLowerCase();
        if (expCat != catFilter && !expCat.contains(catFilter)) {
          return false;
        }
      }

      if (cityFilter.isNotEmpty) {
        if (!exp.city.toLowerCase().contains(cityFilter)) return false;
      }

      if (filter.format == ExperienceFormatFilter.online && !exp.isOnline) {
        return false;
      }
      if (filter.format == ExperienceFormatFilter.inPerson && exp.isOnline) {
        return false;
      }

      if (filter.onlyAvailablePlaces && exp.isFull) {
        return false;
      }

      if (filter.dateFilter != ExperienceDateFilter.any) {
        final localStart = exp.startsAt;
        final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
        switch (filter.dateFilter) {
          case ExperienceDateFilter.today:
            if (localStart.isAfter(endOfToday)) return false;
          case ExperienceDateFilter.thisWeek:
            if (localStart.isAfter(now.add(const Duration(days: 7)))) {
              return false;
            }
          case ExperienceDateFilter.thisWeekend:
            final isWeekendDay =
                localStart.weekday == DateTime.saturday ||
                localStart.weekday == DateTime.sunday;
            if (!isWeekendDay ||
                localStart.isAfter(now.add(const Duration(days: 8)))) {
              return false;
            }
          case ExperienceDateFilter.any:
            break;
        }
      }

      return true;
    }).toList();

    // Simple, zero-cost personalized ranking: prioritize matches to user's saved
    // city, preferred activity categories, and interests without hiding non-matches.
    final userCity = (currentUser?.city ?? '').trim().toLowerCase();
    final userInterests = (currentUser?.interests ?? const <String>[])
        .map((e) => e.toLowerCase())
        .toList();
    final userPreferredCats =
        (currentUser?.preferredActivityCategories ?? const <String>[])
            .map((e) => e.toLowerCase())
            .toList();

    int scoreOf(ExperienceModel exp) {
      int score = 0;
      if (userCity.isNotEmpty && exp.city.toLowerCase().contains(userCity)) {
        score += 3;
      }
      // Locality boost for matching area
      if (exp.area != null &&
          exp.area!.trim().isNotEmpty &&
          userCity.isNotEmpty) {
        if (exp.area!.toLowerCase().contains(userCity) ||
            userCity.contains(exp.area!.toLowerCase())) {
          score += 2;
        }
      }
      final catLower = exp.categoryName.toLowerCase();
      if (userPreferredCats.any(
        (c) => catLower == c || catLower.contains(c) || c.contains(catLower),
      )) {
        score += 3;
      }
      final searchable = '${exp.title} ${exp.description} ${exp.categoryName}'
          .toLowerCase();
      for (final interest in userInterests) {
        if (interest.isNotEmpty && searchable.contains(interest)) {
          score += 1;
        }
      }
      // Cold-start new host & new activity fairness boost:
      // Prevents established hosts from monopolizing Discover solely from accumulated history.
      if (exp.isNewHost) {
        score += 2;
      }
      // Available spots bonus
      if (exp.spotsLeft > 0) {
        score += 1;
      }
      return score;
    }

    filtered.sort((a, b) {
      final diff = scoreOf(b).compareTo(scoreOf(a));
      if (diff != 0) return diff;
      return a.startsAt.compareTo(b.startsAt);
    });

    return filtered;
  }

  /// Pure grouping helper for My Experiences / My Circles (also directly unit-tested).
  static MyExperiencesBundle groupMyExperiences(
    List<ExperienceModel> memberExperiences, {
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final upcoming = <ExperienceModel>[];
    final waitlisted = <ExperienceModel>[];
    final attended = <ExperienceModel>[];
    final past = <ExperienceModel>[];

    for (final exp in memberExperiences) {
      if (exp.membershipStatus == MembershipStatus.cancelled ||
          exp.membershipStatus == MembershipStatus.none) {
        continue;
      }

      if (exp.membershipStatus == MembershipStatus.attended) {
        attended.add(exp);
        continue;
      }

      final isStillUpcoming =
          exp.experienceStatus == 'published' && exp.startsAt.isAfter(now);

      if (isStillUpcoming) {
        if (exp.membershipStatus == MembershipStatus.joined) {
          upcoming.add(exp);
        } else if (exp.membershipStatus == MembershipStatus.waitlisted) {
          waitlisted.add(exp);
        }
      } else {
        past.add(exp);
      }
    }

    upcoming.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    waitlisted.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    attended.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    past.sort((a, b) => b.startsAt.compareTo(a.startsAt));

    return MyExperiencesBundle(
      upcoming: upcoming,
      waitlisted: waitlisted,
      attended: attended,
      past: past,
    );
  }

  @override
  Future<List<ExperienceModel>> fetchPublishedUpcomingExperiences({
    ExperienceFilter filter = const ExperienceFilter(),
    AppUser? currentUser,
    int limit = defaultPageLimit,
    int offset = 0,
  }) async {
    if (!_hasLiveSupabase) {
      final cached = await _loadCachedExperiences();
      if (cached.isNotEmpty) {
        _isServingCachedOfflineData = true;
        return applyFiltersAndRanking(
          cached,
          filter: filter,
          currentUser: currentUser,
        );
      }
      if (kDebugMode) return const [];
      _requireClient();
    }

    try {
      final client = _requireClient();
      final nowIso = DateTime.now().toUtc().toIso8601String();

      var queryBuilder = client
          .from('experiences')
          .select(
            'id, title, description, cover_image_url, city, area, venue_name, venue_address, '
            'is_online, max_participants, status, starts_at, ends_at, duration_minutes, '
            'cancellation_policy, host_id, is_free, price_amount, is_recurring, moderation_status, '
            'activity_categories(name, icon, color), '
            'profiles!experiences_host_id_fkey(id, display_name, avatar_url, bio)',
          )
          .eq('status', 'published')
          .eq('moderation_status', 'approved')
          .gt('starts_at', nowIso);

      if (filter.format == ExperienceFormatFilter.online) {
        queryBuilder = queryBuilder.eq('is_online', true);
      } else if (filter.format == ExperienceFormatFilter.inPerson) {
        queryBuilder = queryBuilder.eq('is_online', false);
      }

      if (filter.city.trim().isNotEmpty) {
        queryBuilder = queryBuilder.ilike('city', '%${filter.city.trim()}%');
      }

      final safeLimit = limit.clamp(1, 50);
      final rows = await queryBuilder
          .order('starts_at', ascending: true)
          .range(offset, offset + safeLimit - 1);

      final rawList = (rows as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (rawList.isEmpty) return const [];

      final ids = rawList.map((r) => r['id'].toString()).toList();
      final results = await Future.wait([
        _fetchCounts(client, ids),
        _fetchUserMemberships(client, ids),
      ]);

      final countsMap =
          results[0] as Map<String, ({int joined, int waitlisted})>;
      final membershipMap =
          results[1]
              as Map<String, ({MembershipStatus status, DateTime? joinedAt})>;

      final models = rawList.map((row) {
        final id = row['id'].toString();
        final counts = countsMap[id];
        final member = membershipMap[id];
        return _mapRowToModel(
          row,
          joinedCount: counts?.joined ?? 0,
          waitlistCount: counts?.waitlisted ?? 0,
          membershipStatus: member?.status ?? MembershipStatus.none,
          joinedAt: member?.joinedAt,
        );
      }).toList();

      _lastSyncedAt = DateTime.now();
      _isServingCachedOfflineData = false;
      _persistCachedExperiences(models);

      return applyFiltersAndRanking(
        models,
        filter: filter,
        currentUser: currentUser,
      );
    } catch (e) {
      debugPrint(
        '[SupabaseExperiencesRepository] Error fetching experiences, attempting offline cache: $e',
      );
      final cached = await _loadCachedExperiences();
      if (cached.isNotEmpty) {
        _isServingCachedOfflineData = true;
        return applyFiltersAndRanking(
          cached,
          filter: filter,
          currentUser: currentUser,
        );
      }
      rethrow;
    }
  }

  @override
  Future<ExperienceModel> fetchExperienceById(String experienceId) async {
    final client = _requireClient();

    final row = await client
        .from('experiences')
        .select(
          'id, title, description, cover_image_url, city, area, venue_name, venue_address, '
          'is_online, max_participants, status, starts_at, ends_at, duration_minutes, '
          'cancellation_policy, host_id, is_free, price_amount, is_recurring, moderation_status, '
          'activity_categories(name, icon, color), '
          'profiles!experiences_host_id_fkey(id, display_name, avatar_url, bio)',
        )
        .eq('id', experienceId)
        .single();

    final map = Map<String, dynamic>.from(row as Map);
    final results = await Future.wait([
      _fetchCounts(client, [experienceId]),
      _fetchUserMemberships(client, [experienceId]),
    ]);

    final countsMap = results[0] as Map<String, ({int joined, int waitlisted})>;
    final membershipMap =
        results[1]
            as Map<String, ({MembershipStatus status, DateTime? joinedAt})>;
    final counts = countsMap[experienceId];
    final member = membershipMap[experienceId];

    return _mapRowToModel(
      map,
      joinedCount: counts?.joined ?? 0,
      waitlistCount: counts?.waitlisted ?? 0,
      membershipStatus: member?.status ?? MembershipStatus.none,
      joinedAt: member?.joinedAt,
    );
  }

  @override
  Future<MyExperiencesBundle> fetchMyExperiences() async {
    if (!_hasLiveSupabase) {
      if (kDebugMode) return const MyExperiencesBundle();
      _requireClient();
    }

    final client = _requireClient();
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const MyExperiencesBundle();

    final rows = await client
        .from('experience_members')
        .select(
          'status, joined_at, experience_id, '
          'experiences('
          '  id, title, description, cover_image_url, city, venue_name, venue_address, '
          '  is_online, max_participants, status, starts_at, ends_at, duration_minutes, '
          '  cancellation_policy, host_id, '
          '  activity_categories(name, icon, color), '
          '  profiles!experiences_host_id_fkey(id, display_name, avatar_url, bio)'
          ')',
        )
        .eq('user_id', uid)
        .neq('status', 'cancelled')
        .order('joined_at', ascending: false)
        .limit(50);

    final rawRows = (rows as List)
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .where((m) => m['experiences'] is Map)
        .toList();

    if (rawRows.isEmpty) return const MyExperiencesBundle();

    final expIds = rawRows
        .map((r) => (r['experiences'] as Map)['id'].toString())
        .toSet()
        .toList();
    final countsMap = await _fetchCounts(client, expIds);

    final models = rawRows.map((memberRow) {
      final expMap = Map<String, dynamic>.from(memberRow['experiences'] as Map);
      final id = expMap['id'].toString();
      final counts = countsMap[id];
      return _mapRowToModel(
        expMap,
        joinedCount: counts?.joined ?? 0,
        waitlistCount: counts?.waitlisted ?? 0,
        membershipStatus: MembershipStatus.fromDb(
          memberRow['status']?.toString(),
        ),
        joinedAt: memberRow['joined_at'] != null
            ? DateTime.tryParse(memberRow['joined_at'].toString())
            : null,
      );
    }).toList();

    return groupMyExperiences(models);
  }

  @override
  Future<JoinExperienceResult> joinExperience(String experienceId) async {
    final client = _requireClient();

    try {
      final raw = await client.rpc(
        'join_experience',
        params: {'p_experience_id': experienceId},
      );

      final data = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};

      return JoinExperienceResult(
        status: MembershipStatus.fromDb(data['status']?.toString()),
        alreadyMember: (data['already_member'] as bool?) ?? false,
        currentParticipants:
            (data['current_participants'] as num?)?.toInt() ?? 0,
        maxParticipants: (data['max_participants'] as num?)?.toInt(),
        waitlistCount: (data['waitlist_count'] as num?)?.toInt() ?? 0,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        e.message.isNotEmpty
            ? e.message
            : 'We couldn\'t complete that action. Please try again.',
      );
    }
  }

  @override
  Future<CancelMembershipResult> cancelMembership(String experienceId) async {
    final client = _requireClient();

    try {
      final raw = await client.rpc(
        'cancel_experience_membership',
        params: {'p_experience_id': experienceId},
      );

      final data = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};

      return CancelMembershipResult(
        previousStatus: MembershipStatus.fromDb(
          data['previous_status']?.toString(),
        ),
        promotedUserId: data['promoted_user_id']?.toString(),
        currentParticipants:
            (data['current_participants'] as num?)?.toInt() ?? 0,
        maxParticipants: (data['max_participants'] as num?)?.toInt(),
        waitlistCount: (data['waitlist_count'] as num?)?.toInt() ?? 0,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        e.message.isNotEmpty
            ? e.message
            : 'We couldn\'t cancel your reservation. Please try again.',
      );
    }
  }

  @override
  Future<List<String>> fetchAvailableCategories() async {
    if (!_hasLiveSupabase) return const ['All'];

    try {
      final rows = await SupabaseService.client!
          .from('activity_categories')
          .select('name')
          .order('display_order');
      final names = (rows as List)
          .map((r) => r['name']?.toString())
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .toList();
      return ['All', ...names];
    } catch (_) {
      return const ['All'];
    }
  }

  @override
  Future<List<({String id, String name, String icon})>>
  fetchCategoriesWithIds() async {
    if (!_hasLiveSupabase) return const [];
    try {
      final rows = await SupabaseService.client!
          .from('activity_categories')
          .select('id, name, icon')
          .order('display_order');
      return (rows as List)
          .whereType<Map>()
          .map(
            (r) => (
              id: r['id']?.toString() ?? '',
              name: r['name']?.toString() ?? '',
              icon: r['icon']?.toString() ?? '✨',
            ),
          )
          .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<CircleCreationResult> createCircle(CircleCreationInput input) async {
    final client = _requireClient();
    try {
      final res = await client.rpc(
        'create_user_experience',
        params: input.toRpcParams(),
      );
      if (res is Map) {
        return CircleCreationResult.fromJson(Map<String, dynamic>.from(res));
      }
      throw Exception('Invalid circle creation response format.');
    } catch (e) {
      debugPrint('[SupabaseExperiencesRepository] createCircle error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExperienceModel>> fetchNewInYourArea({
    String? city,
    String? area,
  }) async {
    if (!_hasLiveSupabase) return const [];
    try {
      final client = _requireClient();
      final nowIso = DateTime.now().toUtc().toIso8601String();
      var query = client
          .from('experiences')
          .select(
            'id, title, description, cover_image_url, city, area, venue_name, venue_address, '
            'is_online, max_participants, status, starts_at, ends_at, duration_minutes, '
            'cancellation_policy, host_id, is_free, price_amount, is_recurring, moderation_status, '
            'activity_categories(name, icon, color), '
            'profiles!experiences_host_id_fkey(id, display_name, avatar_url, bio)',
          )
          .eq('status', 'published')
          .eq('moderation_status', 'approved')
          .gt('starts_at', nowIso);

      if (city != null && city.trim().isNotEmpty) {
        query = query.ilike('city', '%${city.trim()}%');
      }

      final rows = await query.order('created_at', ascending: false).limit(8);

      final rawList = (rows as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (rawList.isEmpty) return const [];
      final ids = rawList.map((r) => r['id'].toString()).toList();
      final results = await Future.wait([
        _fetchCounts(client, ids),
        _fetchUserMemberships(client, ids),
      ]);
      final countsMap =
          results[0] as Map<String, ({int joined, int waitlisted})>;
      final membershipMap =
          results[1]
              as Map<String, ({MembershipStatus status, DateTime? joinedAt})>;

      return rawList.map((r) {
        final id = r['id'].toString();
        final c = countsMap[id] ?? (joined: 0, waitlisted: 0);
        final m =
            membershipMap[id] ??
            (status: MembershipStatus.none, joinedAt: null);
        return _mapRowToModel(
          r,
          joinedCount: c.joined,
          waitlistCount: c.waitlisted,
          membershipStatus: m.status,
          joinedAt: m.joinedAt,
        );
      }).toList();
    } catch (e) {
      debugPrint(
        '[SupabaseExperiencesRepository] fetchNewInYourArea error: $e',
      );
      return const [];
    }
  }

  @override
  Future<List<ExperienceModel>> fetchPendingExperiences() async {
    if (!_hasLiveSupabase) return const [];
    try {
      final client = _requireClient();
      final rows = await client
          .from('experiences')
          .select(
            'id, title, description, cover_image_url, city, area, venue_name, venue_address, '
            'is_online, max_participants, status, starts_at, ends_at, duration_minutes, '
            'cancellation_policy, host_id, is_free, price_amount, is_recurring, moderation_status, '
            'activity_categories(name, icon, color), '
            'profiles!experiences_host_id_fkey(id, display_name, avatar_url, bio)',
          )
          .eq('moderation_status', 'pending_review')
          .order('created_at', ascending: false);

      final rawList = List<Map<String, dynamic>>.from(rows);
      final expIds = rawList.map((r) => r['id'].toString()).toList();
      final countsMap = await _fetchCounts(client, expIds);

      return rawList.map((r) {
        final id = r['id'].toString();
        final c = countsMap[id] ?? (joined: 0, waitlisted: 0);
        return _mapRowToModel(
          r,
          joinedCount: c.joined,
          waitlistCount: c.waitlisted,
        );
      }).toList();
    } catch (e) {
      debugPrint(
        '[SupabaseExperiencesRepository] fetchPendingExperiences error: $e',
      );
      return const [];
    }
  }
}

// ── Riverpod Providers (Shared by Discover, Experiences, Details, Profile) ───

final experiencesRepositoryProvider = Provider<ExperiencesRepository>((ref) {
  return SupabaseExperiencesRepository();
});

final discoveryFilterProvider = StateProvider<ExperienceFilter>((ref) {
  return const ExperienceFilter();
});

final activityCategoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(experiencesRepositoryProvider).fetchAvailableCategories();
});

final publishedExperiencesProvider = FutureProvider<List<ExperienceModel>>((
  ref,
) async {
  final repo = ref.watch(experiencesRepositoryProvider);
  final filter = ref.watch(discoveryFilterProvider);
  final user = ref.watch(currentUserProvider);
  return repo.fetchPublishedUpcomingExperiences(
    filter: filter,
    currentUser: user,
  );
});

final myExperiencesProvider = FutureProvider<MyExperiencesBundle>((ref) async {
  final repo = ref.watch(experiencesRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const MyExperiencesBundle();
  return repo.fetchMyExperiences();
});

final experienceDetailProvider = FutureProvider.family<ExperienceModel, String>(
  (ref, experienceId) async {
    final repo = ref.watch(experiencesRepositoryProvider);
    return repo.fetchExperienceById(experienceId);
  },
);

/// Coordinates atomic join/cancel operations and refreshes all dependent providers.
class ExperienceActionController {
  final Ref _ref;

  ExperienceActionController(this._ref);

  Future<JoinExperienceResult> joinExperience(String experienceId) async {
    final result = await _ref
        .read(experiencesRepositoryProvider)
        .joinExperience(experienceId);
    _invalidateAll(experienceId);
    return result;
  }

  Future<CancelMembershipResult> cancelMembership(String experienceId) async {
    final result = await _ref
        .read(experiencesRepositoryProvider)
        .cancelMembership(experienceId);
    _invalidateAll(experienceId);
    return result;
  }

  void _invalidateAll(String experienceId) {
    _ref.invalidate(publishedExperiencesProvider);
    _ref.invalidate(myExperiencesProvider);
    _ref.invalidate(experienceDetailProvider(experienceId));
    _ref.invalidate(newInYourAreaExperiencesProvider);
  }
}

final categoriesWithIdsProvider =
    FutureProvider<List<({String id, String name, String icon})>>((ref) {
      return ref.watch(experiencesRepositoryProvider).fetchCategoriesWithIds();
    });

final newInYourAreaExperiencesProvider = FutureProvider<List<ExperienceModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  return ref
      .watch(experiencesRepositoryProvider)
      .fetchNewInYourArea(city: user?.city);
});

final pendingExperiencesProvider = FutureProvider<List<ExperienceModel>>((ref) {
  return ref.watch(experiencesRepositoryProvider).fetchPendingExperiences();
});

final experienceActionControllerProvider = Provider<ExperienceActionController>(
  (ref) => ExperienceActionController(ref),
);

final isOfflineExperiencesProvider = Provider<bool>((ref) {
  final repo = ref.watch(experiencesRepositoryProvider);
  return repo.isServingCachedOfflineData;
});

final experiencesLastSyncedProvider = Provider<DateTime?>((ref) {
  final repo = ref.watch(experiencesRepositoryProvider);
  return repo.lastSyncedAt;
});
