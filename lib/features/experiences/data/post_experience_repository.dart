import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'experiences_repository.dart';

/// Available connection choice types for post-experience reconnection.
enum ReconnectChoiceType {
  friendship,
  activityPartner,
  exploreDating,
  noConnection;

  String toDbString() {
    switch (this) {
      case ReconnectChoiceType.friendship:
        return 'friendship';
      case ReconnectChoiceType.activityPartner:
        return 'activity_partner';
      case ReconnectChoiceType.exploreDating:
        return 'explore_dating';
      case ReconnectChoiceType.noConnection:
        return 'no_connection';
    }
  }

  static ReconnectChoiceType fromDbString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'friendship':
        return ReconnectChoiceType.friendship;
      case 'activity_partner':
        return ReconnectChoiceType.activityPartner;
      case 'explore_dating':
      case 'dating':
        return ReconnectChoiceType.exploreDating;
      default:
        return ReconnectChoiceType.noConnection;
    }
  }

  String get label {
    switch (this) {
      case ReconnectChoiceType.friendship:
        return 'Friendship';
      case ReconnectChoiceType.activityPartner:
        return 'Activity Partner';
      case ReconnectChoiceType.exploreDating:
        return 'Explore Dating';
      case ReconnectChoiceType.noConnection:
        return 'No Connection';
    }
  }
}

/// An attended peer eligible to be selected for reconnection.
class EligibleAttendee {
  final String id;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final String experienceTitle;

  const EligibleAttendee({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    this.experienceTitle = '',
  });

  factory EligibleAttendee.fromMap(Map<String, dynamic> map) {
    return EligibleAttendee(
      id: map['user_id']?.toString() ?? '',
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : 'MELSAVA Member',
      avatarUrl: (map['avatar_url'] as String?)?.trim() ?? '',
      bio: (map['bio'] as String?)?.trim() ?? '',
      experienceTitle: (map['experience_title'] as String?)?.trim() ?? '',
    );
  }
}

/// A choice submitted for a specific attendee.
class PostExperienceChoiceInput {
  final String chosenId;
  final ReconnectChoiceType choiceType;

  const PostExperienceChoiceInput({
    required this.chosenId,
    required this.choiceType,
  });

  Map<String, dynamic> toJson() => {
    'chosen_id': chosenId,
    'choice_type': choiceType.toDbString(),
  };
}

/// A newly formed mutual connection returned by the atomic submission RPC.
class MutualConnectionResult {
  final String connectionId;
  final String conversationId;
  final String partnerId;
  final String partnerName;
  final String partnerAvatar;
  final String connectionType;
  final String connectionTypeLabel;
  final String experienceTitle;

  const MutualConnectionResult({
    required this.connectionId,
    required this.conversationId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerAvatar,
    required this.connectionType,
    required this.connectionTypeLabel,
    required this.experienceTitle,
  });

  factory MutualConnectionResult.fromMap(Map<String, dynamic> map) {
    return MutualConnectionResult(
      connectionId: map['connection_id']?.toString() ?? '',
      conversationId: map['conversation_id']?.toString() ?? '',
      partnerId: map['partner_id']?.toString() ?? '',
      partnerName: map['partner_name']?.toString() ?? 'New Connection',
      partnerAvatar: map['partner_avatar']?.toString() ?? '',
      connectionType: map['connection_type']?.toString() ?? 'friendship',
      connectionTypeLabel:
          map['connection_type_label']?.toString() ?? 'Connection',
      experienceTitle: map['experience_title']?.toString() ?? 'Experience',
    );
  }
}

/// Result returned after submitting post-experience reconnection choices.
class PostExperienceSubmissionResult {
  final bool submitted;
  final bool alreadySubmitted;
  final String message;
  final List<MutualConnectionResult> mutualConnections;

  const PostExperienceSubmissionResult({
    required this.submitted,
    this.alreadySubmitted = false,
    this.message = '',
    this.mutualConnections = const [],
  });

  bool get hasMutualMatch => mutualConnections.isNotEmpty;
}

/// Detailed status for post-experience reconnection screen gating.
class ReconnectSubmissionStatus {
  final bool isCompleted;
  final bool isAttended;
  final bool isHost;
  final bool isSubmitted;
  final DateTime? submittedAt;

  const ReconnectSubmissionStatus({
    this.isCompleted = false,
    this.isAttended = false,
    this.isHost = false,
    this.isSubmitted = false,
    this.submittedAt,
  });

  factory ReconnectSubmissionStatus.fromMap(Map<String, dynamic> map) {
    return ReconnectSubmissionStatus(
      isCompleted: map['is_completed'] == true,
      isAttended: map['is_attended'] == true,
      isHost: map['is_host'] == true,
      isSubmitted: map['is_submitted'] == true,
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'].toString())
          : null,
    );
  }
}

/// Joined participant item shown to host during attendance confirmation.
class HostParticipantItem {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final String memberStatus;
  final DateTime? joinedAt;

  const HostParticipantItem({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.memberStatus,
    this.joinedAt,
  });

  bool get isAttended => memberStatus == 'attended';

  factory HostParticipantItem.fromMap(Map<String, dynamic> map) {
    return HostParticipantItem(
      userId: map['user_id']?.toString() ?? '',
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : 'Participant',
      avatarUrl: (map['avatar_url'] as String?)?.trim() ?? '',
      bio: (map['bio'] as String?)?.trim() ?? '',
      memberStatus: map['member_status']?.toString() ?? 'joined',
      joinedAt: map['joined_at'] != null
          ? DateTime.tryParse(map['joined_at'].toString())
          : null,
    );
  }
}

/// Participant in an active or live meetup session.
class MeetupCircleParticipant {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final String role; // 'Host' or 'Attendee'
  final DateTime? joinedAt;

  const MeetupCircleParticipant({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.role,
    this.joinedAt,
  });

  factory MeetupCircleParticipant.fromMap(Map<String, dynamic> map) {
    return MeetupCircleParticipant(
      userId: map['user_id']?.toString() ?? '',
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : 'Participant',
      avatarUrl: (map['avatar_url'] as String?)?.trim() ?? '',
      bio: (map['bio'] as String?)?.trim() ?? '',
      role: map['role']?.toString() ?? 'Attendee',
      joinedAt: map['joined_at'] != null
          ? DateTime.tryParse(map['joined_at'].toString())
          : null,
    );
  }
}

/// Result of host confirming attendance.
class AttendanceConfirmationResult {
  final bool success;
  final String experienceId;
  final String status;
  final int attendedCount;

  const AttendanceConfirmationResult({
    required this.success,
    required this.experienceId,
    required this.status,
    required this.attendedCount,
  });
}

/// Contract for post-experience reconnection, attendance, and mutual matching.
abstract class PostExperienceRepository {
  Future<List<EligibleAttendee>> fetchEligibleAttendees(String experienceId);

  Future<ReconnectSubmissionStatus> fetchSubmissionStatus(String experienceId);

  Future<PostExperienceSubmissionResult> submitChoices(
    String experienceId,
    List<PostExperienceChoiceInput> choices,
  );

  Future<List<HostParticipantItem>> fetchHostJoinedParticipants(
    String experienceId,
  );

  Future<List<MeetupCircleParticipant>> fetchCircleParticipants(
    String experienceId,
  );

  Future<AttendanceConfirmationResult> completeExperienceAndMarkAttendance(
    String experienceId,
    List<String> attendedUserIds,
  );
}

/// Production Supabase-backed implementation of [PostExperienceRepository].
class SupabasePostExperienceRepository implements PostExperienceRepository {
  bool get _hasLiveSupabase =>
      SupabaseService.isConfigured && SupabaseService.client != null;

  SupabaseClient _requireClient() {
    if (!_hasLiveSupabase) {
      throw Exception(
        'Service is not configured. Please check connection and settings.',
      );
    }
    return SupabaseService.client!;
  }

  @override
  Future<List<EligibleAttendee>> fetchEligibleAttendees(
    String experienceId,
  ) async {
    final client = _requireClient();

    try {
      final rows = await client.rpc(
        'fetch_eligible_reconnect_attendees',
        params: {'p_experience_id': experienceId},
      );

      if (rows is List) {
        return rows
            .whereType<Map>()
            .map((r) => EligibleAttendee.fromMap(Map<String, dynamic>.from(r)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[PostExperienceRepository] fetchEligibleAttendees error: $e');
      rethrow;
    }
  }

  @override
  Future<ReconnectSubmissionStatus> fetchSubmissionStatus(
    String experienceId,
  ) async {
    final client = _requireClient();

    try {
      final res = await client.rpc(
        'fetch_reconnect_submission_status',
        params: {'p_experience_id': experienceId},
      );

      if (res is Map) {
        return ReconnectSubmissionStatus.fromMap(
          Map<String, dynamic>.from(res),
        );
      }
      return const ReconnectSubmissionStatus();
    } catch (e) {
      debugPrint('[PostExperienceRepository] fetchSubmissionStatus error: $e');
      rethrow;
    }
  }

  @override
  Future<PostExperienceSubmissionResult> submitChoices(
    String experienceId,
    List<PostExperienceChoiceInput> choices,
  ) async {
    final client = _requireClient();

    final payload = choices.map((c) => c.toJson()).toList();

    try {
      final res = await client.rpc(
        'submit_post_experience_choices',
        params: {'p_experience_id': experienceId, 'p_choices': payload},
      );

      if (res is Map) {
        final map = Map<String, dynamic>.from(res);
        final alreadySubmitted = map['already_submitted'] == true;
        final submitted = map['submitted'] == true;
        final message = map['message']?.toString() ?? '';

        final rawConnections = map['mutual_connections'];
        final connections = <MutualConnectionResult>[];

        if (rawConnections is List) {
          for (final c in rawConnections) {
            if (c is Map) {
              connections.add(
                MutualConnectionResult.fromMap(Map<String, dynamic>.from(c)),
              );
            }
          }
        }

        return PostExperienceSubmissionResult(
          submitted: submitted,
          alreadySubmitted: alreadySubmitted,
          message: message,
          mutualConnections: connections,
        );
      }

      return const PostExperienceSubmissionResult(submitted: false);
    } catch (e) {
      debugPrint('[PostExperienceRepository] submitChoices error: $e');
      rethrow;
    }
  }

  @override
  Future<List<HostParticipantItem>> fetchHostJoinedParticipants(
    String experienceId,
  ) async {
    final client = _requireClient();

    try {
      final rows = await client.rpc(
        'get_host_joined_participants',
        params: {'p_experience_id': experienceId},
      );

      if (rows is List) {
        return rows
            .whereType<Map>()
            .map(
              (r) => HostParticipantItem.fromMap(Map<String, dynamic>.from(r)),
            )
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint(
        '[PostExperienceRepository] fetchHostJoinedParticipants error: $e',
      );
      rethrow;
    }
  }

  @override
  Future<AttendanceConfirmationResult> completeExperienceAndMarkAttendance(
    String experienceId,
    List<String> attendedUserIds,
  ) async {
    final client = _requireClient();

    try {
      final res = await client.rpc(
        'complete_experience_and_mark_attendance',
        params: {
          'p_experience_id': experienceId,
          'p_attended_user_ids': attendedUserIds,
        },
      );

      if (res is Map) {
        final map = Map<String, dynamic>.from(res);
        return AttendanceConfirmationResult(
          success: map['success'] == true,
          experienceId: map['experience_id']?.toString() ?? experienceId,
          status: map['status']?.toString() ?? 'completed',
          attendedCount: (map['attended_count'] as num?)?.toInt() ?? 0,
        );
      }

      return AttendanceConfirmationResult(
        success: false,
        experienceId: experienceId,
        status: 'error',
        attendedCount: 0,
      );
    } catch (e) {
      debugPrint(
        '[PostExperienceRepository] completeExperienceAndMarkAttendance error: $e',
      );
      rethrow;
    }
  }

  @override
  Future<List<MeetupCircleParticipant>> fetchCircleParticipants(
    String experienceId,
  ) async {
    final client = _requireClient();

    try {
      final rows = await client.rpc(
        'get_experience_circle_participants',
        params: {'p_experience_id': experienceId},
      );

      if (rows is List) {
        return rows
            .whereType<Map>()
            .map(
              (r) =>
                  MeetupCircleParticipant.fromMap(Map<String, dynamic>.from(r)),
            )
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint(
        '[PostExperienceRepository] fetchCircleParticipants RPC error: $e. Falling back to direct database query.',
      );
      try {
        return await _fetchCircleParticipantsFallback(client, experienceId);
      } catch (fallbackError) {
        debugPrint(
          '[PostExperienceRepository] fetchCircleParticipants fallback failed: $fallbackError',
        );
        rethrow;
      }
    }
  }

  /// Resilient fallback when the server-side RPC is not available in the schema cache.
  Future<List<MeetupCircleParticipant>> _fetchCircleParticipantsFallback(
    SupabaseClient client,
    String experienceId,
  ) async {
    final participants = <MeetupCircleParticipant>[];
    final seenUserIds = <String>{};

    // 1. Fetch host from experiences table
    try {
      final expRow = await client
          .from('experiences')
          .select(
            'id, host_id, created_at, profiles!experiences_host_id_fkey(id, display_name, avatar_url, bio)',
          )
          .eq('id', experienceId)
          .maybeSingle();

      if (expRow != null) {
        final hostId = expRow['host_id']?.toString() ?? '';
        final profileMap = expRow['profiles'];
        if (profileMap is Map) {
          final hostProfile = Map<String, dynamic>.from(profileMap);
          final hostParticipant = MeetupCircleParticipant(
            userId: hostProfile['id']?.toString() ?? hostId,
            displayName:
                (hostProfile['display_name'] as String?)?.trim().isNotEmpty ==
                    true
                ? (hostProfile['display_name'] as String).trim()
                : 'Host',
            avatarUrl: (hostProfile['avatar_url'] as String?)?.trim() ?? '',
            bio: (hostProfile['bio'] as String?)?.trim() ?? '',
            role: 'Host',
            joinedAt: expRow['created_at'] != null
                ? DateTime.tryParse(expRow['created_at'].toString())
                : null,
          );
          if (hostParticipant.userId.isNotEmpty) {
            participants.add(hostParticipant);
            seenUserIds.add(hostParticipant.userId);
          }
        } else if (hostId.isNotEmpty) {
          final hostProfRow = await client
              .from('profiles')
              .select('id, display_name, avatar_url, bio')
              .eq('id', hostId)
              .maybeSingle();
          if (hostProfRow != null) {
            final hp = Map<String, dynamic>.from(hostProfRow);
            participants.add(
              MeetupCircleParticipant(
                userId: hp['id']?.toString() ?? hostId,
                displayName:
                    (hp['display_name'] as String?)?.trim().isNotEmpty == true
                    ? (hp['display_name'] as String).trim()
                    : 'Host',
                avatarUrl: (hp['avatar_url'] as String?)?.trim() ?? '',
                bio: (hp['bio'] as String?)?.trim() ?? '',
                role: 'Host',
                joinedAt: expRow['created_at'] != null
                    ? DateTime.tryParse(expRow['created_at'].toString())
                    : null,
              ),
            );
            seenUserIds.add(hostId);
          }
        }
      }
    } catch (e) {
      debugPrint('[PostExperienceRepository] fallback host query error: $e');
    }

    // 2. Fetch joined attendees from experience_members table
    try {
      final memberRows = await client
          .from('experience_members')
          .select(
            'user_id, status, joined_at, profiles!experience_members_user_id_fkey(id, display_name, avatar_url, bio)',
          )
          .eq('experience_id', experienceId)
          .inFilter('status', ['joined', 'attended'])
          .order('joined_at', ascending: true);

      for (final row in memberRows) {
        final uid = row['user_id']?.toString() ?? '';
        if (uid.isEmpty || seenUserIds.contains(uid)) continue;

        final profMap = row['profiles'];
        if (profMap is Map) {
          final p = Map<String, dynamic>.from(profMap);
          participants.add(
            MeetupCircleParticipant(
              userId: uid,
              displayName:
                  (p['display_name'] as String?)?.trim().isNotEmpty == true
                  ? (p['display_name'] as String).trim()
                  : 'Participant',
              avatarUrl: (p['avatar_url'] as String?)?.trim() ?? '',
              bio: (p['bio'] as String?)?.trim() ?? '',
              role: 'Attendee',
              joinedAt: row['joined_at'] != null
                  ? DateTime.tryParse(row['joined_at'].toString())
                  : null,
            ),
          );
          seenUserIds.add(uid);
        }
      }
    } catch (e) {
      debugPrint(
        '[PostExperienceRepository] fallback attendee join query error: $e, trying separate queries',
      );
      try {
        final simpleRows = await client
            .from('experience_members')
            .select('user_id, status, joined_at')
            .eq('experience_id', experienceId)
            .inFilter('status', ['joined', 'attended']);

        if (simpleRows.isNotEmpty) {
          final uids = simpleRows
              .map((r) => r['user_id']?.toString())
              .whereType<String>()
              .where((id) => !seenUserIds.contains(id))
              .toList();

          if (uids.isNotEmpty) {
            final profs = await client
                .from('profiles')
                .select('id, display_name, avatar_url, bio')
                .inFilter('id', uids);

            final profMap = <String, Map<String, dynamic>>{};
            for (final p in profs) {
              if (p['id'] != null) {
                profMap[p['id'].toString()] = Map<String, dynamic>.from(p);
              }
            }

            for (final r in simpleRows) {
              final uid = r['user_id']?.toString() ?? '';
              if (uid.isEmpty || seenUserIds.contains(uid)) continue;
              final p = profMap[uid];
              participants.add(
                MeetupCircleParticipant(
                  userId: uid,
                  displayName:
                      (p?['display_name'] as String?)?.trim().isNotEmpty == true
                      ? (p!['display_name'] as String).trim()
                      : 'Participant',
                  avatarUrl: (p?['avatar_url'] as String?)?.trim() ?? '',
                  bio: (p?['bio'] as String?)?.trim() ?? '',
                  role: 'Attendee',
                  joinedAt: r['joined_at'] != null
                      ? DateTime.tryParse(r['joined_at'].toString())
                      : null,
                ),
              );
              seenUserIds.add(uid);
            }
          }
        }
      } catch (innerErr) {
        debugPrint(
          '[PostExperienceRepository] fallback separate queries error: $innerErr',
        );
      }
    }

    // 3. Ensure current authenticated user is included if they have joined
    final currentUid = client.auth.currentUser?.id;
    if (currentUid != null && !seenUserIds.contains(currentUid)) {
      try {
        final myMemberRow = await client
            .from('experience_members')
            .select('user_id, status, joined_at')
            .eq('experience_id', experienceId)
            .eq('user_id', currentUid)
            .maybeSingle();

        if (myMemberRow != null &&
            (myMemberRow['status'] == 'joined' ||
                myMemberRow['status'] == 'attended')) {
          final myProf = await client
              .from('profiles')
              .select('id, display_name, avatar_url, bio')
              .eq('id', currentUid)
              .maybeSingle();

          final p = myProf != null ? Map<String, dynamic>.from(myProf) : null;
          participants.add(
            MeetupCircleParticipant(
              userId: currentUid,
              displayName:
                  (p?['display_name'] as String?)?.trim().isNotEmpty == true
                  ? (p!['display_name'] as String).trim()
                  : 'You',
              avatarUrl: (p?['avatar_url'] as String?)?.trim() ?? '',
              bio: (p?['bio'] as String?)?.trim() ?? '',
              role: 'Attendee',
              joinedAt: myMemberRow['joined_at'] != null
                  ? DateTime.tryParse(myMemberRow['joined_at'].toString())
                  : null,
            ),
          );
        }
      } catch (e) {
        debugPrint('[PostExperienceRepository] current user check error: $e');
      }
    }

    return participants;
  }
}

// ----------------------------------------------------------------------------
// Riverpod Providers
// ----------------------------------------------------------------------------

final postExperienceRepositoryProvider = Provider<PostExperienceRepository>((
  ref,
) {
  return SupabasePostExperienceRepository();
});

final eligibleAttendeesProvider =
    FutureProvider.family<List<EligibleAttendee>, String>((
      ref,
      experienceId,
    ) async {
      final repo = ref.watch(postExperienceRepositoryProvider);
      return repo.fetchEligibleAttendees(experienceId);
    });

final reconnectSubmissionStatusProvider =
    FutureProvider.family<ReconnectSubmissionStatus, String>((
      ref,
      experienceId,
    ) async {
      final repo = ref.watch(postExperienceRepositoryProvider);
      return repo.fetchSubmissionStatus(experienceId);
    });

final hostJoinedParticipantsProvider =
    FutureProvider.family<List<HostParticipantItem>, String>((
      ref,
      experienceId,
    ) async {
      final repo = ref.watch(postExperienceRepositoryProvider);
      return repo.fetchHostJoinedParticipants(experienceId);
    });

final circleParticipantsProvider =
    FutureProvider.family<List<MeetupCircleParticipant>, String>((
      ref,
      experienceId,
    ) async {
      final repo = ref.watch(postExperienceRepositoryProvider);
      return repo.fetchCircleParticipants(experienceId);
    });

class PostExperienceActionController {
  final Ref _ref;

  PostExperienceActionController(this._ref);

  Future<PostExperienceSubmissionResult> submitChoices({
    required String experienceId,
    required List<PostExperienceChoiceInput> choices,
  }) async {
    final repo = _ref.read(postExperienceRepositoryProvider);
    final result = await repo.submitChoices(experienceId, choices);

    _ref.invalidate(reconnectSubmissionStatusProvider(experienceId));
    _ref.invalidate(eligibleAttendeesProvider(experienceId));
    _ref.invalidate(myExperiencesProvider);

    return result;
  }

  Future<AttendanceConfirmationResult> completeExperienceAndMarkAttendance({
    required String experienceId,
    required List<String> attendedUserIds,
  }) async {
    final repo = _ref.read(postExperienceRepositoryProvider);
    final result = await repo.completeExperienceAndMarkAttendance(
      experienceId,
      attendedUserIds,
    );

    _ref.invalidate(reconnectSubmissionStatusProvider(experienceId));
    _ref.invalidate(hostJoinedParticipantsProvider(experienceId));
    _ref.invalidate(eligibleAttendeesProvider(experienceId));
    _ref.invalidate(circleParticipantsProvider(experienceId));
    _ref.invalidate(myExperiencesProvider);
    _ref.invalidate(publishedExperiencesProvider);

    return result;
  }
}

final postExperienceActionControllerProvider =
    Provider<PostExperienceActionController>((ref) {
      return PostExperienceActionController(ref);
    });
