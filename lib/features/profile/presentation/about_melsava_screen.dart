import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/melsava_logo.dart';

/// Screen 15 (from Image 3 / Master Design): About MELSAVA Philosophy & Community Links
///
/// Features:
/// - Scenic twilight mountain sunset backdrop with friends overlooking the city
/// - Glowing brand logo & mission: "Meet through moments. Less swiping. More living."
/// - Terms of Service, Privacy Policy & Community Guidelines
/// - Official social channel links (Web, Instagram, Twitter/X, YouTube)
class AboutMelsavaScreen extends StatelessWidget {
  const AboutMelsavaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140E26),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Scenic Twilight Mountain Sunset Backdrop (Screen 15) ─────────
          Image.asset(
            'assets/images/splash_scenic_backdrop.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF18102E),
                    Color(0xFF381A54),
                    Color(0xFF8627BE),
                    Color(0xFF160E28),
                  ],
                ),
              ),
            ),
          ),

          // ── Gradient Shadow Overlay ──────────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 0.8, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.80),
                ],
              ),
            ),
          ),

          // ── Main Content Layout ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/discover');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Glowing Brand Icon (Image 3 Screen 15)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.65),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: MelsavaLogo(size: 80, showWordmark: false),
                  ),
                ),

                const SizedBox(height: 18),

                // MELSAVA Wordmark
                Text(
                  AppConstants.appName,
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6.0,
                    fontSize: 28,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 18,
                      ),
                      Shadow(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.85),
                        blurRadius: 36,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline & Manifesto
                Text(
                  'Meet through moments.',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Less swiping. More living.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(flex: 7),

                // ── Legal Policy Links ─────────────────────────────────────
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    _buildFooterLink(context, 'Terms of Service'),
                    Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                    _buildFooterLink(context, 'Privacy Policy'),
                    Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                    _buildFooterLink(context, 'Community Guidelines'),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Social Media Icons Row (Screen 15) ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(Icons.language_rounded),
                    const SizedBox(width: 20),
                    _buildSocialIcon(Icons.camera_alt_outlined),
                    const SizedBox(width: 20),
                    _buildSocialIcon(Icons.alternate_email_rounded),
                    const SizedBox(width: 20),
                    _buildSocialIcon(Icons.play_circle_outline_rounded),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $text...')),
        );
      },
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 1.0),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
