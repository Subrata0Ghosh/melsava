import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/connections_repository.dart';
import 'orbital_connections_view.dart';

typedef ConnectionItem = ConnectionModel;

/// Screen 8 (from Image 8): My Connections Screen
///
/// Clean, high-fidelity connections directory:
/// - Filter tabs: All, Friends, Activity, Dates (with live count badges)
/// - Contact cards with online indicator, intent badge, last message preview
/// - Direct chat action bubble button
/// - Optional Cosmic Orbit view toggle
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  String _selectedFilter = 'All';
  bool _isOrbitView = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    final currentUser = ref.watch(currentUserProvider);
    final connectionsAsync = ref.watch(userConnectionsProvider);
    final allConnections = connectionsAsync.valueOrNull ?? const [];
    final isLoading = connectionsAsync.isLoading && !connectionsAsync.hasValue;

    final filtered = allConnections.where((c) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Friends') return c.connectionType == 'Friends';
      if (_selectedFilter == 'Activity') return c.connectionType == 'Activity';
      if (_selectedFilter == 'Dates') return c.connectionType == 'Dates';
      return true;
    }).toList();

    final friendsCount = allConnections
        .where((c) => c.connectionType == 'Friends')
        .length;
    final activityCount = allConnections
        .where((c) => c.connectionType == 'Activity')
        .length;
    final datesCount = allConnections
        .where((c) => c.connectionType == 'Dates')
        .length;

    final filterTabs = [
      {'name': 'All', 'count': allConnections.length},
      {'name': 'Friends', 'count': friendsCount},
      {'name': 'Activity', 'count': activityCount},
      {'name': 'Dates', 'count': datesCount},
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1D142E)
          : const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: Text(
          'My Connections',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: primaryTextColor,
          ),
        ),
        actions: [
          // Orbit vs List view toggle
          IconButton(
            tooltip: _isOrbitView ? 'List View' : 'Cosmic Orbit View',
            icon: Icon(
              _isOrbitView ? Icons.list_rounded : Icons.bubble_chart_rounded,
              color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isOrbitView = !_isOrbitView);
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.wildGrass,
        leafColors: BotanicalLeafDecoration.warmOlive,
        child: _isOrbitView
            ? (filtered.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.bubble_chart_outlined,
                      title: 'Your Orbit is quiet',
                      message:
                          'Join experiences and make mutual choices to see your cosmic connections in orbit!',
                    )
                  : OrbitalConnectionsView(
                      connections: filtered,
                      userAvatarUrl: currentUser?.avatarUrl ?? '',
                      userName: currentUser?.displayName ?? 'You',
                    ))
            : Column(
                children: [
                  // Filter Tabs (Image 8 Screen 8)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        itemCount: filterTabs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final tab = filterTabs[index];
                          final name = tab['name'] as String;
                          final count = tab['count'] as int;
                          final isSelected = _selectedFilter == name;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedFilter = name);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppColors.purpleGradient
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark
                                          ? AppColors.darkElevated
                                          : AppColors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.divider),
                                  width: 0.9,
                                ),
                              ),
                              child: Text(
                                '$name ($count)',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.deepPlum),
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Connections List
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryPurple,
                            ),
                          )
                        : filtered.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.people_outline_rounded,
                            title: allConnections.isEmpty
                                ? 'No mutual connections yet'
                                : 'No connections in this category',
                            message: allConnections.isEmpty
                                ? 'Join public experiences, attend in person, and select mutual intentions to unlock your connections!'
                                : 'Try selecting a different filter above to see your connections.',
                          )
                        : RefreshIndicator(
                            onRefresh: () async =>
                                ref.refresh(userConnectionsProvider.future),
                            child: ListView.separated(
                              padding: const EdgeInsets.only(
                                left: 18,
                                right: 18,
                                top: 6,
                                bottom:
                                    120, // Guaranteed 120dp clearance for floating navbar
                              ),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: ClampingScrollPhysics(),
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final conn = filtered[index];
                                return _buildConnectionCard(
                                  context,
                                  conn,
                                  isDark,
                                  primaryTextColor,
                                  mutedTextColor,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    ConnectionItem conn,
    bool isDark,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(
          '/chat/${conn.name}',
          extra: {
            'connectionId': conn.id,
            'conversationId': conn.conversationId,
            'partnerId': conn.partnerId,
            'partnerAvatar': conn.avatarUrl,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.divider,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black26
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with Online dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.brightViolet
                          : AppColors.primaryPurple,
                      width: 1.8,
                    ),
                  ),
                  child: ClipOval(
                    child: AppSmartImage(
                      imagePath: conn.avatarUrl,
                      isAvatar: true,
                      nameHint: conn.name,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (conn.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.mintAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Name, Intent & snippet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        conn.name,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getIntentBg(conn.connectionType, isDark),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${conn.connectionType} • ${conn.timeAgo}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _getIntentText(conn.connectionType, isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    conn.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedTextColor,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Direct Chat Action Button (Image 8 Screen 8)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(
                  '/chat/${conn.name}',
                  extra: {
                    'connectionId': conn.id,
                    'conversationId': conn.conversationId,
                    'partnerId': conn.partnerId,
                    'partnerAvatar': conn.avatarUrl,
                  },
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkElevated
                      : const Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.brightViolet.withValues(alpha: 0.3)
                        : AppColors.primaryPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.brightViolet
                      : AppColors.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIntentBg(String type, bool isDark) {
    if (isDark) return AppColors.darkElevated;
    switch (type) {
      case 'Friends':
        return AppColors.intentFriendshipBg;
      case 'Activity':
        return AppColors.intentActivityBg;
      case 'Dates':
        return AppColors.intentDatingBg;
      default:
        return AppColors.creamElevated;
    }
  }

  Color _getIntentText(String type, bool isDark) {
    if (isDark) return Colors.white;
    switch (type) {
      case 'Friends':
        return AppColors.intentFriendshipText;
      case 'Activity':
        return AppColors.intentActivityText;
      case 'Dates':
        return AppColors.intentDatingText;
      default:
        return AppColors.deepPlum;
    }
  }
}
