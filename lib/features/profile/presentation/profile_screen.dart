import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../auth/presentation/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardRadiusLarge,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepPlum.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.sage,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.mauve,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMD),
                    Text(
                      user?.displayName ?? 'Explorer',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.deepPlum,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user?.city ?? 'Mumbai, India'} • Adult Certified (18+)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMD),
                    Text(
                      'Enjoys discovering specialty coffee roasters, weekend nature walks, and friendly board games.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.deepPlum,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingLG),

              // Intentions Section
              Text(
                'My Intentions',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Wrap(
                spacing: AppConstants.spacingSM,
                runSpacing: AppConstants.spacingSM,
                children: [
                  _buildTag('Genuine friendship', isPrimary: true),
                  _buildTag('Activity partner', isPrimary: true),
                  _buildTag('Meaningful dating', isPrimary: false),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLG),

              // Interests Section
              Text(
                'My Interests',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Wrap(
                spacing: AppConstants.spacingSM,
                runSpacing: AppConstants.spacingSM,
                children: [
                  _buildTag('Specialty Coffee', isPrimary: false),
                  _buildTag('Nature Photography', isPrimary: false),
                  _buildTag('Badminton', isPrimary: false),
                  _buildTag('Historical Fiction', isPrimary: false),
                  _buildTag('Board Games', isPrimary: false),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Safety & Settings List
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardRadiusSmall,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.mauve,
                      ),
                      title: Text(
                        'Community Guidelines & Safety',
                        style: AppTypography.bodyMedium,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.mutedText,
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.white,
                            title: const Text('MELSAVA Community Standards'),
                            content: const Text(
                              '1. Respect & Consent: All connections are strictly mutual.\n2. Public Venues Only: All offline activities take place in public, vetted locations.\n3. Zero Harassment: Harassment or unwanted contact results in immediate account suspension.\n4. Adult Community: Exclusively for respectful adults.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Understood'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline,
                        color: AppColors.mauve,
                      ),
                      title: Text(
                        'Privacy & Visibility Controls',
                        style: AppTypography.bodyMedium,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.mutedText,
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Your exact location and private choices are always hidden.',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.error),
                      title: Text(
                        'Sign Out',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      onTap: () {
                        ConfirmationDialog.show(
                          context,
                          title: 'Sign Out?',
                          message:
                              'Are you sure you want to sign out of MELSAVA?',
                          confirmLabel: 'Sign Out',
                          isDestructive: true,
                        ).then((confirmed) {
                          if (confirmed == true && context.mounted) {
                            ref.read(authRepositoryProvider).signOut();
                            ref.read(currentUserProvider.notifier).state = null;
                            context.go('/welcome');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.deepPlum : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
        border: Border.all(
          color: isPrimary ? AppColors.deepPlum : AppColors.divider,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: isPrimary ? AppColors.white : AppColors.deepPlum,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
