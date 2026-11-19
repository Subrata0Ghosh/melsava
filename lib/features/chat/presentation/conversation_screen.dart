import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../connections/data/connections_repository.dart';

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

class ConversationScreen extends ConsumerStatefulWidget {
  final String participantName;
  final String? conversationId;
  final String? connectionId;
  final String? partnerAvatar;
  final String? partnerId;

  const ConversationScreen({
    super.key,
    required this.participantName,
    this.conversationId,
    this.connectionId,
    this.partnerAvatar,
    this.partnerId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _optimisticMessages = [];
  String? _activeConversationId;
  bool _isSending = false;

  // Fallback messages for preview / demo when no live conversation exists
  final List<ChatMessage> _fallbackMessages = [
    const ChatMessage(
      text: 'That was an amazing experience! 😊',
      isMe: false,
      time: '7:20 PM',
    ),
    const ChatMessage(
      text: "Yes! Let's definitely do more together.",
      isMe: true,
      time: '7:22 PM',
    ),
  ];

  static const List<String> _icebreakers = [
    'Hey! It was great connecting at the meetup! 👋',
    'What was your favorite moment from the experience?',
    'Would love to join another activity together soon! ☕',
  ];

  @override
  void initState() {
    super.initState();
    _activeConversationId = widget.conversationId;
    if ((_activeConversationId == null || _activeConversationId!.isEmpty) &&
        widget.connectionId != null &&
        widget.connectionId!.isNotEmpty) {
      _resolveConversation();
    }
  }

  Future<void> _resolveConversation() async {
    try {
      final convId = await ref
          .read(connectionsRepositoryProvider)
          .getOrCreateConversation(widget.connectionId!);
      if (convId != null && mounted) {
        setState(() {
          _activeConversationId = convId;
        });
      }
    } catch (e) {
      debugPrint('[ConversationScreen] Error resolving conversation: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    HapticFeedback.lightImpact();
    if (presetText == null) {
      _messageController.clear();
    }

    String? targetConvId = _activeConversationId;
    if ((targetConvId == null || targetConvId.isEmpty) &&
        widget.connectionId != null &&
        widget.connectionId!.isNotEmpty) {
      targetConvId = await ref
          .read(connectionsRepositoryProvider)
          .getOrCreateConversation(widget.connectionId!);
      if (targetConvId != null && mounted) {
        setState(() {
          _activeConversationId = targetConvId;
        });
      }
    }

    final hasLiveConv = targetConvId != null && targetConvId.isNotEmpty;

    if (hasLiveConv) {
      setState(() {
        _isSending = true;
        _optimisticMessages.add(
          ChatMessage(text: text, isMe: true, time: 'Just now'),
        );
      });
      _scrollToBottom();

      try {
        final success = await ref
            .read(connectionsRepositoryProvider)
            .sendMessage(targetConvId, text);

        if (mounted) {
          if (success) {
            ref.invalidate(conversationMessagesProvider(targetConvId));
            ref.invalidate(inboxThreadsProvider);
            ref.invalidate(userConnectionsProvider);
          }
          setState(() {
            _optimisticMessages.clear();
            _isSending = false;
          });
          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    } else {
      // Local demo fallback
      setState(() {
        _fallbackMessages.add(
          ChatMessage(text: text, isMe: true, time: 'Just now'),
        );
      });
      _scrollToBottom();
    }
  }

  String _resolveAvatarPath() {
    if (widget.partnerAvatar != null &&
        widget.partnerAvatar!.trim().isNotEmpty) {
      return widget.partnerAvatar!.trim();
    }
    if (widget.participantName.toLowerCase().contains('rohan')) {
      return 'assets/images/rohan_avatar.png';
    }
    return 'assets/images/sneha_avatar.png';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    final avatarPath = _resolveAvatarPath();
    final hasLiveConv =
        _activeConversationId != null && _activeConversationId!.isNotEmpty;

    final messagesAsync = hasLiveConv
        ? ref.watch(conversationMessagesProvider(_activeConversationId!))
        : null;

    final List<ChatMessage> displayMessages;
    if (hasLiveConv) {
      final live = messagesAsync?.valueOrNull ?? [];
      displayMessages = [
        ...live.map(
          (m) => ChatMessage(text: m.content, isMe: m.isMe, time: m.time),
        ),
        ..._optimisticMessages,
      ];
    } else {
      displayMessages = _fallbackMessages;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.brightViolet
                      : AppColors.primaryPurple,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: AppSmartImage(
                  imagePath: avatarPath,
                  isAvatar: true,
                  nameHint: widget.participantName,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.participantName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: primaryTextColor,
                  ),
                ),
                Text(
                  'Connected Peer',
                  style: AppTypography.bodySmall.copyWith(
                    color: mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
            onSelected: (value) async {
              if (value == 'report') {
                ReportDialog.show(
                  context,
                  targetTitle: widget.participantName,
                  onSubmit: (reason, desc) async {
                    if (widget.partnerId != null &&
                        widget.partnerId!.isNotEmpty) {
                      await ref
                          .read(connectionsRepositoryProvider)
                          .reportUser(
                            reportedUserId: widget.partnerId!,
                            reason: reason,
                            description: desc,
                            conversationId: _activeConversationId,
                          );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Report submitted to MELSAVA Safety Team.',
                          ),
                        ),
                      );
                    }
                  },
                );
              } else if (value == 'block') {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: 'Block ${widget.participantName}?',
                  message:
                      'They will no longer be able to message you, view your profile, or be paired in the same small experience groups.',
                  confirmLabel: 'Block',
                  isDestructive: true,
                );

                if (confirmed == true && mounted) {
                  if (widget.partnerId != null &&
                      widget.partnerId!.isNotEmpty) {
                    await ref
                        .read(connectionsRepositoryProvider)
                        .blockUser(widget.partnerId!);
                    ref.invalidate(userConnectionsProvider);
                    ref.invalidate(inboxThreadsProvider);
                  }
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.participantName} has been blocked.',
                      ),
                    ),
                  );
                }
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
                    Text(
                      'Report Conversation',
                      style: TextStyle(color: primaryTextColor),
                    ),
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
              border: Border(
                bottom: BorderSide(color: borderColor, width: 0.8),
              ),
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

          // Messages list or empty conversation icebreaker state
          Expanded(
            child:
                (hasLiveConv &&
                    messagesAsync != null &&
                    messagesAsync.isLoading &&
                    !messagesAsync.hasValue)
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPurple,
                      ),
                    ),
                  )
                : displayMessages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.purpleGradient.scale(0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPurple.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: AppSmartImage(
                                imagePath: avatarPath,
                                isAvatar: true,
                                nameHint: widget.participantName,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Say hello to ${widget.participantName}!',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You both mutually reconnected after your shared experience. Send an icebreaker to start chatting!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'ICEBREAKER SUGGESTIONS',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.luminousMauve
                                  : AppColors.primaryPurple,
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._icebreakers.map(
                            (prompt) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _sendMessage(prompt),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.primaryPurple.withValues(
                                              alpha: 0.2,
                                            ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 15,
                                        color: isDark
                                            ? AppColors.brightViolet
                                            : AppColors.primaryPurple,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          prompt,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: primaryTextColor,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.send_rounded,
                                        size: 13,
                                        color: mutedTextColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: displayMessages.length,
                    itemBuilder: (context, index) {
                      final msg = displayMessages[index];
                      final msgTextColor = msg.isMe
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.deepPlum);

                      final bubble = Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.74,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          gradient: msg.isMe ? AppColors.purpleGradient : null,
                          color: msg.isMe
                              ? null
                              : (isDark
                                    ? AppColors.darkSurface
                                    : AppColors.white),
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
                                  ? AppColors.primaryPurple.withValues(
                                      alpha: 0.25,
                                    )
                                  : (isDark
                                        ? Colors.black26
                                        : Colors.black.withValues(alpha: 0.04)),
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
                      );

                      if (msg.isMe) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: bubble,
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(right: 8, top: 4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: AppSmartImage(
                                    imagePath: avatarPath,
                                    isAvatar: true,
                                    nameHint: widget.participantName,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              bubble,
                            ],
                          ),
                        );
                      }
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
                        fillColor: isDark
                            ? AppColors.darkElevated
                            : AppColors.warmIvory,
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
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : const Icon(
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
