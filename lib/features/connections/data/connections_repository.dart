import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// Represents a mutual connection formed from an attended experience.
class ConnectionModel {
  final String id;
  final String? conversationId;
  final String partnerId;
  final String name;
  final String avatarUrl;
  final String bio;
  final String connectionType; // 'Friends', 'Activity', 'Dates'
  final String
  rawConnectionType; // 'friendship', 'activity_partner', 'explore_dating'
  final String? experienceId;
  final String experienceName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String timeAgo;
  final bool isOnline;
  final int? compatibilityScore;

  const ConnectionModel({
    required this.id,
    this.conversationId,
    required this.partnerId,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.connectionType,
    required this.rawConnectionType,
    this.experienceId,
    required this.experienceName,
    required this.lastMessage,
    this.lastMessageAt,
    required this.timeAgo,
    this.isOnline = false,
    this.compatibilityScore,
  });

  factory ConnectionModel.fromMap(Map<String, dynamic> map) {
    final rawType =
        map['connection_type']?.toString().toLowerCase() ?? 'friendship';
    final String displayType;
    if (rawType.contains('dating')) {
      displayType = 'Dates';
    } else if (rawType.contains('activity')) {
      displayType = 'Activity';
    } else {
      displayType = 'Friends';
    }

    final createdAtStr = map['last_message_at'] ?? map['created_at'];
    DateTime? dt;
    if (createdAtStr != null) {
      dt = DateTime.tryParse(createdAtStr.toString());
    }

    final rawLastMessage = (map['last_message'] as String?)?.trim();
    final lastMessage = (rawLastMessage != null && rawLastMessage.isNotEmpty)
        ? rawLastMessage
        : '';

    return ConnectionModel(
      id: map['connection_id']?.toString() ?? '',
      conversationId: map['conversation_id']?.toString(),
      partnerId: map['partner_id']?.toString() ?? '',
      name: (map['partner_name'] as String?)?.trim().isNotEmpty == true
          ? (map['partner_name'] as String).trim()
          : 'MELSAVA Member',
      avatarUrl: (map['partner_avatar'] as String?)?.trim() ?? '',
      bio: (map['partner_bio'] as String?)?.trim() ?? '',
      connectionType: displayType,
      rawConnectionType: rawType,
      experienceId: map['experience_id']?.toString(),
      experienceName:
          (map['experience_title'] as String?)?.trim().isNotEmpty == true
          ? (map['experience_title'] as String).trim()
          : 'Shared Experience',
      lastMessage: lastMessage,
      lastMessageAt: dt,
      timeAgo: _formatTimeAgo(dt),
      isOnline: map['is_online'] == true,
      compatibilityScore: (map['compatibility_score'] as num?)?.toInt(),
    );
  }
}

/// Represents an inbox conversation thread between mutual connections.
class InboxThreadModel {
  final String conversationId;
  final String? connectionId;
  final String partnerId;
  final String participantName;
  final String participantAvatar;
  final String
  connectionType; // 'Friendship', 'Activity Partner', 'Exploring Dating'
  final String experienceName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String timestamp;
  final int unreadCount;
  final bool isOnline;

  const InboxThreadModel({
    required this.conversationId,
    this.connectionId,
    required this.partnerId,
    required this.participantName,
    required this.participantAvatar,
    required this.connectionType,
    required this.experienceName,
    required this.lastMessage,
    this.lastMessageAt,
    required this.timestamp,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  bool get isUnread => unreadCount > 0;

  factory InboxThreadModel.fromMap(Map<String, dynamic> map) {
    final rawType =
        map['connection_type']?.toString().toLowerCase() ?? 'friendship';
    final String displayType;
    if (rawType.contains('dating')) {
      displayType = 'Exploring Dating';
    } else if (rawType.contains('activity')) {
      displayType = 'Activity Partner';
    } else {
      displayType = 'Friendship';
    }

    final createdAtStr = map['last_message_at'] ?? map['created_at'];
    DateTime? dt;
    if (createdAtStr != null) {
      dt = DateTime.tryParse(createdAtStr.toString());
    }

    final rawLastMessage = (map['last_message'] as String?)?.trim();
    final lastMessage = (rawLastMessage != null && rawLastMessage.isNotEmpty)
        ? rawLastMessage
        : '';

    return InboxThreadModel(
      conversationId: map['conversation_id']?.toString() ?? '',
      connectionId: map['connection_id']?.toString(),
      partnerId: map['partner_id']?.toString() ?? '',
      participantName:
          (map['partner_name'] as String?)?.trim().isNotEmpty == true
          ? (map['partner_name'] as String).trim()
          : 'MELSAVA Member',
      participantAvatar: (map['partner_avatar'] as String?)?.trim() ?? '',
      connectionType: displayType,
      experienceName:
          (map['experience_title'] as String?)?.trim().isNotEmpty == true
          ? (map['experience_title'] as String).trim()
          : 'Shared Experience',
      lastMessage: lastMessage,
      lastMessageAt: dt,
      timestamp: _formatTimeAgo(dt),
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      isOnline: map['is_online'] == true,
    );
  }
}

/// Represents an individual message in a chat conversation.
class ChatMessageModel {
  final String id;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final bool isMe;
  final String time;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.isMe,
    required this.time,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    final dt =
        DateTime.tryParse(map['created_at']?.toString() ?? '') ??
        DateTime.now();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    final senderId = map['sender_id']?.toString() ?? '';
    final currentUid = SupabaseService.client?.auth.currentUser?.id;
    final isMe =
        map['is_me'] == true ||
        (currentUid != null && senderId.isNotEmpty && senderId == currentUid);

    return ChatMessageModel(
      id: map['message_id']?.toString() ?? map['id']?.toString() ?? '',
      senderId: senderId,
      content: map['content']?.toString() ?? '',
      isRead: map['is_read'] == true,
      createdAt: dt,
      isMe: isMe,
      time: '$hour:$minute $period',
    );
  }

  ChatMessageModel copyWith({bool? isRead}) {
    return ChatMessageModel(
      id: id,
      senderId: senderId,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      isMe: isMe,
      time: time,
    );
  }
}

String _formatTimeAgo(DateTime? dt) {
  if (dt == null) return 'Recent';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

/// Represents a blocked user profile.
class BlockedUserModel {
  final String blockedId;
  final String displayName;
  final String avatarUrl;
  final DateTime? blockedAt;

  const BlockedUserModel({
    required this.blockedId,
    required this.displayName,
    required this.avatarUrl,
    this.blockedAt,
  });

  factory BlockedUserModel.fromMap(Map<String, dynamic> map) {
    DateTime? dt;
    final rawDt = map['blocked_at'] ?? map['created_at'];
    if (rawDt != null) {
      dt = DateTime.tryParse(rawDt.toString());
    }
    return BlockedUserModel(
      blockedId: map['blocked_id']?.toString() ?? '',
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : 'MELSAVA Member',
      avatarUrl: (map['avatar_url'] as String?)?.trim() ?? '',
      blockedAt: dt,
    );
  }
}

/// Represents a submitted community moderation report.
class ModerationReportModel {
  final String reportId;
  final String reportedUserId;
  final String reportedName;
  final String reportedAvatar;
  final String reportedContentType;
  final String? reportedContentId;
  final String reason;
  final String? description;
  final String status;
  final DateTime? createdAt;

  const ModerationReportModel({
    required this.reportId,
    required this.reportedUserId,
    required this.reportedName,
    required this.reportedAvatar,
    required this.reportedContentType,
    this.reportedContentId,
    required this.reason,
    this.description,
    required this.status,
    this.createdAt,
  });

  factory ModerationReportModel.fromMap(Map<String, dynamic> map) {
    DateTime? dt;
    final rawDt = map['created_at'];
    if (rawDt != null) {
      dt = DateTime.tryParse(rawDt.toString());
    }
    return ModerationReportModel(
      reportId: map['report_id']?.toString() ?? map['id']?.toString() ?? '',
      reportedUserId: map['reported_user_id']?.toString() ?? '',
      reportedName: (map['reported_name'] as String?)?.trim().isNotEmpty == true
          ? (map['reported_name'] as String).trim()
          : 'MELSAVA Member',
      reportedAvatar: (map['reported_avatar'] as String?)?.trim() ?? '',
      reportedContentType:
          map['reported_content_type']?.toString() ?? 'profile',
      reportedContentId: map['reported_content_id']?.toString(),
      reason: map['reason']?.toString() ?? 'Other concern',
      description: map['description']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt: dt,
    );
  }
}

/// Contract for connections and messaging data.
abstract class ConnectionsRepository {
  Future<List<ConnectionModel>> fetchConnections();
  Future<List<InboxThreadModel>> fetchInboxThreads();
  Future<List<ChatMessageModel>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  });
  Future<bool> sendMessage(String conversationId, String content);
  Future<int> markConversationRead(String conversationId);
  Future<String?> getOrCreateConversation(String connectionId);
  Future<List<BlockedUserModel>> fetchBlockedUsers();
  Future<bool> blockUser(String partnerId);
  Future<bool> unblockUser(String blockedId);
  Future<bool> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? contentType,
    String? contentId,
    String? conversationId,
  });
  Future<bool> isCurrentUserModerator();
  Future<List<ModerationReportModel>> fetchModerationReports({
    String status = 'pending',
  });
  Future<bool> resolveModerationReport(String reportId, String status);
  Future<bool> applyModerationAction({
    required String userId,
    required String actionType,
    required String reason,
    String? reportId,
    DateTime? expiresAt,
  });
  RealtimeChannel? subscribeToConversationMessages({
    required String conversationId,
    required void Function(ChatMessageModel message) onMessageInserted,
    required void Function(String messageId, bool isRead) onMessageUpdated,
  });
  void unsubscribe(RealtimeChannel channel);
}

/// Production Supabase-backed implementation of [ConnectionsRepository].
class SupabaseConnectionsRepository implements ConnectionsRepository {
  bool get _hasLiveSupabase =>
      SupabaseService.isConfigured && SupabaseService.client != null;

  SupabaseClient? get _client => SupabaseService.client;

  @override
  Future<List<ConnectionModel>> fetchConnections() async {
    if (!_hasLiveSupabase) return const [];

    try {
      final rows = await _client!.rpc('get_user_connections');
      if (rows is List) {
        return rows
            .whereType<Map>()
            .map((r) => ConnectionModel.fromMap(Map<String, dynamic>.from(r)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[ConnectionsRepository] fetchConnections RPC error: $e');
      rethrow;
    }
  }

  @override
  Future<List<InboxThreadModel>> fetchInboxThreads() async {
    if (!_hasLiveSupabase) return const [];

    try {
      final rows = await _client!.rpc('get_user_inbox_threads');
      if (rows is List) {
        return rows
            .whereType<Map>()
            .map((r) => InboxThreadModel.fromMap(Map<String, dynamic>.from(r)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[ConnectionsRepository] fetchInboxThreads RPC error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChatMessageModel>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    if (!_hasLiveSupabase || conversationId.isEmpty) return const [];

    try {
      final rows = await _client!.rpc(
        'get_conversation_messages',
        params: {
          'p_conversation_id': conversationId,
          'p_limit': limit,
          if (before != null) 'p_before': before.toIso8601String(),
        },
      );
      if (rows is List) {
        return rows
            .whereType<Map>()
            .map((r) => ChatMessageModel.fromMap(Map<String, dynamic>.from(r)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[ConnectionsRepository] fetchMessages RPC error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> sendMessage(String conversationId, String content) async {
    if (!_hasLiveSupabase || conversationId.isEmpty || content.trim().isEmpty) {
      return false;
    }

    try {
      final res = await _client!.rpc(
        'send_conversation_message',
        params: {
          'p_conversation_id': conversationId,
          'p_content': content.trim(),
        },
      );
      return res != null && res['success'] == true;
    } catch (e) {
      debugPrint('[ConnectionsRepository] sendMessage RPC error: $e');
      rethrow;
    }
  }

  @override
  Future<int> markConversationRead(String conversationId) async {
    if (!_hasLiveSupabase || conversationId.isEmpty) return 0;

    try {
      final res = await _client!.rpc(
        'mark_conversation_read',
        params: {'p_conversation_id': conversationId},
      );
      return (res as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('[ConnectionsRepository] markConversationRead RPC error: $e');
      return 0;
    }
  }

  @override
  Future<String?> getOrCreateConversation(String connectionId) async {
    if (!_hasLiveSupabase || connectionId.isEmpty) return null;
    try {
      final res = await _client!.rpc(
        'get_or_create_conversation_for_connection',
        params: {'p_connection_id': connectionId},
      );
      return res?.toString();
    } catch (e) {
      debugPrint(
        '[ConnectionsRepository] getOrCreateConversation RPC error: $e',
      );
      rethrow;
    }
  }

  @override
  Future<List<BlockedUserModel>> fetchBlockedUsers() async {
    if (!_hasLiveSupabase) return const [];
    try {
      final rows = await _client!.rpc('get_blocked_users');
      if (rows is List) {
        return rows
            .whereType<Map>()
            .map((r) => BlockedUserModel.fromMap(Map<String, dynamic>.from(r)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[ConnectionsRepository] fetchBlockedUsers error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> blockUser(String partnerId) async {
    if (!_hasLiveSupabase || partnerId.isEmpty) return false;
    try {
      final res = await _client!.rpc(
        'block_user',
        params: {'p_blocked_id': partnerId},
      );
      return res == true;
    } catch (e) {
      debugPrint('[ConnectionsRepository] blockUser RPC error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> unblockUser(String blockedId) async {
    if (!_hasLiveSupabase || blockedId.isEmpty) return false;
    try {
      final res = await _client!.rpc(
        'unblock_user',
        params: {'p_blocked_id': blockedId},
      );
      return res == true;
    } catch (e) {
      debugPrint('[ConnectionsRepository] unblockUser RPC error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? contentType,
    String? contentId,
    String? conversationId,
  }) async {
    if (!_hasLiveSupabase || reportedUserId.isEmpty) return false;
    final finalContentType =
        contentType ?? (conversationId != null ? 'conversation' : 'profile');
    final finalContentId = contentId ?? conversationId;

    try {
      final res = await _client!.rpc(
        'submit_user_report',
        params: {
          'p_reported_user_id': reportedUserId,
          'p_reason': reason,
          if (description != null && description.isNotEmpty)
            'p_description': description,
          'p_content_type': finalContentType,
          if (finalContentId != null && finalContentId.isNotEmpty)
            'p_content_id': finalContentId,
        },
      );
      return res != null && res['success'] == true;
    } catch (e) {
      debugPrint('[ConnectionsRepository] submit_user_report RPC error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isCurrentUserModerator() async {
    if (!_hasLiveSupabase) return false;
    try {
      final res = await _client!.rpc('is_moderator');
      return res == true;
    } catch (e) {
      debugPrint('[ConnectionsRepository] is_moderator error: $e');
      return false;
    }
  }

  @override
  Future<List<ModerationReportModel>> fetchModerationReports({
    String status = 'pending',
  }) async {
    if (!_hasLiveSupabase) return const [];
    try {
      final rows = await _client!.rpc(
        'get_moderation_reports',
        params: {'p_status': status},
      );
      if (rows is List) {
        return rows
            .whereType<Map>()
            .map(
              (r) =>
                  ModerationReportModel.fromMap(Map<String, dynamic>.from(r)),
            )
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[ConnectionsRepository] fetchModerationReports error: $e');
      return const [];
    }
  }

  @override
  Future<bool> resolveModerationReport(String reportId, String status) async {
    if (!_hasLiveSupabase || reportId.isEmpty) return false;
    try {
      final res = await _client!.rpc(
        'resolve_moderation_report',
        params: {'p_report_id': reportId, 'p_new_status': status},
      );
      return res == true;
    } catch (e) {
      debugPrint('[ConnectionsRepository] resolveModerationReport error: $e');
      return false;
    }
  }

  @override
  Future<bool> applyModerationAction({
    required String userId,
    required String actionType,
    required String reason,
    String? reportId,
    DateTime? expiresAt,
  }) async {
    if (!_hasLiveSupabase || userId.isEmpty) return false;
    try {
      final res = await _client!.rpc(
        'apply_moderation_action',
        params: {
          'p_user_id': userId,
          'p_action_type': actionType,
          'p_reason': reason,
          if (reportId != null && reportId.isNotEmpty) 'p_report_id': reportId,
          if (expiresAt != null) 'p_expires_at': expiresAt.toIso8601String(),
        },
      );
      return res != null && res['success'] == true;
    } catch (e) {
      debugPrint('[ConnectionsRepository] applyModerationAction error: $e');
      return false;
    }
  }

  @override
  RealtimeChannel? subscribeToConversationMessages({
    required String conversationId,
    required void Function(ChatMessageModel message) onMessageInserted,
    required void Function(String messageId, bool isRead) onMessageUpdated,
  }) {
    if (!_hasLiveSupabase || conversationId.isEmpty) return null;

    final channel = _client!.channel('chat:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final msg = ChatMessageModel.fromMap(newRecord);
              onMessageInserted(msg);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final msgId =
                newRecord['id']?.toString() ??
                newRecord['message_id']?.toString() ??
                '';
            final isRead = newRecord['is_read'] == true;
            if (msgId.isNotEmpty) {
              onMessageUpdated(msgId, isRead);
            }
          },
        )
        .subscribe();

    return channel;
  }

  @override
  void unsubscribe(RealtimeChannel channel) {
    if (_client != null) {
      _client!.removeChannel(channel);
    }
  }
}

// ----------------------------------------------------------------------------
// Riverpod Providers
// ----------------------------------------------------------------------------

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return SupabaseConnectionsRepository();
});

final userConnectionsProvider =
    FutureProvider.autoDispose<List<ConnectionModel>>((ref) async {
      final repo = ref.watch(connectionsRepositoryProvider);
      return repo.fetchConnections();
    });

final inboxThreadsProvider = FutureProvider.autoDispose<List<InboxThreadModel>>(
  (ref) async {
    final repo = ref.watch(connectionsRepositoryProvider);
    return repo.fetchInboxThreads();
  },
);

final conversationMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessageModel>, String>((ref, conversationId) async {
      final repo = ref.watch(connectionsRepositoryProvider);
      return repo.fetchMessages(conversationId);
    });

final blockedUsersProvider = FutureProvider.autoDispose<List<BlockedUserModel>>(
  (ref) async {
    final repo = ref.watch(connectionsRepositoryProvider);
    return repo.fetchBlockedUsers();
  },
);

final isModeratorProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(connectionsRepositoryProvider);
  return repo.isCurrentUserModerator();
});

final moderationReportsProvider = FutureProvider.autoDispose
    .family<List<ModerationReportModel>, String>((ref, status) async {
      final repo = ref.watch(connectionsRepositoryProvider);
      return repo.fetchModerationReports(status: status);
    });
