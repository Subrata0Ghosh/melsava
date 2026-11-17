import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/experience_model.dart';
import 'app_smart_image.dart';

/// Full-featured Experience Share Modal and Native Share Launcher
class ExperienceShareSheet extends StatefulWidget {
  final ExperienceModel experience;

  const ExperienceShareSheet({
    super.key,
    required this.experience,
  });

  static Future<void> show(BuildContext context, ExperienceModel experience) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExperienceShareSheet(experience: experience),
    );
  }

  /// Triggers native platform share sheet directly
  static Future<void> triggerNativeShare(
    BuildContext context,
    ExperienceModel experience,
  ) async {
    HapticFeedback.mediumImpact();
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');
    final shareUrl = 'https://melsava.app/e/${experience.id}';
    final shareMessage =
        '🌟 Join me for "${experience.title}" on MELSAVA!\n'
        '📍 ${experience.venueName}, ${experience.city}\n'
        '🗓️ ${dateFormat.format(experience.startsAt)}\n\n'
        'Explore and RSVP here: $shareUrl';

    final box = context.findRenderObject() as RenderBox?;
    final originRect = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(0, 0, 100, 100);

    // Copy to clipboard first
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (!context.mounted) return;

    try {
      final result = await Share.share(
        shareMessage,
        subject: 'Join me for ${experience.title} on MELSAVA!',
        sharePositionOrigin: originRect,
      );

      if (context.mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for sharing MELSAVA! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        show(context, experience);
      }
    }
  }

  @override
  State<ExperienceShareSheet> createState() => _ExperienceShareSheetState();
}

class _ExperienceShareSheetState extends State<ExperienceShareSheet> {
  bool _copied = false;

  void _copyLink() async {
    HapticFeedback.selectionClick();
    final shareUrl = 'https://melsava.app/e/${widget.experience.id}';
    await Clipboard.setData(ClipboardData(text: shareUrl));
    setState(() => _copied = true);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  void _shareViaNative() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      ExperienceShareSheet.triggerNativeShare(context, widget.experience);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');

    final sheetBg = isDark ? const Color(0xFF1B142B) : Colors.white;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF1E1435);
    final mutedTextColor = isDark ? AppColors.darkMutedText : const Color(0xFF7E7394);
    final cardBg = isDark ? const Color(0xFF241C38) : const Color(0xFFF7F5FB);
    final borderColor = isDark ? const Color(0xFF382F4D) : const Color(0xFFE9E4F5);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top pill
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share Experience',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: primaryTextColor,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close_rounded, color: mutedTextColor, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Experience Preview Mini Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: AppSmartImage(
                      imagePath: exp.coverImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${dateFormat.format(exp.startsAt)} · ${exp.venueName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 20),

          // Share Options Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOption(
                icon: Icons.share_rounded,
                label: 'System Share',
                gradient: AppColors.purpleGradient,
                onTap: _shareViaNative,
                isDark: isDark,
              ),
              _buildShareOption(
                icon: _copied ? Icons.check_rounded : Icons.link_rounded,
                label: _copied ? 'Copied! ✓' : 'Copy Link',
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                onTap: _copyLink,
                isDark: isDark,
              ),
              _buildShareOption(
                icon: Icons.chat_rounded,
                label: 'Message',
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                onTap: _shareViaNative,
                isDark: isDark,
              ),
              _buildShareOption(
                icon: Icons.send_rounded,
                label: 'Send Direct',
                gradient: AppColors.sunsetCtaGradient,
                onTap: _shareViaNative,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Direct Primary Action Button
          GestureDetector(
            onTap: _shareViaNative,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.sunsetCtaGradient,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E7E).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Share with Friends',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF1E1435),
            ),
          ),
        ],
      ),
    );
  }
}
