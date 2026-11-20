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

/// Screen displaying the list of users blocked by the authenticated member.
/// Allows reviewing blocked users and unblocking them with confirmation.
class BlockedProfilesScreen extends ConsumerWidget {
  const BlockedProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final blockedAsync = ref.watch(blockedUsersProvider);

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
              // ── Pinned Top Header ──
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                    Text(
                      'Blocked Profiles',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Informational Note ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF6F3FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: AppColors.brightViolet,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Blocked members cannot message you, see your active profile, or join the same private circle discussions.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: mutedTextColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Main Content ──
              Expanded(
                child: blockedAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load blocked accounts',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.invalidate(blockedUsersProvider);
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (blockedList) {
                    if (blockedList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFEDE9FE),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 48,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Blocked Profiles',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You have a clean roster. Safe connections ahead!',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: blockedList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = blockedList[index];
                        final blockedAtStr = user.blockedAt != null
                            ? 'Blocked on ${user.blockedAt!.day}/${user.blockedAt!.month}/${user.blockedAt!.year}'
                            : 'Blocked';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: borderColor,
                                ),
                                child: ClipOval(
                                  child: AppSmartImage(
                                    imagePath: user.avatarUrl,
                                    isAvatar: true,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    fallbackAsset:
                                        'assets/images/sneha_avatar.png',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name & date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      blockedAtStr,
                                      style: TextStyle(
                                        color: mutedTextColor,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Unblock Action Button
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: borderColor,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final confirm = await ConfirmationDialog.show(
                                    context,
                                    title: 'Unblock ${user.displayName}?',
                                    message:
                                        'They will be able to see you in mutual experiences and message you if a mutual match occurs.',
                                    confirmLabel: 'Unblock',
                                    isDestructive: false,
                                  );

                                  if (confirm == true) {
                                    final success = await ref
                                        .read(connectionsRepositoryProvider)
                                        .unblockUser(user.blockedId);

                                    if (success) {
                                      ref.invalidate(blockedUsersProvider);
                                      ref.invalidate(userConnectionsProvider);
                                      ref.invalidate(inboxThreadsProvider);

                                      messenger.showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          content: Text(
                                            '${user.displayName} has been unblocked.',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to unblock. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  'Unblock',
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}
