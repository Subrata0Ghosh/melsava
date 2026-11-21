import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/supabase_service.dart';
import '../e2ee/e2ee_service.dart';

/// Screen displaying cryptographic safety numbers, QR code verification,
/// and end-to-end encryption transparency details for a conversation.
class SecurityInfoScreen extends ConsumerStatefulWidget {
  final String participantName;
  final String partnerId;

  const SecurityInfoScreen({
    super.key,
    required this.participantName,
    required this.partnerId,
  });

  static Future<void> show(
    BuildContext context, {
    required String participantName,
    required String partnerId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SecurityInfoScreen(
          participantName: participantName,
          partnerId: partnerId,
        ),
      ),
    );
  }

  @override
  ConsumerState<SecurityInfoScreen> createState() => _SecurityInfoScreenState();
}

class _SecurityInfoScreenState extends ConsumerState<SecurityInfoScreen> {
  SafetyNumberResult? _safetyResult;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadSafetyNumber();
  }

  Future<void> _loadSafetyNumber() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUid = SupabaseService.client?.auth.currentUser?.id;
    if (currentUid == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not authenticated.';
      });
      return;
    }

    try {
      final e2ee = ref.read(e2eeServiceProvider);
      final res = await e2ee.computeSafetyNumber(
        localUserId: currentUid,
        remoteUserId: widget.partnerId,
      );

      if (!mounted) return;
      setState(() {
        _safetyResult = res;
        _isVerified = res.isVerified;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not generate safety number: ${e.toString()}';
      });
    }
  }

  Future<void> _toggleVerified(bool val) async {
    HapticFeedback.lightImpact();
    setState(() => _isVerified = val);
    final e2ee = ref.read(e2eeServiceProvider);
    await e2ee.setSafetyNumberVerified(widget.partnerId, val);
  }

  Future<void> _acknowledgeKeyChange() async {
    HapticFeedback.mediumImpact();
    final e2ee = ref.read(e2eeServiceProvider);
    await e2ee.acknowledgeIdentityChange(widget.partnerId);
    await _loadSafetyNumber();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New security code for ${widget.participantName} acknowledged.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Encryption & Safety',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryPurple,
                ),
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSafetyNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // ── Lock & Header ──
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.purpleGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'End-to-End Encrypted',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Messages with ${widget.participantName} are secured with the Signal Protocol (Double Ratchet & X3DH). Nobody outside of this chat, not even MELSAVA, can read them.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedTextColor,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Key Change Warning Banner (if applicable) ──
                  if (_safetyResult?.hasIdentityChanged == true) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFEF4444),
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Security Code Changed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.participantName}\'s security code changed. This frequently occurs when someone reinstalls MELSAVA or switches to a new phone. Verify their new code below.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? Colors.white70 : AppColors.deepPlum,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _acknowledgeKeyChange,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Acknowledge New Code'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── QR Code Verification ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _safetyResult!.qrCodeData,
                            version: QrVersions.auto,
                            size: 180.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF1E1035),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF1E1035),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'SAFETY NUMBER',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: isDark
                                ? AppColors.softCoral
                                : AppColors.mauve,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 60-digit number display
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.obsidian.withValues(alpha: 0.5)
                                : AppColors.warmIvory,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _safetyResult!.formattedNumber,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13.5,
                              letterSpacing: 1.2,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Compare this 60-digit number with ${widget.participantName}\'s phone, or scan their QR code to verify this is a private, direct channel.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: mutedTextColor,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Verification Toggle ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isVerified
                              ? Icons.verified_user_rounded
                              : Icons.gpp_maybe_rounded,
                          color: _isVerified
                              ? const Color(0xFF10B981)
                              : mutedTextColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isVerified
                                    ? 'Contact Verified'
                                    : 'Mark as Verified',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                              Text(
                                _isVerified
                                    ? 'Cryptographic safety number confirmed'
                                    : 'Toggle once verified in person or over video',
                                style: AppTypography.bodySmall.copyWith(
                                  color: mutedTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isVerified,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF10B981),
                          onChanged: _toggleVerified,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Technical Explanations ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECURITY SPECIFICATIONS',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.softCoral
                                : AppColors.mauve,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSpecRow(
                          icon: Icons.vpn_key_rounded,
                          title: 'Forward Secrecy & Ratcheting',
                          desc:
                              'Each message uses a unique ephemeral key derived from the Double Ratchet. Past messages cannot be decrypted even if a key is compromised.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildSpecRow(
                          icon: Icons.cloud_off_rounded,
                          title: 'Zero Plaintext Server Relay',
                          desc:
                              'Supabase stores only encrypted ciphertext envelopes. Database administrators and server processes have zero plaintext access.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildSpecRow(
                          icon: Icons.phonelink_lock_rounded,
                          title: 'Hardware Keystore Storage',
                          desc:
                              'Private identity keys never leave your phone and are kept in hardware-backed storage (Android Keystore / iOS Keychain).',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppColors.mutedText,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
