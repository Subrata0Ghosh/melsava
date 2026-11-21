import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../connections/data/connections_repository.dart';
import '../../experiences/data/experiences_repository.dart';
import '../../../shared/models/experience_model.dart';

/// Screen for community moderators and administrators to review reported members,
/// inspect flags, dismiss invalid concerns, and issue formal warnings or account suspensions.
class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});

  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen> {
  int _mainSection = 0; // 0: Reports, 1: Pending Circles, 2: Member Appeals
  String _selectedStatus = 'pending';

  static const List<Map<String, String>> _statusTabs = [
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Reviewed', 'value': 'reviewed'},
    {'label': 'Resolved', 'value': 'resolved'},
    {'label': 'Dismissed', 'value': 'dismissed'},
    {'label': 'All', 'value': 'all'},
  ];

  Future<void> _handleModerateCircle({
    required ExperienceModel exp,
    required String action,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(connectionsRepositoryProvider);

    final confirm = await ConfirmationDialog.show(
      context,
      title: action == 'approved' ? 'Approve Circle?' : 'Remove Circle?',
      message: action == 'approved'
          ? 'Make "${exp.title}" visible on community discovery immediately.'
          : 'Remove "${exp.title}" from community discovery for safety reasons.',
      confirmLabel: action == 'approved' ? 'Approve' : 'Remove',
      isDestructive: action != 'approved',
    );
    if (confirm != true) return;

    final success = await repo.moderateExperience(
      experienceId: exp.id,
      action: action,
      reason: action == 'approved'
          ? 'Approved by moderator after verification.'
          : 'Removed by moderator due to community safety review.',
    );

    if (success) {
      ref.invalidate(pendingExperiencesProvider);
      ref.invalidate(publishedExperiencesProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            action == 'approved' ? 'Circle approved!' : 'Circle removed.',
          ),
        ),
      );
    }
  }

  Future<void> _handleResolveAppeal({
    required ModerationAppealModel appeal,
    required String resolution,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(connectionsRepositoryProvider);

    final confirm = await ConfirmationDialog.show(
      context,
      title: resolution == 'approved' ? 'Approve Appeal?' : 'Reject Appeal?',
      message: resolution == 'approved'
          ? 'Approve appeal for ${appeal.userName}. Account/circle access will be restored.'
          : 'Reject appeal for ${appeal.userName}. Restriction remains in place.',
      confirmLabel: resolution == 'approved'
          ? 'Approve Appeal'
          : 'Reject Appeal',
      isDestructive: resolution != 'approved',
    );
    if (confirm != true) return;

    final success = await repo.resolveModerationAppeal(
      appealId: appeal.appealId,
      resolution: resolution,
      notes: resolution == 'approved'
          ? 'Appeal reviewed and accepted.'
          : 'Appeal reviewed and rejected by moderator.',
    );

    if (success) {
      ref.invalidate(moderationAppealsProvider('pending'));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            resolution == 'approved'
                ? 'Appeal accepted and restriction lifted.'
                : 'Appeal rejected.',
          ),
        ),
      );
    }
  }

  Future<void> _handleAction({
    required ModerationReportModel report,
    required String actionType,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(connectionsRepositoryProvider);

    if (actionType == 'dismiss') {
      final confirm = await ConfirmationDialog.show(
        context,
        title: 'Dismiss Report?',
        message: 'This report will be marked as dismissed without penalty.',
        confirmLabel: 'Dismiss',
      );
      if (confirm != true) return;

      final success = await repo.resolveModerationReport(
        report.reportId,
        'dismissed',
      );
      if (success) {
        ref.invalidate(moderationReportsProvider(_selectedStatus));
        messenger.showSnackBar(
          const SnackBar(content: Text('Report dismissed.')),
        );
      }
    } else if (actionType == 'review') {
      final success = await repo.resolveModerationReport(
        report.reportId,
        'reviewed',
      );
      if (success) {
        ref.invalidate(moderationReportsProvider(_selectedStatus));
        messenger.showSnackBar(
          const SnackBar(content: Text('Marked as reviewed.')),
        );
      }
    } else if (actionType == 'warning') {
      final confirm = await ConfirmationDialog.show(
        context,
        title: 'Issue Formal Warning?',
        message:
            'A warning record will be logged on ${report.reportedName}\'s account for violation of "${report.reason}".',
        confirmLabel: 'Issue Warning',
      );
      if (confirm != true) return;

      final success = await repo.applyModerationAction(
        userId: report.reportedUserId,
        actionType: 'warning',
        reason: 'Violating Community Guidelines: ${report.reason}',
        reportId: report.reportId,
      );
      if (success) {
        ref.invalidate(moderationReportsProvider(_selectedStatus));
        messenger.showSnackBar(
          const SnackBar(content: Text('Warning logged against member.')),
        );
      }
    } else if (actionType == 'suspension') {
      final confirm = await ConfirmationDialog.show(
        context,
        title: 'Suspend Account?',
        message:
            'Immediately suspend ${report.reportedName}\'s account and revoke access to all circles and messaging.',
        confirmLabel: 'Suspend Account',
        isDestructive: true,
      );
      if (confirm != true) return;

      final success = await repo.applyModerationAction(
        userId: report.reportedUserId,
        actionType: 'suspension',
        reason: 'Account suspended following report: ${report.reason}',
        reportId: report.reportId,
      );
      if (success) {
        ref.invalidate(moderationReportsProvider(_selectedStatus));
        messenger.showSnackBar(
          const SnackBar(content: Text('Account successfully suspended.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1E1435);
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : const Color(0xFF7E7394);
    final cardBg = isDark ? const Color(0xFF1B1528) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF332A45)
        : const Color(0xFFEDE9FE);

    final isModAsync = ref.watch(isModeratorProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1D142E)
          : const Color(0xFFFFFDF9),
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.wildGrass,
        leafColors: BotanicalLeafDecoration.warmOlive,
        child: SizedBox.expand(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 0.9),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: primaryTextColor,
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/settings');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Moderation Console',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                fontSize: 19,
                              ),
                            ),
                            Text(
                              'Review reports & protect community safety',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Check Moderator Permission
                Expanded(
                  child: isModAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Permission check error: $err',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    data: (isMod) {
                      if (!isMod) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.gpp_bad_rounded,
                                  size: 54,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Access Restricted',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You do not have moderator or administrative credentials to access this console.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: mutedTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return _buildModeratorBody(
                        context: context,
                        isDark: isDark,
                        primaryTextColor: primaryTextColor,
                        mutedTextColor: mutedTextColor,
                        cardBg: cardBg,
                        borderColor: borderColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTab(
    int index,
    String label,
    bool isDark,
    Color primaryTextColor,
  ) {
    final isSelected = _mainSection == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _mainSection = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : primaryTextColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeratorBody({
    required BuildContext context,
    required bool isDark,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    final reportsAsync = ref.watch(moderationReportsProvider(_selectedStatus));

    return Column(
      children: [
        // ── Main Section Tabs: Reports | Pending Circles | Appeals ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevated : const Color(0xFFF3EEFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            children: [
              _buildSectionTab(0, 'Reports', isDark, primaryTextColor),
              _buildSectionTab(1, 'Pending Circles', isDark, primaryTextColor),
              _buildSectionTab(2, 'Appeals', isDark, primaryTextColor),
            ],
          ),
        ),

        if (_mainSection == 0) ...[
          // ── Filter Tabs ──
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusTabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = _statusTabs[index];
                final isSelected = tab['value'] == _selectedStatus;

                return ChoiceChip(
                  label: Text(tab['label']!),
                  selected: isSelected,
                  selectedColor: AppColors.brightViolet,
                  backgroundColor: cardBg,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : primaryTextColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = tab['value']!);
                    }
                  },
                );
              },
            ),
          ),

          // ── Reports List ──
          Expanded(
            child: reportsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load reports: $err',
                      style: TextStyle(color: mutedTextColor),
                    ),
                  ],
                ),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 44,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No $_selectedStatus reports',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Everything looks peaceful and safe!',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: reports.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final dateStr = report.createdAt != null
                        ? '${report.createdAt!.day}/${report.createdAt!.month}/${report.createdAt!.year}'
                        : 'Recent';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 0.9),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row: Member & Date
                          Row(
                            children: [
                              ClipOval(
                                child: AppSmartImage(
                                  imagePath: report.reportedAvatar,
                                  isAvatar: true,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  fallbackAsset:
                                      'assets/images/sneha_avatar.png',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.reportedName,
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    Text(
                                      'Reported on $dateStr • ${report.reportedContentType}',
                                      style: TextStyle(
                                        color: mutedTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: report.status == 'pending'
                                      ? const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.15)
                                      : const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  report.status.toUpperCase(),
                                  style: TextStyle(
                                    color: report.status == 'pending'
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Reason
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF6F4FB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FLAGGED REASON:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.error,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  report.reason,
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (report.description != null &&
                                    report.description!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    report.description!,
                                    style: TextStyle(
                                      color: mutedTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Action Buttons Bar
                          Row(
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _handleAction(
                                  report: report,
                                  actionType: 'dismiss',
                                ),
                                child: const Text(
                                  'Dismiss',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _handleAction(
                                  report: report,
                                  actionType: 'warning',
                                ),
                                child: const Text(
                                  'Issue Warning',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF43F5E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _handleAction(
                                  report: report,
                                  actionType: 'suspension',
                                ),
                                child: const Text(
                                  'Suspend',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ] else if (_mainSection == 1) ...[
          Expanded(
            child: _buildPendingCirclesSection(
              context,
              isDark,
              primaryTextColor,
              mutedTextColor,
              cardBg,
              borderColor,
            ),
          ),
        ] else ...[
          Expanded(
            child: _buildAppealsSection(
              context,
              isDark,
              primaryTextColor,
              mutedTextColor,
              cardBg,
              borderColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPendingCirclesSection(
    BuildContext context,
    bool isDark,
    Color primaryTextColor,
    Color mutedTextColor,
    Color cardBg,
    Color borderColor,
  ) {
    final pendingAsync = ref.watch(pendingExperiencesProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(
        child: Text(
          'Failed to load pending circles: $err',
          style: TextStyle(color: mutedTextColor),
        ),
      ),
      data: (circles) {
        if (circles.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 44,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                Text(
                  'No pending circles',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All member-submitted activities have been reviewed.',
                  style: TextStyle(color: mutedTextColor, fontSize: 12.5),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: circles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final exp = circles[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 0.9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                  .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          exp.categoryIcon,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exp.title,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                            Text(
                              'Host: ${exp.hostName} • ${exp.city}${(exp.area != null && exp.area!.isNotEmpty) ? ', ${exp.area!}' : ''}',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    exp.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChip(
                        Icons.people_outline,
                        'Max ${exp.maxParticipants}',
                        isDark,
                        mutedTextColor,
                        cardBg,
                        borderColor,
                      ),
                      _buildChip(
                        Icons.access_time_rounded,
                        '${exp.durationMinutes} min',
                        isDark,
                        mutedTextColor,
                        cardBg,
                        borderColor,
                      ),
                      _buildChip(
                        Icons.attach_money_rounded,
                        exp.isFree
                            ? 'Free'
                            : '${exp.currency} ${exp.priceAmount}',
                        isDark,
                        mutedTextColor,
                        cardBg,
                        borderColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            _handleModerateCircle(exp: exp, action: 'removed'),
                        child: const Text(
                          'Reject & Remove',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            _handleModerateCircle(exp: exp, action: 'approved'),
                        child: const Text(
                          'Approve Circle',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppealsSection(
    BuildContext context,
    bool isDark,
    Color primaryTextColor,
    Color mutedTextColor,
    Color cardBg,
    Color borderColor,
  ) {
    final appealsAsync = ref.watch(moderationAppealsProvider('pending'));

    return appealsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(
        child: Text(
          'Failed to load appeals: $err',
          style: TextStyle(color: mutedTextColor),
        ),
      ),
      data: (appeals) {
        if (appeals.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 44,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                Text(
                  'No pending appeals',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No member restriction appeals require review.',
                  style: TextStyle(color: mutedTextColor, fontSize: 12.5),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: appeals.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final appeal = appeals[index];
            final dateStr = appeal.createdAt != null
                ? '${appeal.createdAt!.day}/${appeal.createdAt!.month}/${appeal.createdAt!.year}'
                : 'Recent';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 0.9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: AppSmartImage(
                          imagePath: appeal.userAvatar,
                          isAvatar: true,
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          fallbackAsset: 'assets/images/sneha_avatar.png',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appeal.userName,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                            Text(
                              'Appealed on $dateStr • ${appeal.actionType.toUpperCase()}',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF3B82F6,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'APPEAL',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Action Reason: ${appeal.actionReason}',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Appeal Claim: ${appeal.appealReason}',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (appeal.explanation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${appeal.explanation}"',
                            style: TextStyle(
                              color: primaryTextColor.withValues(alpha: 0.9),
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _handleResolveAppeal(
                          appeal: appeal,
                          resolution: 'rejected',
                        ),
                        child: const Text(
                          'Reject Appeal',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _handleResolveAppeal(
                          appeal: appeal,
                          resolution: 'approved',
                        ),
                        child: const Text(
                          'Approve & Restore',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(
    IconData icon,
    String text,
    bool isDark,
    Color mutedTextColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: mutedTextColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
