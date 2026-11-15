import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class ChatThreadPreview {
  final String id;
  final String participantName;
  final String participantAvatar;
  final String lastMessage;
  final String timestamp;
  final bool isUnread;

  const ChatThreadPreview({
    required this.id,
    required this.participantName,
    required this.participantAvatar,
    required this.lastMessage,
    required this.timestamp,
    this.isUnread = false,
  });
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final List<ChatThreadPreview> _threads = [
    const ChatThreadPreview(
      id: 'thread-1',
      participantName: 'Rhea Sen',
      participantAvatar:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
      lastMessage:
          'It was great chatting about architectural photography today!',
      timestamp: '2h ago',
      isUnread: true,
    ),
    const ChatThreadPreview(
      id: 'thread-2',
      participantName: 'Aarav Mehta',
      participantAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      lastMessage: 'Let\'s rally at the wooden court next Tuesday?',
      timestamp: '1d ago',
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Inbox',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _threads.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'No conversations yet',
                message:
                    'Enjoyed meeting someone? Your mutual connections and conversations will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                itemCount: _threads.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppConstants.spacingMD),
                itemBuilder: (context, index) {
                  final thread = _threads[index];
                  return GestureDetector(
                    onTap: () =>
                        context.push('/chat/${thread.participantName}'),
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.spacingMD),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppConstants.cardRadiusSmall,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepPlum.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(
                                  thread.participantAvatar,
                                ),
                              ),
                              if (thread.isUnread)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.mauve,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: AppConstants.spacingMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      thread.participantName,
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: thread.isUnread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      thread.timestamp,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.mutedText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  thread.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: thread.isUnread
                                        ? AppColors.deepPlum
                                        : AppColors.mutedText,
                                    fontWeight: thread.isUnread
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
