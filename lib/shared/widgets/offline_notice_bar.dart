import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';

/// Low-cost offline notice bar displayed when serving cached experiences
/// or when backend connectivity is unavailable.
class OfflineNoticeBar extends StatelessWidget {
  final DateTime? lastSyncedAt;
  final VoidCallback? onRetry;

  const OfflineNoticeBar({super.key, this.lastSyncedAt, this.onRetry});

  String _formatSyncTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = lastSyncedAt != null
        ? _formatSyncTime(lastSyncedAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2216) : const Color(0xFFFFFBEB),
        border: Border(
          bottom: BorderSide(
            color: const Color(
              0xFFF59E0B,
            ).withValues(alpha: isDark ? 0.3 : 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              timeStr != null
                  ? 'Offline Mode • Cached at $timeStr'
                  : 'Offline Mode • Showing cached content',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF59E0B,
                  ).withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Retry',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFF92400E),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
