import 'package:cached_network_image/cached_network_image.dart';
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
  final String connectionType; // 'Friends', 'Activity', 'Dates'
  final String experienceName;
  final String lastMessage;
  final String timeAgo;
  final bool isOnline;
  final int compatibilityScore;

  const ConnectionItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.connectionType,
    required this.experienceName,
    required this.lastMessage,
    required this.timeAgo,
    this.isOnline = true,
    this.compatibilityScore = 94,
  });
}

/// Screen 8 (from Image 8): My Connections Screen
///
/// Clean, high-fidelity connections directory:
/// - Filter tabs: All (8), Friends (4), Activity (2), Dates (2)
/// - Contact cards with green online indicator, intent badge, last message preview
/// - Direct chat action bubble button
/// - Optional Cosmic Orbit view toggle (inspired by Proxima)
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  String _selectedFilter = 'All';
  bool _isOrbitView = false;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';

  final List<ConnectionItem> _allConnections = [
    const ConnectionItem(
      id: 'conn-1',
      name: 'Sneha',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Friends',
      experienceName: 'Trekking to Mukutmanipur',
      lastMessage: 'Great trekking experience! Let\'s go again soon.',
      timeAgo: '2h ago',
      isOnline: true,
      compatibilityScore: 96,
    ),
    const ConnectionItem(
      id: 'conn-2',
      name: 'Rohan',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Activity',
      experienceName: 'Cycling Club Ride',
      lastMessage: 'Shall we plan for next weekend ride at Salt Lake?',
      timeAgo: '1d ago',
      isOnline: true,
      compatibilityScore: 91,
    ),
    const ConnectionItem(
      id: 'conn-3',
      name: 'Aditi',
      avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Dates',
      experienceName: 'Coffee & Conversation',
      lastMessage: 'Had a lovely time discussing books yesterday!',
      timeAgo: '2d ago',
      isOnline: false,
      compatibilityScore: 94,
    ),
    const ConnectionItem(
      id: 'conn-4',
      name: 'Priya',
      avatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Friends',
      experienceName: 'Morning Yoga & Wellness',
      lastMessage: 'Let\'s catch up soon 😊 The herbal tea was amazing.',
      timeAgo: '3d ago',
      isOnline: true,
      compatibilityScore: 89,
    ),
    const ConnectionItem(
      id: 'conn-5',
      name: 'Karan',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Activity',
      experienceName: 'Board Game Evening',
      lastMessage: 'That Catan strategy was brilliant!',
      timeAgo: '4d ago',
      isOnline: false,
      compatibilityScore: 88,
    ),
    const ConnectionItem(
      id: 'conn-6',
      name: 'Meera',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      connectionType: 'Dates',
      experienceName: 'Coffee & Conversation',
      lastMessage: 'Loved our conversation on heritage architecture.',
      timeAgo: '5d ago',
      isOnline: true,
      compatibilityScore: 93,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    final filtered = _allConnections.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.experienceName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Friends' && c.connectionType == 'Friends') ||
          (_selectedFilter == 'Activity' && c.connectionType == 'Activity') ||
          (_selectedFilter == 'Dates' && c.connectionType == 'Dates');

      return matchesSearch && matchesFilter;
    }).toList();

    final friendsCount = _allConnections.where((c) => c.connectionType == 'Friends').length;
    final activityCount = _allConnections.where((c) => c.connectionType == 'Activity').length;
    final datesCount = _allConnections.where((c) => c.connectionType == 'Dates').length;

    final filterTabs = [
      {'name': 'All', 'count': _allConnections.length},
      {'name': 'Friends', 'count': friendsCount},
      {'name': 'Activity', 'count': activityCount},
      {'name': 'Dates', 'count': datesCount},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
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
      body: _isOrbitView
          ? OrbitalConnectionsView(
              connections: filtered,
            )
          : Column(
              children: [
                // Filter Tabs (Image 8 Screen 8)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filterTabs.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.purpleGradient : null,
                              color: isSelected
                                  ? null
                                  : (isDark ? AppColors.darkElevated : AppColors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark ? AppColors.darkBorder : AppColors.divider),
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              '$name ($count)',
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
                  child: filtered.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.people_outline_rounded,
                          title: 'No connections in this category',
                          message: 'Join more public experiences to meet people and unlock mutual connections!',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 18,
                            right: 18,
                            top: 6,
                            bottom: 120, // Guaranteed 120dp clearance for floating navbar
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
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
              ],
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
        context.push('/chat/${conn.name}');
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
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
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
                    color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                    width: 1.8,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: conn.avatarUrl,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              context.push('/chat/${conn.name}');
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : const Color(0xFFF3E8FF),
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
                color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
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
