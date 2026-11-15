import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import 'orbital_connections_view.dart';

class ConnectionItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String
  connectionType; // 'Friendship', 'Activity Partner', 'Exploring Dating'
  final String experienceName;
  final DateTime connectedAt;

  const ConnectionItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.connectionType,
    required this.experienceName,
    required this.connectedAt,
  });
}

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  bool _isOrbitView = true;

  final List<ConnectionItem> _connections = [
    ConnectionItem(
      id: 'conn-1',
      name: 'Rhea Sen',
      avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Exploring Dating',
      experienceName: 'Coffee & Conversation: Weekend Musings',
      connectedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    ConnectionItem(
      id: 'conn-2',
      name: 'Aarav Mehta',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Activity Partner',
      experienceName: 'Beginner Badminton & Court Rally',
      connectedAt: DateTime.now().subtract(const Duration(days: 2)),
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
          'Connections',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        actions: [
          // Segmented Orbit vs List Toggle Pill
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isOrbitView = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isOrbitView
                            ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bubble_chart_rounded,
                            size: 14,
                            color: _isOrbitView
                                ? Colors.white
                                : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Orbit',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _isOrbitView
                                  ? Colors.white
                                  : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isOrbitView = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: !_isOrbitView
                            ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 14,
                            color: !_isOrbitView
                                ? Colors.white
                                : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'List',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: !_isOrbitView
                                  ? Colors.white
                                  : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: _connections.isEmpty
            ? EmptyStateWidget(
                icon: Icons.people_outline_rounded,
                title: 'No connections yet',
                message:
                    'Your next great connection may begin with your next experience. Attend an activity to meet compatible people!',
                actionLabel: 'Discover Activities',
                onActionPressed: () => context.go('/discover'),
              )
            : ListView(
                padding: const EdgeInsets.only(
                  left: AppConstants.spacingLG,
                  right: AppConstants.spacingLG,
                  top: AppConstants.spacingSM,
                  bottom: 120, // Bottom padding for glassmorphic navbar
                ),
                children: [
                  Text(
                    'Good moments can become\ngreat connections.',
                    style: AppTypography.headlineMedium.copyWith(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    'Connections from small-group meetups who mutually unlocked contact.',
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedTextColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMD),

                  // View Switch: Orbit Cosmic View vs List View
                  if (_isOrbitView) ...[
                    OrbitalConnectionsView(connections: _connections),
                  ] else ...[
                    ..._connections.map((conn) {
                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.spacingMD,
                      ),
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
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(conn.avatarUrl),
                          ),
                          const SizedBox(width: AppConstants.spacingMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      conn.name,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkElevated
                                            : AppColors.sage,
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.buttonRadiusSmall,
                                        ),
                                        border: isDark
                                            ? Border.all(
                                                color: AppColors.darkBorder,
                                                width: 0.6)
                                            : null,
                                      ),
                                      child: Text(
                                        conn.connectionType,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: isDark
                                              ? AppColors.luminousMauve
                                              : AppColors.deepPlum,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event_available_rounded,
                                      size: 13,
                                      color: isDark
                                          ? AppColors.luminousMauve
                                          : AppColors.mauve,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Met at ${conn.experienceName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: mutedTextColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingSM),
                          IconButton(
                            icon: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: isDark
                                  ? AppColors.luminousMauve
                                  : AppColors.mauve,
                            ),
                            onPressed: () => context.push('/chat/${conn.name}'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                ],
              ),
      ),
    );
  }
}
