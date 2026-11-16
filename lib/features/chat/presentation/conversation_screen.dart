import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
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

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true, time: 'Just now'));
      _messageController.clear();
    });
  }

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
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.participantName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.mintAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Mutual Connection • Online',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: primaryTextColor),
            color: isDark ? AppColors.darkElevated : AppColors.white,
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
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 18,
                      color: primaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text('Report Conversation', style: TextStyle(color: primaryTextColor)),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkElevated : AppColors.sage)
                  .withValues(alpha: 0.4),
              border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You both mutually reconnected after your meetup. Keep chats respectful and genuine.',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final msgTextColor = msg.isMe
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum);

                return Align(
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: msg.isMe ? AppColors.purpleGradient : null,
                      color: msg.isMe
                          ? null
                          : (isDark ? AppColors.darkSurface : AppColors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
                        bottomRight: Radius.circular(msg.isMe ? 4 : 18),
                      ),
                      border: msg.isMe
                          ? null
                          : Border.all(color: borderColor, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: msg.isMe
                              ? AppColors.primaryPurple.withValues(alpha: 0.25)
                              : (isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04)),
                          blurRadius: 8,
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
                            color: msgTextColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg.time,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: msg.isMe
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : mutedTextColor,
                              ),
                            ),
                            if (msg.isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ],
                          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: borderColor, width: 0.9)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: primaryTextColor,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: mutedTextColor,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkElevated : AppColors.warmIvory,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
