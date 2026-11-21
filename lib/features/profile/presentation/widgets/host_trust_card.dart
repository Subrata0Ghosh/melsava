import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/reputation_repository.dart';
import '../../domain/reputation_model.dart';

/// Presentation widget displaying verified host trust, reputation, and signals.
///
/// Follows MELSAVA Cold-Start & Fairness Rules:
/// - New hosts display: "New Host • Not yet rated • No completed circles yet".
/// - NEVER displays zero stars, negative scores, or fabricated trust badges.
/// - Numerical average rating is ONLY shown after at least 5 verified reviews.
class HostTrustCard extends ConsumerWidget {
  final String hostId;
  final String? hostName;
  final bool compact;

  const HostTrustCard({
    super.key,
    required this.hostId,
    this.hostName,
    this.compact = false,
  });

  Color _levelColor(HostReputationLevel level) {
    switch (level) {
      case HostReputationLevel.trustedHost:
        return const Color(0xFF10B981); // Emerald
      case HostReputationLevel.reliableHost:
        return const Color(0xFF6366F1); // Indigo
      case HostReputationLevel.activeHost:
        return AppColors.primaryPurple;
      case HostReputationLevel.newHost:
        return const Color(0xFFEC4899); // Pink / warm rose
    }
  }

  IconData _levelIcon(HostReputationLevel level) {
    switch (level) {
      case HostReputationLevel.trustedHost:
        return Icons.verified_user_rounded;
      case HostReputationLevel.reliableHost:
        return Icons.handshake_rounded;
      case HostReputationLevel.activeHost:
        return Icons.event_available_rounded;
      case HostReputationLevel.newHost:
        return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repAsync = ref.watch(hostReputationProvider(hostId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return repAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (rep) {
        final levelColor = _levelColor(rep.reputationLevel);
        final levelIcon = _levelIcon(rep.reputationLevel);

        if (compact) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: levelColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(levelIcon, size: 14, color: levelColor),
                const SizedBox(width: 6),
                Text(
                  rep.reputationLevel.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: levelColor,
                  ),
                ),
                if (!rep.isNewHost &&
                    rep.hasNumericRating &&
                    rep.averageRating != null) ...[
                  const SizedBox(width: 6),
                  const Text(
                    '•',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rep.averageRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.darkSurface,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: levelColor.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Reputation Badge & Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: levelColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(levelIcon, size: 16, color: levelColor),
                        const SizedBox(width: 6),
                        Text(
                          rep.reputationLevel.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rating pill
                  if (rep.showsNotYetRated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Not yet rated',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : AppColors.mutedText,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rep.averageRating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.darkSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${rep.reviewsCount} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Description of reputation level
              Text(
                rep.reputationLevel.description,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white70 : AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 14),

              // Activity & Hosting Stats
              Row(
                children: [
                  _buildStatPill(
                    icon: Icons.event_available_rounded,
                    label: rep.isNewHost
                        ? 'No completed circles yet'
                        : '${rep.completedHostedCount} circles hosted',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildStatPill(
                    icon: Icons.reviews_outlined,
                    label: '${rep.reviewsCount} verified reviews',
                    isDark: isDark,
                  ),
                ],
              ),
              const Divider(height: 20),

              // Genuine Trust Signals
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (rep.isEmailConfirmed)
                    _buildTrustSignal(
                      'Email Confirmed',
                      Icons.mark_email_read_outlined,
                      isDark,
                    ),
                  if (rep.isProfileCompleted)
                    _buildTrustSignal(
                      'Profile Completed',
                      Icons.badge_outlined,
                      isDark,
                    ),
                  _buildTrustSignal(
                    'Guidelines Accepted',
                    Icons.check_circle_outline_rounded,
                    isDark,
                  ),
                  if (rep.isIdentityVerified)
                    _buildTrustSignal(
                      'Identity Verified',
                      Icons.verified_rounded,
                      isDark,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : AppColors.warmIvory,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryPurple),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.darkSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustSignal(String text, IconData icon, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF10B981)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}
