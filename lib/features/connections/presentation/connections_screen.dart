import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import 'orbital_connections_view.dart';

class ConnectionItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String connectionType; // 'Friendship', 'Activity Partner', 'Exploring Dating'
  final String experienceName;
  final DateTime connectedAt;
  final int compatibilityScore; // e.g. 94%

  const ConnectionItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.connectionType,
    required this.experienceName,
    required this.connectedAt,
    this.compatibilityScore = 92,
  });
}

/// Screen 4: Post-Experience Connections
///
/// Features:
/// - Cosmic Orbit View inspired by Proxima (Dribbble), visualizing connections
///   revolving around the user based on shared activities and compatibility
/// - List View with rich cards, compatibility breakdown, and direct chat actions
/// - Vibe/Connection category tags (Dating, Friendship, Activity Partner)
/// - Seamless Light & Dark mode support
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
      compatibilityScore: 94,
    ),
    ConnectionItem(
      id: 'conn-2',
      name: 'Aarav Mehta',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Activity Partner',
      experienceName: 'Beginner Badminton & Court Rally',
      connectedAt: DateTime.now().subtract(const Duration(days: 2)),
      compatibilityScore: 89,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connections',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: primaryTextColor,
              ),
            ),
            Text(
              'MUTUAL POST-EXPERIENCE MATCHES',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.2,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.softCoral : AppColors.mauve,
              ),
            ),
          ],
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
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isOrbitView = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isOrbitView
                            ? (isDark ? AppColors.luminousMauve : AppColors.deepPlum)
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
                          const SizedBox(width: 5),
                          Text(
                            'Orbit',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11.5,
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
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isOrbitView = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: !_isOrbitView
                            ? (isDark ? AppColors.luminousMauve : AppColors.deepPlum)
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
                          const SizedBox(width: 5),
                          Text(
                            'List',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11.5,
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
                    'Your next great connection begins with your next experience. Attend an activity to meet compatible people!',
                actionLabel: 'Discover Activities',
                onActionPressed: () => context.go('/discover'),
              )
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: 120, // Bottom padding for glassmorphic navbar
                ),
                children: [
                  // Header intro
                  Text(
                    'Good moments become\ngreat connections.',
                    style: AppTypography.headlineMedium.copyWith(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'People you mutually unlocked contact with after attending small-group experiences together.',
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedTextColor,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // View Switch: Orbit Cosmic View vs List View
                  if (_isOrbitView) ...[
                    OrbitalConnectionsView(connections: _connections),
                  ] else ...[
                    ..._connections.map((conn) {
                      final badgeColor = _getBadgeColor(conn.connectionType, isDark);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : AppColors.deepPlum.withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar with badge ring
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: badgeColor,
                                  width: 2.2,
                                ),
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: ClipOval(
                                child: Image.network(
                                  conn.avatarUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Name & Metadata
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
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          conn.connectionType,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: badgeColor,
                                            fontWeight: FontWeight.w800,
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
                                        Icons.auto_awesome_rounded,
                                        size: 13,
                                        color: isDark
                                            ? AppColors.luminousMauve
                                            : AppColors.mauve,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          conn.experienceName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodySmall.copyWith(
                                            color: mutedTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${conn.compatibilityScore}% Compatibility · Shared vibe',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark ? AppColors.softCoral : AppColors.mauve,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Chat CTA
                            GestureDetector(
                              onTap: () => context.push('/chat/${conn.name}'),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.luminousMauve.withValues(alpha: 0.15)
                                      : AppColors.mauve.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: (isDark
                                            ? AppColors.luminousMauve
                                            : AppColors.mauve)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.luminousMauve
                                      : AppColors.mauve,
                                ),
                              ),
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
