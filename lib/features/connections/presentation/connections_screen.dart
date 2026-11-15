import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/empty_state_widget.dart';

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
  final List<ConnectionItem> _connections = [
    ConnectionItem(
      id: 'conn-1',
      name: 'Rhea Sen',
      avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Friendship',
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
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Connections',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
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
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                children: [
                  Text(
                    'Good moments can become\ngreat connections.',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.deepPlum,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSM),
                  Text(
                    'People you have met in real-world experiences who mutually chose to stay in touch.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXL),

                  ..._connections.map((conn) {
                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.spacingMD,
                      ),
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
                                        color: AppColors.sage,
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.buttonRadiusSmall,
                                        ),
                                      ),
                                      child: Text(
                                        conn.connectionType,
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: AppColors.deepPlum,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.event_available,
                                      size: 12,
                                      color: AppColors.mauve,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Met at ${conn.experienceName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.mutedText,
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
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.mauve,
                            ),
                            onPressed: () => context.push('/chat/${conn.name}'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
