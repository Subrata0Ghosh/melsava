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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Inbox',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: _threads.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'No conversations yet',
                message:
                    'Enjoyed meeting someone? Your mutual connections and conversations will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.only(
                  left: AppConstants.spacingLG,
                  right: AppConstants.spacingLG,
                  top: AppConstants.spacingMD,
                  bottom: 100, // Bottom padding for glassmorphic navbar
                ),
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
                        color: cardBg,
                        borderRadius: BorderRadius.circular(
                          AppConstants.cardRadiusSmall,
                        ),
                        border: Border.all(color: borderColor, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : AppColors.deepPlum.withValues(alpha: 0.04),
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
                                      color: isDark
                                          ? AppColors.luminousMauve
                                          : AppColors.mauve,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: cardBg,
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
                                        color: primaryTextColor,
                                        fontWeight: thread.isUnread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      thread.timestamp,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: mutedTextColor,
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
                                        ? (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.deepPlum)
                                        : mutedTextColor,
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
