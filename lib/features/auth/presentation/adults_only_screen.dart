import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/auth_validators.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/onboarding_providers.dart';
import 'auth_providers.dart';

/// Adults Only Age Eligibility Screen (18+ Date of Birth Verification)
///
/// Preserves the MELSAVA pastel sky, bokeh orbs, fluid waves, dome card, and
/// 3D glossy heraldic shield while collecting Date of Birth privately
/// (`profile_private.date_of_birth`) and blocking users under 18 from continuing.
class AdultsOnlyScreen extends ConsumerStatefulWidget {
  const AdultsOnlyScreen({super.key});

  @override
  ConsumerState<AdultsOnlyScreen> createState() => _AdultsOnlyScreenState();
}

class _AdultsOnlyScreenState extends ConsumerState<AdultsOnlyScreen> {
  DateTime? _selectedDob;
  bool _isSaving = false;
  bool _isUnderageBlocked = false;
  String? _errorMessage;

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 24, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: now,
      helpText: 'Select your date of birth',
      confirmText: 'Confirm',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDob = picked;
        _errorMessage = null;
        _isUnderageBlocked = !AuthValidators.isAdult(picked);
      });
    }
  }

  Future<void> _handleContinue() async {
    HapticFeedback.mediumImpact();

    if (_selectedDob == null) {
      setState(
        () => _errorMessage = 'Please select your date of birth to continue.',
      );
      return;
    }

    if (!AuthValidators.isAdult(_selectedDob!)) {
      setState(() {
        _isUnderageBlocked = true;
        _errorMessage = null;
      });
      _showAgeRestrictionDialog(context);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) context.go('/welcome');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final updatedUser = await onboardingRepo.saveAdultEligibility(
        currentUser: user,
        dateOfBirth: _selectedDob!,
      );
      ref.read(currentUserProvider.notifier).state = updatedUser;
      if (mounted) {
        context.go(
          updatedUser.onboardingCompleted ? '/discover' : '/profile-onboarding',
        );
      }
    } on UnderageUserException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUnderageBlocked = true;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is PostgrestException) {
          msg = e.message;
        }
        setState(() {
          _isSaving = false;
          _errorMessage = msg;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(currentUserProvider.notifier).state = null;
    if (mounted) {
      context.go('/welcome');
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
        : const Color(0xFF594F70);
    final dateLabel = _selectedDob == null
        ? 'Tap to select date of birth'
        : DateFormat('MMMM d, yyyy').format(_selectedDob!);

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : const Color(0xFFF3F0FA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Dreamy Pastel Sky Background ───────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF120E22),
                          Color(0xFF1B1430),
                          Color(0xFF24153B),
                        ]
                      : const [
                          Color(0xFFECEBFC),
                          Color(0xFFF4F0FB),
                          Color(0xFFFAF5FC),
                        ],
                ),
              ),
            ),
          ),

          // ── 2. Floating Background Bokeh Spheres & Ambient Aura ────────
          Positioned(
            top: 40,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF38BDF8) : const Color(0xFF93C5FD))
                        .withValues(alpha: isDark ? 0.20 : 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 20,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF818CF8) : const Color(0xFFDDD6FE))
                        .withValues(alpha: isDark ? 0.25 : 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF60A5FA,
                      ).withValues(alpha: isDark ? 0.30 : 0.35),
                      const Color(
                        0xFFA78BFA,
                      ).withValues(alpha: isDark ? 0.15 : 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 90,
            left: 55,
            child: _buildBubble(14, const Color(0xFF67E8F9), isDark),
          ),
          Positioned(
            top: 120,
            right: 65,
            child: _buildBubble(18, const Color(0xFFFDE047), isDark),
          ),
          Positioned(
            top: 190,
            left: 30,
            child: _buildBubble(22, const Color(0xFF818CF8), isDark),
          ),

          // ── 3. Bottom Multi-Layer Fluid Undulating Wave Ribbons ─────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _AdultsOnlyFluidWavesPainter(isDark: isDark),
            ),
          ),

          // ── 4. Grand White Dome/Arch Card with 3D Overlapping Shield ───
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: SizedBox(
                  width: 350,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 65),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C162E)
                              : Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(54),
                            bottom: Radius.circular(46),
                          ),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2E244A)
                                : const Color(0xFFEDE9FE),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4C1D95,
                              ).withValues(alpha: isDark ? 0.40 : 0.09),
                              blurRadius: 36,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.04,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(26, 76, 26, 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Adults Only',
                                textAlign: TextAlign.center,
                                style: AppTypography.displaySmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 27,
                                  color: primaryTextColor,
                                  letterSpacing: -0.4,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'MELSAVA is exclusively for adults (18+). Confirm your date of birth to continue.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: mutedTextColor,
                                  height: 1.45,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Date of Birth Picker Card ───────────────
                              GestureDetector(
                                onTap: _isSaving ? null : _pickDateOfBirth,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkElevated
                                        : AppColors.warmIvory,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _isUnderageBlocked
                                          ? AppColors.error
                                          : (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.divider),
                                      width: _isUnderageBlocked ? 1.5 : 1.1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cake_outlined,
                                        size: 20,
                                        color: _isUnderageBlocked
                                            ? AppColors.error
                                            : (isDark
                                                  ? AppColors.luminousMauve
                                                  : AppColors.mauve),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Date of Birth',
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                    color: mutedTextColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              dateLabel,
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                    color: _selectedDob == null
                                                        ? mutedTextColor
                                                        : primaryTextColor,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: mutedTextColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Private DOB guarantee note
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 13,
                                    color: mutedTextColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Kept strictly private and never displayed publicly.',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: mutedTextColor,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (_isUnderageBlocked) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.40,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Access restricted: You must be at least 18 years old to use MELSAVA.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ] else if (_errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 22),

                              // Primary Button: "Confirm & Continue"
                              Opacity(
                                opacity: _isUnderageBlocked ? 0.45 : 1.0,
                                child: Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(27),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF861B5E),
                                        Color(0xFF271066),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF861B5E,
                                        ).withValues(alpha: 0.38),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(27),
                                      onTap: (_isSaving || _isUnderageBlocked)
                                          ? null
                                          : _handleContinue,
                                      child: Center(
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.3,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'I am 18 or Older',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Secondary Link: "I am under 18"
                              GestureDetector(
                                onTap: () {
                                  setState(() => _isUnderageBlocked = true);
                                  _showAgeRestrictionDialog(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'I am under 18',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.luminousMauve
                                          : const Color(0xFF2A1D44),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                              ),

                              if (_isUnderageBlocked) ...[
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: _handleSignOut,
                                  child: Text(
                                    'Sign Out & Return to Welcome',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: mutedTextColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // ── 3D Glossy Heraldic Shield & Gold Checkmark ──────
                      const Positioned(
                        top: 0,
                        child: Glossy3dShieldWidget(width: 122, height: 138),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBubble(double size, Color color, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.35 : 0.50),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }

  void _showAgeRestrictionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Age Requirement (18+)'),
        content: const Text(
          'MELSAVA experiences are strictly designed for individuals 18 years or older to maintain safety and compliance standards. You cannot continue with an under-18 date of birth.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleSignOut();
            },
            child: const Text('Sign Out'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 3D Glossy Heraldic Shield Widget
///
/// Features:
/// - Beveled silver/white outer 3D rim with specular edge highlights
/// - Deep royal blue gradient inner shield surface (cyan to cobalt)
/// - Upper curved glossy glass reflection sheen
/// - Thick 3D extruded golden yellow checkmark with soft drop shadow
/// ─────────────────────────────────────────────────────────────────────────────
class Glossy3dShieldWidget extends StatelessWidget {
  final double width;
  final double height;

  const Glossy3dShieldWidget({super.key, this.width = 122, this.height = 138});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _Glossy3dShieldPainter(),
    );
  }
}

class _Glossy3dShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Heraldic Shield Path
    final outerRect = Rect.fromLTWH(0, 0, w, h);
    final outerPath = _getShieldPath(outerRect);

    // 1. Ambient Drop Shadows / Halo
    final shadowPaint1 = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(outerPath.shift(const Offset(0, 8)), shadowPaint1);

    final shadowPaint2 = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawPath(outerPath, shadowPaint2);

    // 2. Outer 3D Beveled Rim / Frame
    // Top-left specular white to bottom-right lavender shadow
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF1F5F9),
          Color(0xFFE2E8F0),
          Color(0xFFCBD5E1),
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(outerRect);
    canvas.drawPath(outerPath, rimPaint);

    // Outer Rim Specular Highlight Stroke
    final rimStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.40),
          Colors.white.withValues(alpha: 0.10),
        ],
      ).createShader(outerRect);
    canvas.drawPath(outerPath, rimStrokePaint);

    // 3. Inner Inset Shield Face
    // Deflate to create thick protective rim
    final insetMarginW = w * 0.125;
    final insetMarginH = h * 0.115;
    final innerRect = Rect.fromLTWH(
      insetMarginW,
      insetMarginH,
      w - (insetMarginW * 2),
      h - (insetMarginH * 2),
    );
    final innerPath = _getShieldPath(innerRect);

    // Inner Face Gradient: Azure Cyan to Deep Cobalt Blue
    final innerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF2563EB),
          Color(0xFF1D4ED8),
          Color(0xFF1E3A8A),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(innerRect);
    canvas.drawPath(innerPath, innerPaint);

    // 4. Inner Bevel Stroke
    final innerBevelStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.30);
    canvas.drawPath(innerPath, innerBevelStroke);

    // 5. Upper Glossy Glass Reflection Sheen
    canvas.save();
    canvas.clipPath(innerPath);

    final glossRect = Rect.fromLTWH(
      innerRect.left - (w * 0.2),
      innerRect.top - (h * 0.15),
      innerRect.width + (w * 0.4),
      innerRect.height * 0.60,
    );
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(glossRect);
    canvas.drawOval(glossRect, glossPaint);
    canvas.restore();

    // 6. 3D Golden Yellow Checkmark
    final p1 = Offset(w * 0.40, h * 0.51);
    final p2 = Offset(w * 0.49, h * 0.63);
    final p3 = Offset(w * 0.65, h * 0.43);

    final checkPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);

    final checkWidth = w * 0.088;

    // Checkmark Drop Shadow
    final checkShadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = checkWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawPath(checkPath.shift(const Offset(0, 3)), checkShadowPaint);

    // Golden Yellow Checkmark Fill
    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = checkWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF085),
          Color(0xFFFACC15),
          Color(0xFFEAB308),
          Color(0xFFCA8A04),
        ],
      ).createShader(outerRect);
    canvas.drawPath(checkPath, checkPaint);

    // Specular Highlight Line on upper spine of Checkmark
    final checkHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = checkWidth * 0.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawPath(
      checkPath.shift(const Offset(-0.8, -0.8)),
      checkHighlightPaint,
    );
  }

  Path _getShieldPath(Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final l = rect.left;
    final t = rect.top;

    final path = Path();
    // Top-left shoulder
    path.moveTo(l + w * 0.15, t + h * 0.08);
    // Top crest dip to center
    path.quadraticBezierTo(
      l + w * 0.50,
      t + h * 0.16,
      l + w * 0.85,
      t + h * 0.08,
    );
    // Top-right rounded ear / shoulder
    path.quadraticBezierTo(
      l + w * 0.98,
      t + h * 0.09,
      l + w * 0.95,
      t + h * 0.28,
    );
    // Right flank tapering down to bottom point
    path.cubicTo(
      l + w * 0.92,
      t + h * 0.58,
      l + w * 0.72,
      t + h * 0.84,
      l + w * 0.50,
      t + h * 0.98,
    );
    // Left flank tapering up from bottom point
    path.cubicTo(
      l + w * 0.28,
      t + h * 0.84,
      l + w * 0.08,
      t + h * 0.58,
      l + w * 0.05,
      t + h * 0.28,
    );
    // Top-left rounded ear / shoulder
    path.quadraticBezierTo(
      l + w * 0.02,
      t + h * 0.09,
      l + w * 0.15,
      t + h * 0.08,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Bottom Fluid Undulating Waves Painter
///
/// Features 3 smooth organic wave ribbons rising from bottom-left to bottom-right:
/// - Layer 1 (Top): Deep Royal Purple / Indigo
/// - Layer 2 (Middle): Radiant Magenta / Rose Pink
/// - Layer 3 (Bottom): Warm Sunset Apricot / Orange
/// ─────────────────────────────────────────────────────────────────────────────
class _AdultsOnlyFluidWavesPainter extends CustomPainter {
  final bool isDark;

  const _AdultsOnlyFluidWavesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1 (Top Wave): Deep Royal Purple
    final path1 = Path();
    path1.moveTo(0, h * 0.55);
    path1.cubicTo(w * 0.24, h * 0.65, w * 0.52, h * 0.28, w * 0.80, h * 0.32);
    path1.cubicTo(w * 0.90, h * 0.34, w * 0.96, h * 0.26, w, h * 0.22);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF581C87), Color(0xFF7C3AED), Color(0xFF4C1D95)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path1, paint1);

    // Layer 2 (Middle Wave): Vivid Magenta / Rose Pink
    final path2 = Path();
    path2.moveTo(0, h * 0.70);
    path2.cubicTo(w * 0.22, h * 0.76, w * 0.50, h * 0.44, w * 0.78, h * 0.48);
    path2.cubicTo(w * 0.88, h * 0.50, w * 0.96, h * 0.42, w, h * 0.38);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFD946EF), Color(0xFFEC4899), Color(0xFFF43F5E)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path2, paint2);

    // Layer 3 (Bottom Wave): Warm Sunset Apricot / Orange
    final path3 = Path();
    path3.moveTo(0, h * 0.85);
    path3.cubicTo(w * 0.25, h * 0.88, w * 0.55, h * 0.64, w * 0.82, h * 0.66);
    path3.cubicTo(w * 0.92, h * 0.67, w * 0.97, h * 0.60, w, h * 0.56);
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();

    final paint3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFF97316), Color(0xFFFB923C), Color(0xFFFBBF24)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
