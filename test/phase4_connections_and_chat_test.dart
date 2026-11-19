import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<List<ConnectionModel>> fetchConnections() async => connections;

  @override
  Future<List<InboxThreadModel>> fetchInboxThreads() async => threads;

  @override
  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async =>
      messages[conversationId] ?? [];

  @override
  Future<bool> sendMessage(String conversationId, String content) async {
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
  Future<String?> getOrCreateConversation(String connectionId) async {
    return 'conv_$connectionId';
  }

  @override
  Future<bool> blockUser(String partnerId) async {
    didBlock = true;
    return true;
  }

  @override
  Future<bool> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? conversationId,
  }) async {
    didReport = true;
    return true;
  }
}

void main() {
  group('Phase 4: Connections, Inbox & Real Messaging Tests', () {
    late MockConnectionsRepository mockRepo;

    setUp(() {
      mockRepo = MockConnectionsRepository();
    });

    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          connectionsRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: child,
        ),
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
      'ConnectionsScreen displays live connections and filter counts',
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

    testWidgets(
      'InboxScreen displays EmptyStateWidget when no threads exist',
      (tester) async {
        mockRepo.threads = [];

        await tester.pumpWidget(createTestApp(const InboxScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Inbox'), findsOneWidget);
        expect(find.text('No conversations yet'), findsOneWidget);
      },
    );

    testWidgets(
      'InboxScreen displays active conversation threads and badges',
      (tester) async {
        mockRepo.threads = [
          const InboxThreadModel(
            conversationId: 'conv_123',
            partnerId: 'partner_1',
            participantName: 'Aditi Sen',
            participantAvatar: '',
            connectionType: 'Friendship',
            experienceName: 'Coffee & Conversation',
            lastMessage: 'It was great chatting about books!',
            timestamp: '2h ago',
            unreadCount: 1,
          ),
        ];

        await tester.pumpWidget(createTestApp(const InboxScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Aditi Sen'), findsAtLeastNWidgets(1));
        expect(
          find.text('It was great chatting about books!'),
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

        // Sent message is now in repository and displayed
        expect(mockRepo.messages['conv_abc']?.length, 1);
        expect(
          mockRepo.messages['conv_abc']?.first.content,
          'What was your favorite moment from the experience?',
        );
      },
    );
  });
}
