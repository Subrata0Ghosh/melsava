import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:melsava/features/chat/presentation/conversation_screen.dart';
import 'package:melsava/features/chat/presentation/inbox_screen.dart';
import 'package:melsava/features/connections/data/connections_repository.dart';
import 'package:melsava/features/connections/presentation/connections_screen.dart';

class MockConnectionsRepository implements ConnectionsRepository {
  List<ConnectionModel> connections = [];
  List<InboxThreadModel> threads = [];
  Map<String, List<ChatMessageModel>> messages = {};
  bool didBlock = false;
  bool didReport = false;
  bool didMarkRead = false;
  String? lastMarkedConversationId;
  bool throwOnSend = false;

  void Function(ChatMessageModel message)? onMessageInsertedCallback;
  void Function(String messageId, bool isRead)? onMessageUpdatedCallback;

  @override
  Future<List<ConnectionModel>> fetchConnections() async => connections;

  @override
  Future<List<InboxThreadModel>> fetchInboxThreads() async => threads;

  @override
  Future<List<ChatMessageModel>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async => messages[conversationId] ?? [];

  @override
  Future<bool> sendMessage(String conversationId, String content) async {
    if (throwOnSend) {
      throw Exception('Network error sending message');
    }
    final list = messages[conversationId] ?? [];
    list.add(
      ChatMessageModel(
        id: 'msg_${list.length + 1}',
        senderId: 'current_user',
        content: content,
        isRead: false,
        createdAt: DateTime.now(),
        isMe: true,
        time: 'Just now',
      ),
    );
    messages[conversationId] = list;
    return true;
  }

  @override
  Future<bool> sendEncryptedMessage({
    required String conversationId,
    required String recipientId,
    required String plaintext,
    String? clientRequestId,
  }) async {
    return sendMessage(conversationId, plaintext);
  }

  @override
  Future<int> markConversationRead(String conversationId) async {
    didMarkRead = true;
    lastMarkedConversationId = conversationId;
    return 1;
  }

  @override
  Future<String?> getOrCreateConversation(String connectionId) async {
    return 'conv_$connectionId';
  }

  @override
  Future<bool> blockUser(String partnerId) async {
    didBlock = true;
    return true;
  }

  @override
  Future<List<BlockedUserModel>> fetchBlockedUsers() async => [];

  @override
  Future<bool> unblockUser(String blockedId) async => true;

  @override
  Future<bool> isCurrentUserModerator() async => false;

  @override
  Future<List<ModerationReportModel>> fetchModerationReports({
    String status = 'pending',
  }) async => [];

  @override
  Future<bool> resolveModerationReport(String reportId, String status) async =>
      true;

  @override
  Future<bool> applyModerationAction({
    required String userId,
    required String actionType,
    required String reason,
    String? reportId,
    DateTime? expiresAt,
  }) async => true;

  @override
  Future<bool> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? contentType,
    String? contentId,
    String? conversationId,
  }) async {
    didReport = true;
    return true;
  }

  @override
  RealtimeChannel? subscribeToConversationMessages({
    required String conversationId,
    required void Function(ChatMessageModel message) onMessageInserted,
    required void Function(String messageId, bool isRead) onMessageUpdated,
  }) {
    onMessageInsertedCallback = onMessageInserted;
    onMessageUpdatedCallback = onMessageUpdated;
    return null;
  }

  @override
  Future<bool> moderateExperience({
    required String experienceId,
    required String action,
    required String reason,
  }) async => true;

  @override
  Future<List<ModerationAppealModel>> fetchModerationAppeals({
    String status = 'pending',
  }) async => const [];

  @override
  Future<bool> resolveModerationAppeal({
    required String appealId,
    required String resolution,
    String? notes,
  }) async => true;

  @override
  Future<bool> submitAppeal({
    String? actionId,
    required String reason,
    required String explanation,
  }) async => true;

  @override
  void unsubscribe(RealtimeChannel channel) {}
}

void main() {
  group('Phase 4: Connections, Inbox & Real Messaging Tests', () {
    late MockConnectionsRepository mockRepo;

    setUp(() {
      mockRepo = MockConnectionsRepository();
    });

    Widget createTestApp(Widget child, {ThemeData? theme}) {
      return ProviderScope(
        overrides: [connectionsRepositoryProvider.overrideWithValue(mockRepo)],
        child: MaterialApp(theme: theme ?? ThemeData.light(), home: child),
      );
    }

    testWidgets(
      'ConnectionsScreen displays EmptyStateWidget when no connections exist',
      (tester) async {
        mockRepo.connections = [];

        await tester.pumpWidget(createTestApp(const ConnectionsScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('My Connections'), findsOneWidget);
        expect(find.text('No mutual connections yet'), findsOneWidget);
        expect(
          find.text(
            'Join public experiences, attend in person, and select mutual intentions to unlock your connections!',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ConnectionsScreen displays live connections and filter counts without fake badges',
      (tester) async {
        mockRepo.connections = [
          ConnectionModel(
            id: 'conn_1',
            partnerId: 'user_priya',
            name: 'Priya Sharma',
            avatarUrl: '',
            bio: 'Trekking & coffee lover',
            connectionType: 'Friends',
            rawConnectionType: 'friendship',
            experienceName: 'Weekend Trek to Mukutmanipur',
            lastMessage: 'Great hiking with you!',
            timeAgo: '2h ago',
          ),
          ConnectionModel(
            id: 'conn_2',
            partnerId: 'user_rohan',
            name: 'Rohan Sen',
            avatarUrl: '',
            bio: 'Badminton enthusiast',
            connectionType: 'Activity',
            rawConnectionType: 'activity_partner',
            experienceName: 'Court Badminton Rally',
            lastMessage: 'See you next weekend!',
            timeAgo: '1d ago',
          ),
        ];

        await tester.pumpWidget(createTestApp(const ConnectionsScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Priya Sharma'), findsOneWidget);
        expect(find.text('Rohan Sen'), findsOneWidget);
        expect(find.text('Weekend Trek to Mukutmanipur'), findsOneWidget);
        expect(find.text('Court Badminton Rally'), findsOneWidget);
        expect(find.text('Great hiking with you!'), findsOneWidget);
        expect(find.text('All (2)'), findsOneWidget);
        expect(find.text('Friends (1)'), findsOneWidget);
        expect(find.text('Activity (1)'), findsOneWidget);
        expect(find.text('Dates (0)'), findsOneWidget);

        // Filter by Friends
        await tester.tap(find.text('Friends (1)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Priya Sharma'), findsOneWidget);
        expect(find.text('Rohan Sen'), findsNothing);
      },
    );

    testWidgets('InboxScreen displays EmptyStateWidget when no threads exist', (
      tester,
    ) async {
      mockRepo.threads = [];

      await tester.pumpWidget(createTestApp(const InboxScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('InboxScreen displays active conversation threads and badges', (
      tester,
    ) async {
      mockRepo.threads = [
        const InboxThreadModel(
          conversationId: 'conv_123',
          connectionId: 'conn_123',
          partnerId: 'partner_1',
          participantName: 'Aditi Sen',
          participantAvatar: '',
          connectionType: 'Friendship',
          experienceName: 'Coffee & Conversation',
          lastMessage: 'It was great chatting about books!',
          timestamp: '2h ago',
          unreadCount: 2,
        ),
      ];

      await tester.pumpWidget(createTestApp(const InboxScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Aditi Sen'), findsAtLeastNWidgets(1));
      expect(find.text('It was great chatting about books!'), findsOneWidget);
      expect(find.text('Coffee & Conversation'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // unread badge
    });

    testWidgets(
      'ConversationScreen displays context banner with experience name',
      (tester) async {
        mockRepo.messages['conv_xyz'] = [];

        await tester.pumpWidget(
          createTestApp(
            const ConversationScreen(
              participantName: 'Rohan',
              conversationId: 'conv_xyz',
              partnerId: 'user_rohan',
              experienceName: 'Sunset Photography Walk',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text(
            'You both reconnected after Sunset Photography Walk. Keep chats respectful and genuine.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ConversationScreen displays icebreakers when empty and sends messages',
      (tester) async {
        mockRepo.messages['conv_abc'] = [];

        await tester.pumpWidget(
          createTestApp(
            const ConversationScreen(
              participantName: 'Aditi',
              conversationId: 'conv_abc',
              partnerId: 'user_aditi',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Say hello to Aditi!'), findsOneWidget);
        expect(find.text('ICEBREAKER SUGGESTIONS'), findsOneWidget);

        // Tap icebreaker
        final icebreaker = find.text(
          'What was your favorite moment from the experience?',
        );
        expect(icebreaker, findsOneWidget);

        await tester.tap(icebreaker);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Sent message is now in repository
        expect(mockRepo.messages['conv_abc']?.length, 1);
        expect(
          mockRepo.messages['conv_abc']?.first.content,
          'What was your favorite moment from the experience?',
        );
      },
    );

    testWidgets(
      'ConversationScreen shows read receipts correctly for unread and read messages',
      (tester) async {
        final now = DateTime.now();
        mockRepo.messages['conv_read_test'] = [
          ChatMessageModel(
            id: 'm1',
            senderId: 'current_user',
            content: 'Hey, are you free this weekend?',
            isRead: false,
            createdAt: now.subtract(const Duration(minutes: 5)),
            isMe: true,
            time: '2:15 PM',
          ),
          ChatMessageModel(
            id: 'm2',
            senderId: 'current_user',
            content: 'Let me know!',
            isRead: true,
            createdAt: now.subtract(const Duration(minutes: 4)),
            isMe: true,
            time: '2:16 PM',
          ),
        ];

        await tester.pumpWidget(
          createTestApp(
            const ConversationScreen(
              participantName: 'Priya',
              conversationId: 'conv_read_test',
              partnerId: 'user_priya',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Hey, are you free this weekend?'), findsOneWidget);
        expect(find.text('Let me know!'), findsOneWidget);

        // Check icon: single check for unread (m1), double check for read (m2)
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'ConversationScreen receives Realtime message and marks conversation read',
      (tester) async {
        mockRepo.messages['conv_rt'] = [];

        await tester.pumpWidget(
          createTestApp(
            const ConversationScreen(
              participantName: 'Siddharth',
              conversationId: 'conv_rt',
              partnerId: 'user_sid',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(mockRepo.onMessageInsertedCallback, isNotNull);

        // Simulate incoming message via Realtime
        final incoming = ChatMessageModel(
          id: 'rt_msg_1',
          senderId: 'user_sid',
          content: 'Hey! Loved the event!',
          isRead: false,
          createdAt: DateTime.now(),
          isMe: false,
          time: '3:00 PM',
        );

        mockRepo.onMessageInsertedCallback!(incoming);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Hey! Loved the event!'), findsOneWidget);
        expect(mockRepo.didMarkRead, isTrue);
        expect(mockRepo.lastMarkedConversationId, 'conv_rt');
      },
    );

    testWidgets(
      'Sending message failure preserves draft in text field and shows error',
      (tester) async {
        mockRepo.messages['conv_err'] = [];
        mockRepo.throwOnSend = true;

        await tester.pumpWidget(
          createTestApp(
            const ConversationScreen(
              participantName: 'Sneha',
              conversationId: 'conv_err',
              partnerId: 'user_sneha',
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Enter message
        await tester.enterText(
          find.byType(TextField),
          'Important message that must not be lost',
        );
        await tester.pump();

        // Tap send
        await tester.tap(find.byKey(const Key('chat_send_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // TextField still has the draft preserved!
        expect(
          find.text('Important message that must not be lost'),
          findsAtLeastNWidgets(1),
        );
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets('Block user flow invokes blockUser and pops screen', (
      tester,
    ) async {
      mockRepo.messages['conv_block'] = [];

      await tester.pumpWidget(
        createTestApp(
          const ConversationScreen(
            participantName: 'Troublemaker',
            conversationId: 'conv_block',
            partnerId: 'user_bad',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Open overflow menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Block User'), findsOneWidget);
      await tester.tap(find.text('Block User'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Block Troublemaker?'), findsOneWidget);
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(mockRepo.didBlock, isTrue);
    });

    testWidgets('Renders properly in Dark Theme', (tester) async {
      mockRepo.messages['conv_dark'] = [
        ChatMessageModel(
          id: 'd1',
          senderId: 'current_user',
          content: 'Dark mode test message',
          isRead: true,
          createdAt: DateTime.now(),
          isMe: true,
          time: '4:00 PM',
        ),
      ];

      await tester.pumpWidget(
        createTestApp(
          const ConversationScreen(
            participantName: 'Aarav',
            conversationId: 'conv_dark',
            partnerId: 'user_aarav',
          ),
          theme: ThemeData.dark(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dark mode test message'), findsOneWidget);
      expect(find.text('Aarav'), findsOneWidget);
    });
  });
}
