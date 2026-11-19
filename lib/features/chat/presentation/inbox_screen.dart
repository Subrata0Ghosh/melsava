import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../connections/data/connections_repository.dart';

typedef ChatThreadPreview = InboxThreadModel;

/// Screen 5: Inbox Screen
///
/// High-fidelity messaging interface inspired by Mobbin messaging patterns
/// & Proxima social discovery, featuring:
/// - Active Meetups & Connections story rail at the top with gradient rings
/// - Segmented conversation filters (All, Unread, Experiences)
/// - Rich chat tiles with activity context tags and verified indicators
/// - Complete Dark and Light theme adaptability
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Unread, 2: Experiences
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final threadsAsync = ref.watch(inboxThreadsProvider);
    final allThreads = threadsAsync.valueOrNull ?? const [];
    final isLoading = threadsAsync.isLoading && !threadsAsync.hasValue;

    // Filter threads
    final filteredThreads = allThreads.where((t) {
      if (_selectedFilterIndex == 1 && !t.isUnread) return false;
      if (_selectedFilterIndex == 2 && t.experienceName.isEmpty) return false;
      if (_searchQuery.isNotEmpty) {
        return t.participantName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            t.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.experienceName.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inbox',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: primaryTextColor,
              ),
            ),
            Text(
              'MUTUAL CONVERSATIONS',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.2,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.softCoral : AppColors.mauve,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: AmbientNatureBackdrop(
        showTopLeaf: false,
        showBottomLeaf: true,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevated : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          (isDark
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFD97706))
                              .withValues(alpha: 0.28),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFF59E0B,
                        ).withValues(alpha: isDark ? 0.10 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFFC084FC)
                            : const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: AppTypography.bodyMedium.copyWith(
                            color: primaryTextColor,
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search conversations or activities...',
                            hintStyle: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: mutedTextColor,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),

              // ── Active Connections Story Rail (Mobbin pattern) ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 88,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Discover shortcut bubble
                      GestureDetector(
                        onTap: () => context.go('/discover'),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.darkElevated
                                    : AppColors.creamElevated,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.divider,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.explore_outlined,
                                size: 24,
                                color: isDark
                                    ? AppColors.luminousMauve
                                    : AppColors.mauve,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Discover',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11,
                                color: mutedTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Active Connections Bubbles
                      ...allThreads.take(8).map((thread) {
                        final isDating = thread.connectionType
                            .toLowerCase()
                            .contains('dating');
                        final ringGradient = isDating
                            ? const LinearGradient(
                                colors: [
                                  AppColors.vividCoral,
                                  AppColors.softCoral,
                                ],
                              )
                            : LinearGradient(
                                colors: isDark
                                    ? [AppColors.luminousMauve, AppColors.mauve]
                                    : [AppColors.mauve, AppColors.deepPlum],
                              );

                        return GestureDetector(
                          onTap: () => context.push(
                            '/chat/${thread.participantName}',
                            extra: {
                              'conversationId': thread.conversationId,
                              'partnerId': thread.partnerId,
                              'partnerAvatar': thread.participantAvatar,
                            },
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(right: 14),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: ringGradient,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.obsidian
                                                : AppColors.warmIvory,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: AppSmartImage(
                                            imagePath: thread.participantAvatar,
                                            isAvatar: true,
                                            nameHint: thread.participantName,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (thread.isOnline)
                                      Positioned(
                                        right: 2,
                                        bottom: 2,
                                        child: Container(
                                          width: 13,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            color: AppColors.mintAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.obsidian
                                                  : AppColors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  thread.participantName.split(' ').first,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 11,
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Filter Pills (All / Unread / Experiences) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(
                  children: [
                    _buildFilterTab(0, 'All Chats', isDark),
                    const SizedBox(width: 8),
                    _buildFilterTab(1, 'Unread', isDark),
                    const SizedBox(width: 8),
                    _buildFilterTab(2, 'Meetups', isDark),
                  ],
                ),
              ),

              // ── Conversations List ──
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPurple,
                        ),
                      )
                    : filteredThreads.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: allThreads.isEmpty
                            ? 'No conversations yet'
                            : 'No conversations found',
                        message: allThreads.isEmpty
                            ? 'Enjoyed meeting someone at an event? Your mutual connections and messages will appear here.'
                            : 'Try searching for another name or changing filters.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.refresh(inboxThreadsProvider.future),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 6,
                            bottom: 120, // Buffer for floating navbar
                          ),
                          itemCount: filteredThreads.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final thread = filteredThreads[index];
                            final badgeColor = _getBadgeColor(
                              thread.connectionType,
                              isDark,
                            );

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push(
                                  '/chat/${thread.participantName}',
                                  extra: {
                                    'conversationId': thread.conversationId,
                                    'partnerId': thread.partnerId,
                                    'partnerAvatar': thread.participantAvatar,
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: thread.isUnread
                                        ? (isDark
                                              ? AppColors.luminousMauve
                                                    .withValues(alpha: 0.5)
                                              : AppColors.mauve.withValues(
                                                  alpha: 0.4,
                                                ))
                                        : borderColor,
                                    width: thread.isUnread ? 1.4 : 0.9,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black26
                                          : AppColors.deepPlum.withValues(
                                              alpha: 0.04,
                                            ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Avatar with status ring
                                    Stack(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: badgeColor,
                                              width: 1.8,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: AppSmartImage(
                                              imagePath:
                                                  thread.participantAvatar,
                                              isAvatar: true,
                                              nameHint: thread.participantName,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        if (thread.isOnline)
                                          Positioned(
                                            right: 1,
                                            bottom: 1,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: AppColors.mintAccent,
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
                                    const SizedBox(width: 14),

                                    // Text contents
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Name + Timestamp
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    thread.participantName,
                                                    style: AppTypography
                                                        .titleSmall
                                                        .copyWith(
                                                          color:
                                                              primaryTextColor,
                                                          fontWeight:
                                                              thread.isUnread
                                                              ? FontWeight.w800
                                                              : FontWeight.w700,
                                                          fontSize: 14.5,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 1.5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: badgeColor
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      thread.connectionType,
                                                      style: AppTypography
                                                          .labelSmall
                                                          .copyWith(
                                                            color: badgeColor,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 9.5,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                thread.timestamp,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: thread.isUnread
                                                          ? (isDark
                                                                ? AppColors
                                                                      .softCoral
                                                                : AppColors
                                                                      .mauve)
                                                          : mutedTextColor,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          thread.isUnread
                                                          ? FontWeight.w700
                                                          : FontWeight.w400,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),

                                          // Activity context pill
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.event_outlined,
                                                size: 11,
                                                color: mutedTextColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  thread.experienceName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                        color: mutedTextColor,
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),

                                          // Message preview & unread dot
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  thread.lastMessage,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                        color: thread.isUnread
                                                            ? primaryTextColor
                                                            : mutedTextColor,
                                                        fontWeight:
                                                            thread.isUnread
                                                            ? FontWeight.w700
                                                            : FontWeight.w400,
                                                        fontSize: 12.5,
                                                      ),
                                                ),
                                              ),
                                              if (thread.isUnread) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 9,
                                                  height: 9,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isDark
                                                        ? AppColors
                                                              .luminousMauve
                                                        : AppColors.mauve,
                                                  ),
                                                ),
                                              ],
                                            ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    final activeBg = isDark ? AppColors.luminousMauve : AppColors.deepPlum;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeBg
              : (isDark ? AppColors.darkSurface : AppColors.creamElevated),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeBg
                : (isDark ? AppColors.darkBorder : AppColors.divider),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Color _getBadgeColor(String type, bool isDark) {
    switch (type.toLowerCase()) {
      case 'exploring dating':
      case 'dating':
        return isDark ? AppColors.vividCoral : AppColors.softCoral;
      case 'friendship':
        return isDark ? AppColors.luminousMauve : AppColors.mauve;
      case 'activity partner':
        return AppColors.mintAccent;
      default:
        return isDark ? AppColors.luminousMauve : AppColors.mauve;
    }
  }
}
