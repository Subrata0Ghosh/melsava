import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';

/// Screen detailing MELSAVA's 10 Core Community Guidelines for safe, respectful,
/// and authentic face-to-face social experiences.
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  static const List<Map<String, dynamic>> _guidelines = [
    {
      'number': '01',
      'icon': Icons.badge_outlined,
      'title': 'Authentic Identity',
      'desc':
          'Present yourself honestly. Use recent, genuine photos and accurate profile details. Impersonation, sock-puppet accounts, or deceitful personas are strictly prohibited.',
    },
    {
      'number': '02',
      'icon': Icons.storefront_outlined,
      'title': 'Public Venues Only',
      'desc':
          'All MELSAVA micro-group meetups occur exclusively at public venues (cafés, public botanical gardens, and creative studios). Private residences or secluded rendezvous are never sanctioned.',
    },
    {
      'number': '03',
      'icon': Icons.volunteer_activism_outlined,
      'title': 'Zero Tolerance for Harassment',
      'desc':
          'Treat every member with dignity. Bullying, unwanted persistent advances, aggressive behavior, intimidation, and abusive language result in permanent expulsion.',
    },
    {
      'number': '04',
      'icon': Icons.pan_tool_outlined,
      'title': 'Explicit Consent & Boundaries',
      'desc':
          'Honor physical and emotional boundaries at all times. Physical contact requires explicit enthusiasm. A "no" or hesitant silence always means stop.',
    },
    {
      'number': '05',
      'icon': Icons.alarm_outlined,
      'title': 'Punctuality & RSVP Etiquette',
      'desc':
          'Hosts and fellow attendees invest time and emotional energy into each circle. Arrive on time. If you cannot attend, cancel your RSVP at least 4 hours in advance.',
    },
    {
      'number': '06',
      'icon': Icons.no_sim_outlined,
      'title': 'Non-Commercial Gathering',
      'desc':
          'MELSAVA is built for genuine human connection. Do not pitch financial schemes, crypto investments, professional business services, multi-level marketing, or products.',
    },
    {
      'number': '07',
      'icon': Icons.camera_alt_outlined,
      'title': 'Privacy & Discretion',
      'desc':
          'Stories and vulnerabilities shared inside a circle remain confidential. Never record audio, photograph, or tag participants on social media without explicit mutual agreement.',
    },
    {
      'number': '08',
      'icon': Icons.emoji_food_beverage_outlined,
      'title': 'Substance & Alcohol Moderation',
      'desc':
          'Keep your mind clear and present. Intoxication or illicit substances during group meetups endanger community safety and will not be tolerated.',
    },
    {
      'number': '09',
      'icon': Icons.diversity_1_outlined,
      'title': 'Inclusion & Kindness',
      'desc':
          'We celebrate diverse backgrounds, cultures, orientations, and viewpoints. Discrimination or hate speech based on race, religion, gender, sexuality, or disability is forbidden.',
    },
    {
      'number': '10',
      'icon': Icons.security_rounded,
      'title': 'Proactive Safety & Reporting',
      'desc':
          'If you witness misconduct or feel unsafe, notify your host or report the member immediately through the app. Our community moderation team reviews every submission with care.',
    },
  ];

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

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1D142E)
          : const Color(0xFFFFFDF9),
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.wildGrass,
        leafColors: BotanicalLeafDecoration.warmOlive,
        child: SafeArea(
          bottom: false,
          child: Column(
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
                    Expanded(
                      child: Text(
                        'Community Guidelines',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Introductory Banner ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(
                          0xFF10B981,
                        ).withValues(alpha: isDark ? 0.2 : 0.12),
                        const Color(
                          0xFF059669,
                        ).withValues(alpha: isDark ? 0.08 : 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Our Commitment to Safety: Every MELSAVA experience is grounded in mutual respect, active consent, and vetted public venues.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: primaryTextColor.withValues(alpha: 0.9),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 10 Guidelines Scrollable List ──
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: _guidelines.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _guidelines[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Number & Icon Badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.brightViolet.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                item['icon'] as IconData,
                                color: AppColors.brightViolet,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item['number'] as String,
                                      style: const TextStyle(
                                        color: AppColors.brightViolet,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['title'] as String,
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['desc'] as String,
                                  style: TextStyle(
                                    color: mutedTextColor,
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
