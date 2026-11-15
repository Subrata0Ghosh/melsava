import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/report_dialog.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });
}

class ConversationScreen extends StatefulWidget {
  final String participantName;

  const ConversationScreen({super.key, required this.participantName});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    const ChatMessage(
      text: 'Hey! Loved the coffee discussion yesterday.',
      isMe: false,
      time: '4:15 PM',
    ),
    const ChatMessage(
      text:
          'Hey Rhea! Yes, Subko was a fantastic venue choice. Have you read that book you mentioned?',
      isMe: true,
      time: '4:18 PM',
    ),
    const ChatMessage(
      text:
          'Just started chapter three! Really enjoying the conversational tone.',
      isMe: false,
      time: '4:22 PM',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true, time: 'Just now'));
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.participantName,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Mutual Connection • Online',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.mauve,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.deepPlum),
            onSelected: (value) {
              if (value == 'report') {
                ReportDialog.show(
                  context,
                  targetTitle: widget.participantName,
                  onSubmit: (reason, desc) {
                    // Report logged
                  },
                );
              } else if (value == 'block') {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                ConfirmationDialog.show(
                  context,
                  title: 'Block ${widget.participantName}?',
                  message:
                      'They will no longer be able to message you, view your profile, or be paired in the same small experience groups.',
                  confirmLabel: 'Block',
                  isDestructive: true,
                ).then((confirmed) {
                  if (confirmed == true && mounted) {
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '${widget.participantName} has been blocked.',
                        ),
                      ),
                    );
                  }
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 18,
                      color: AppColors.deepPlum,
                    ),
                    SizedBox(width: 8),
                    Text('Report Conversation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      Icons.block_outlined,
                      size: 18,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Block User',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Safety context banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLG,
              vertical: 8,
            ),
            color: AppColors.sage.withOpacity(0.4),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: AppColors.mauve,
                ),
                const SizedBox(width: AppConstants.spacingSM),
                Expanded(
                  child: Text(
                    'You both mutually reconnected after your experience. Keep chats respectful.',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.deepPlum,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.spacingSM,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMD,
                      vertical: AppConstants.spacingSM + 2,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isMe ? AppColors.deepPlum : AppColors.white,
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadiusSmall,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepPlum.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: msg.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: AppTypography.bodyMedium.copyWith(
                            color: msg.isMe
                                ? AppColors.white
                                : AppColors.deepPlum,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          msg.time,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: msg.isMe
                                ? AppColors.white.withOpacity(0.7)
                                : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMD,
              vertical: AppConstants.spacingSM,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mutedText,
                        ),
                        filled: true,
                        fillColor: AppColors.warmIvory,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSM),
                  CircleAvatar(
                    backgroundColor: AppColors.mauve,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
