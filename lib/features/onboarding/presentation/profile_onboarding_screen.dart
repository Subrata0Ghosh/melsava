import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../core/utils/auth_validators.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/glass_back_button.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_providers.dart';

/// Guided 6-step Profile Onboarding Wizard for authenticated, 18+ verified users.
///
/// Collects all Phase 1 profile fields while preserving the MELSAVA Warm Ivory / Deep Plum /
/// Mauve / Soft Coral / Sage aesthetic in both Light and Dark themes.
class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  static const int _totalSteps = 6;
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

  // Step 1: Display Name & Photo
  late final TextEditingController _nameController;
  String? _uploadedAvatarUrl;
  String? _localPreviewPath;
  Uint8List? _localPreviewBytes;
  bool _isUploadingPhoto = false;
  String? _photoError;

  // Step 2: Broad Location & Short Bio
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;

  // Step 3: Interests & Activity Preferences
  final Set<String> _selectedInterests = {};
  final Set<String> _selectedActivities = {};

  // Step 4: Connection Intentions
  final Set<String> _selectedIntentions = {};
  String? _primaryIntention;

  // Step 5: Availability & Discovery Preferences
  final Set<String> _selectedAvailability = {'Weekends', 'Weekday Evenings'};
  RangeValues _ageRange = const RangeValues(21, 40);
  double _maxDistanceKm = 25;
  String _discoveryFormat = 'Both';

  // Step 6: Community Guidelines
  bool _guidelinesAccepted = false;

  // Submission state
  bool _isSubmitting = false;
  String? _stepError;

  static const List<String> _availabilityOptions = [
    'Weekday Mornings',
    'Weekday Afternoons',
    'Weekday Evenings',
    'Weekend Mornings',
    'Weekend Afternoons',
    'Weekend Evenings',
    'Flexible',
  ];

  static const List<String> _formatOptions = ['In-Person', 'Online', 'Both'];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final initialName =
        (user?.displayName != null && user!.displayName != 'New User')
        ? user.displayName!
        : '';
    _nameController = TextEditingController(text: initialName);
    _uploadedAvatarUrl = user?.avatarUrl;
    _cityController = TextEditingController(text: user?.city ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');

    if (user?.interests != null) {
      _selectedInterests.addAll(user!.interests!);
    }
    _selectedActivities.addAll(user?.preferredActivityCategories ?? const []);
    if (user?.primaryIntent != null && user!.primaryIntent!.isNotEmpty) {
      _primaryIntention = user.primaryIntent;
      _selectedIntentions.add(user.primaryIntent!);
    }
    _selectedIntentions.addAll(user?.secondaryIntents ?? const []);
    if (user != null && user.availability.isNotEmpty) {
      _selectedAvailability
        ..clear()
        ..addAll(user.availability);
    }
    if (user != null) {
      _ageRange = RangeValues(
        user.discoveryMinAge.clamp(18, 65).toDouble(),
        user.discoveryMaxAge.clamp(18, 65).toDouble(),
      );
      _maxDistanceKm = user.discoveryMaxDistanceKm.clamp(5, 100).toDouble();
      _discoveryFormat = user.discoveryFormat;
      _guidelinesAccepted = user.guidelinesAccepted;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _photoError = null;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';

      setState(() {
        _localPreviewPath = picked.path;
        _localPreviewBytes = bytes;
        _isUploadingPhoto = true;
        _photoError = null;
      });

      final repo = ref.read(onboardingRepositoryProvider);
      final publicUrl = await repo.uploadProfilePhoto(
        userId: user.id,
        bytes: bytes,
        fileExtension: ext,
        localFallbackPath: picked.path,
      );

      if (mounted) {
        setState(() {
          _uploadedAvatarUrl = publicUrl;
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _photoError =
              'Photo upload failed: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  void _showPhotoSourceSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Add Profile Photo',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.deepPlum,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.mauve,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.mauve,
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    setState(() => _stepError = null);

    switch (_currentStep) {
      case 0:
        final err = AuthValidators.validateDisplayName(_nameController.text);
        if (err != null) {
          setState(() => _stepError = err);
          return false;
        }
        if (_isUploadingPhoto) {
          setState(
            () => _stepError = 'Please wait for your photo upload to finish.',
          );
          return false;
        }
        return true;

      case 1:
        final cityErr = AuthValidators.validateCity(_cityController.text);
        if (cityErr != null) {
          setState(() => _stepError = cityErr);
          return false;
        }
        final bioErr = AuthValidators.validateBio(_bioController.text);
        if (bioErr != null) {
          setState(() => _stepError = bioErr);
          return false;
        }
        return true;

      case 2:
        if (_selectedInterests.isEmpty) {
          setState(() => _stepError = 'Please choose at least one interest.');
          return false;
        }
        if (_selectedActivities.isEmpty) {
          setState(
            () => _stepError =
                'Please choose at least one preferred activity category.',
          );
          return false;
        }
        return true;

      case 3:
        if (_selectedIntentions.isEmpty || _primaryIntention == null) {
          setState(
            () =>
                _stepError = 'Please choose at least one connection intention.',
          );
          return false;
        }
        return true;

      case 4:
        if (_selectedAvailability.isEmpty) {
          setState(
            () => _stepError = 'Please pick at least one availability window.',
          );
          return false;
        }
        return true;

      case 5:
        if (!_guidelinesAccepted) {
          setState(
            () => _stepError =
                'Please accept the MELSAVA Community Guidelines to complete onboarding.',
          );
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _handleNext() {
    HapticFeedback.lightImpact();
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _stepError = null;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } else {
      _handleCompleteOnboarding();
    }
  }

  void _handleBack() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _stepError = null;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  Future<void> _handleCompleteOnboarding() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/welcome');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _stepError = null;
    });

    try {
      final draft = OnboardingProfileDraft(
        userId: user.id,
        email: user.email,
        displayName: _nameController.text.trim(),
        avatarUrl: _uploadedAvatarUrl,
        city: _cityController.text.trim(),
        bio: _bioController.text.trim(),
        interests: _selectedInterests.toList(),
        preferredActivityCategories: _selectedActivities.toList(),
        primaryIntention: _primaryIntention ?? _selectedIntentions.first,
        intentions: _selectedIntentions.toList(),
        availability: _selectedAvailability.toList(),
        discoveryMinAge: _ageRange.start.round(),
        discoveryMaxAge: _ageRange.end.round(),
        discoveryMaxDistanceKm: _maxDistanceKm.round(),
        discoveryFormat: _discoveryFormat,
        guidelinesAccepted: _guidelinesAccepted,
      );

      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final updatedUser = await onboardingRepo.completeProfileOnboarding(
        currentUser: user,
        draft: draft,
      );
      ref.read(currentUserProvider.notifier).state = updatedUser;

      if (mounted) {
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is PostgrestException) {
          msg = e.message;
        } else if (e is AuthException) {
          msg = e.message;
        }
        setState(() {
          _isSubmitting = false;
          _stepError = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final refDataAsync = ref.watch(onboardingReferenceDataProvider);

    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.eucalyptus,
        leafColors: BotanicalLeafDecoration.mintDew,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header Bar & Progress Indicator ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (_currentStep > 0)
                          GlassBackButton(
                            isDark: isDark,
                            iconColor: primaryText,
                            onTap: _handleBack,
                          )
                        else
                          const SizedBox(width: 44),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Set Up Your Profile',
                                style: AppTypography.titleMedium.copyWith(
                                  color: primaryText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Step ${_currentStep + 1} of $_totalSteps',
                                style: AppTypography.bodySmall.copyWith(
                                  color: mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref.read(authRepositoryProvider).signOut();
                            ref.read(currentUserProvider.notifier).state = null;
                            if (context.mounted) {
                              context.go('/welcome');
                            }
                          },
                          child: Text(
                            'Sign Out',
                            style: AppTypography.labelSmall.copyWith(
                              color: mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.luminousMauve : AppColors.mauve,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Step Content ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_stepError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _stepError!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_currentStep == _totalSteps - 1 &&
                                  !_isSubmitting)
                                TextButton(
                                  onPressed: _handleNext,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      _buildStepBody(
                        isDark: isDark,
                        primaryText: primaryText,
                        mutedText: mutedText,
                        refDataAsync: refDataAsync,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom Action Bar ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: PrimaryButton(
                  label: _currentStep == _totalSteps - 1
                      ? 'Complete Profile & Explore →'
                      : 'Continue',
                  isLoading: _isSubmitting,
                  gradient: _currentStep == _totalSteps - 1
                      ? AppColors.sunsetCtaGradient
                      : null,
                  backgroundColor: isDark
                      ? AppColors.luminousMauve
                      : AppColors.deepPlum,
                  onPressed: _isSubmitting ? null : _handleNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody({
    required bool isDark,
    required Color primaryText,
    required Color mutedText,
    required AsyncValue<OnboardingReferenceData> refDataAsync,
  }) {
    switch (_currentStep) {
      case 0:
        return _buildStepIdentityAndPhoto(isDark, primaryText, mutedText);
      case 1:
        return _buildStepLocationAndBio(isDark, primaryText, mutedText);
      case 2:
        return _buildStepInterestsAndActivities(
          isDark,
          primaryText,
          mutedText,
          refDataAsync,
        );
      case 3:
        return _buildStepIntentions(
          isDark,
          primaryText,
          mutedText,
          refDataAsync,
        );
      case 4:
        return _buildStepAvailabilityAndDiscovery(
          isDark,
          primaryText,
          mutedText,
        );
      case 5:
        return _buildStepCommunityGuidelines(isDark, primaryText, mutedText);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── STEP 1: Display Name & Profile Photo ──────────────────────────────────
  Widget _buildStepIdentityAndPhoto(
    bool isDark,
    Color primaryText,
    Color mutedText,
  ) {
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How should people know you?',
          style: AppTypography.headlineMedium.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the name and friendly photo fellow experience participants will see.',
          style: AppTypography.bodyMedium.copyWith(
            color: mutedText,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),

        // Avatar Picker Card
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto
                    ? null
                    : () => _showPhotoSourceSheet(isDark),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceBg,
                        border: Border.all(
                          color: isDark
                              ? AppColors.luminousMauve
                              : AppColors.mauve,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.30 : 0.08,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(child: _buildAvatarPreview(isDark)),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.luminousMauve
                              : AppColors.mauve,
                          border: Border.all(
                            color: isDark
                                ? AppColors.obsidian
                                : AppColors.warmIvory,
                            width: 2.5,
                          ),
                        ),
                        child: _isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isUploadingPhoto
                    ? null
                    : () => _showPhotoSourceSheet(isDark),
                child: Text(
                  _uploadedAvatarUrl != null
                      ? 'Change Profile Photo'
                      : 'Upload Profile Photo (Optional)',
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_photoError != null) ...[
                Text(
                  _photoError!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _nameController,
          label: 'Display Name',
          hintText: 'e.g. Aarav or Sneha',
          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.sage).withValues(
              alpha: isDark ? 0.65 : 0.45,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: isDark ? AppColors.luminousMauve : AppColors.mauve,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your display name is shown to small-group co-attendees. First names or friendly nicknames work great.',
                  style: AppTypography.bodySmall.copyWith(
                    color: primaryText,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPreview(bool isDark) {
    if (_localPreviewBytes != null && kIsWeb) {
      return Image.memory(_localPreviewBytes!, fit: BoxFit.cover);
    }
    if (_localPreviewPath != null &&
        !kIsWeb &&
        File(_localPreviewPath!).existsSync()) {
      return Image.file(File(_localPreviewPath!), fit: BoxFit.cover);
    }
    if (_uploadedAvatarUrl != null && _uploadedAvatarUrl!.isNotEmpty) {
      return AppSmartImage(
        imagePath: _uploadedAvatarUrl!,
        isAvatar: true,
        nameHint: _nameController.text,
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
      child: Icon(
        Icons.person_rounded,
        size: 52,
        color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
      ),
    );
  }

  // ── STEP 2: Broad Location & Short Bio ────────────────────────────────────
  Widget _buildStepLocationAndBio(
    bool isDark,
    Color primaryText,
    Color mutedText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where are you based?',
          style: AppTypography.headlineMedium.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Share a broad city or neighborhood so we can surface nearby public experiences. Exact addresses are never shared.',
          style: AppTypography.bodyMedium.copyWith(
            color: mutedText,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),

        CustomTextField(
          controller: _cityController,
          label: 'City or Broad Area',
          hintText: 'e.g. Mumbai, Bengaluru, London',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
        ),
        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              await LocationVenuePickerSheet.show(context);
              if (!mounted) return;
              final loc = ref.read(userLocationProvider);
              if (loc.city.isNotEmpty) {
                setState(() {
                  _cityController.text = loc.city;
                });
              }
            },
            icon: Icon(
              Icons.public_rounded,
              size: 18,
              color: isDark ? AppColors.luminousMauve : AppColors.mauve,
            ),
            label: Text(
              'Search worldwide city or use GPS',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        CustomTextField(
          controller: _bioController,
          label: 'Short Bio (Optional)',
          hintText:
              'Tell people a little about yourself, hobbies, or favorite weekend plans...',
          maxLines: 4,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_bioController.text.trim().length}/500 characters',
            style: AppTypography.bodySmall.copyWith(color: mutedText),
          ),
        ),
      ],
    );
  }

  // ── STEP 3: Interests & Activity Preferences ──────────────────────────────
  Widget _buildStepInterestsAndActivities(
    bool isDark,
    Color primaryText,
    Color mutedText,
    AsyncValue<OnboardingReferenceData> refDataAsync,
  ) {
    final data =
        refDataAsync.valueOrNull ??
        const OnboardingReferenceData(
          interests: SupabaseOnboardingRepository.defaultInterests,
          intentions: SupabaseOnboardingRepository.defaultIntentions,
          activityCategories:
              SupabaseOnboardingRepository.defaultActivityCategories,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Interests & Activities',
          style: AppTypography.headlineMedium.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick topics you love and experiences you want to see first on Discover.',
          style: AppTypography.bodyMedium.copyWith(
            color: mutedText,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),

        Text(
          'YOUR INTERESTS (${_selectedInterests.length} selected)',
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.softCoral : AppColors.mauve,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.interests.map((item) {
            final selected = _selectedInterests.contains(item.name);
            return _buildSelectableChip(
              label: item.name,
              selected: selected,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _selectedInterests.remove(item.name);
                  } else {
                    _selectedInterests.add(item.name);
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 26),

        Text(
          'PREFERRED ACTIVITIES (${_selectedActivities.length} selected)',
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.softCoral : AppColors.mauve,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.activityCategories.map((cat) {
            final selected = _selectedActivities.contains(cat.name);
            return _buildSelectableChip(
              label: cat.name,
              selected: selected,
              isDark: isDark,
              accentColor: AppColors.softCoral,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _selectedActivities.remove(cat.name);
                  } else {
                    _selectedActivities.add(cat.name);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── STEP 4: Connection Intentions ─────────────────────────────────────────
  Widget _buildStepIntentions(
    bool isDark,
    Color primaryText,
    Color mutedText,
    AsyncValue<OnboardingReferenceData> refDataAsync,
  ) {
    final data =
        refDataAsync.valueOrNull ??
        const OnboardingReferenceData(
          interests: SupabaseOnboardingRepository.defaultInterests,
          intentions: SupabaseOnboardingRepository.defaultIntentions,
          activityCategories:
              SupabaseOnboardingRepository.defaultActivityCategories,
        );
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What brings you to MELSAVA?',
          style: AppTypography.headlineMedium.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select one or more connection intentions. Tap the star badge on your primary intention.',
          style: AppTypography.bodyMedium.copyWith(
            color: mutedText,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),

        ...data.intentions.map((intent) {
          final isSelected = _selectedIntentions.contains(intent.name);
          final isPrimary = _primaryIntention == intent.name;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) {
                  _selectedIntentions.remove(intent.name);
                  if (_primaryIntention == intent.name) {
                    _primaryIntention = _selectedIntentions.isNotEmpty
                        ? _selectedIntentions.first
                        : null;
                  }
                } else {
                  _selectedIntentions.add(intent.name);
                  _primaryIntention ??= intent.name;
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                          .withValues(alpha: isDark ? 0.18 : 0.08)
                    : cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                      : borderColor,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                        : mutedText,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          intent.name,
                          style: AppTypography.titleSmall.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (intent.description != null &&
                            intent.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            intent.description!,
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _primaryIntention = intent.name);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? (isDark
                                    ? AppColors.luminousMauve
                                    : AppColors.mauve)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.warmIvory),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPrimary ? 'Primary ★' : 'Set Primary',
                          style: AppTypography.labelSmall.copyWith(
                            color: isPrimary ? Colors.white : mutedText,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── STEP 5: Availability & Discovery Preferences ──────────────────────────
  Widget _buildStepAvailabilityAndDiscovery(
    bool isDark,
    Color primaryText,
    Color mutedText,
  ) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Availability & Discovery',
          style: AppTypography.headlineMedium.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Help us match you with experiences that fit your schedule and comfort.',
          style: AppTypography.bodyMedium.copyWith(
            color: mutedText,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),

        Text(
          'WHEN ARE YOU USUALLY FREE?',
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.softCoral : AppColors.mauve,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availabilityOptions.map((slot) {
            final selected = _selectedAvailability.contains(slot);
            return _buildSelectableChip(
              label: slot,
              selected: selected,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _selectedAvailability.remove(slot);
                  } else {
                    _selectedAvailability.add(slot);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Age Range & Distance Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preferred Age Range',
                    style: AppTypography.titleSmall.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_ageRange.start.round()} – ${_ageRange.end.round()} yrs',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 65,
                divisions: 47,
                activeColor: isDark ? AppColors.luminousMauve : AppColors.mauve,
                onChanged: (values) => setState(() => _ageRange = values),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discovery Radius',
                    style: AppTypography.titleSmall.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Up to ${_maxDistanceKm.round()} km',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxDistanceKm,
                min: 5,
                max: 100,
                divisions: 19,
                activeColor: isDark ? AppColors.luminousMauve : AppColors.mauve,
                onChanged: (val) => setState(() => _maxDistanceKm = val),
              ),
              const SizedBox(height: 12),
              Text(
                'Experience Format',
                style: AppTypography.titleSmall.copyWith(
                  color: primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _formatOptions.map((fmt) {
                  final selected = _discoveryFormat == fmt;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: fmt == _formatOptions.last ? 0 : 8,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _discoveryFormat = fmt);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? (isDark
                                      ? AppColors.luminousMauve
                                      : AppColors.mauve)
                                : (isDark
                                      ? AppColors.darkElevated
                                      : AppColors.warmIvory),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : borderColor,
                            ),
                          ),
                          child: Text(
                            fmt,
                            style: AppTypography.labelMedium.copyWith(
                              color: selected ? Colors.white : primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 6: Community Guidelines Acceptance ───────────────────────────────
  Widget _buildStepCommunityGuidelines(
    bool isDark,
    Color primaryText,
    Color mutedText,
  ) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    const commitments = [
      (
        icon: Icons.public_rounded,
        title: 'Public Venues Only',
        desc:
            'Meet in vetted public spaces and respect everyone\'s comfort and boundaries.',
      ),
      (
        icon: Icons.favorite_border_rounded,
        title: 'Mutual Consent Always',
        desc:
            'Post-experience choices remain strictly private and connections form only when mutual.',
      ),
      (
        icon: Icons.handshake_outlined,
        title: 'Kindness & Authenticity',
        desc:
            'Show up as your genuine self. Harassment, spam, or disrespectful conduct leads to removal.',
      ),
      (
        icon: Icons.shield_outlined,
        title: 'Privacy & 18+ Community',
        desc:
            'Never share another participant\'s details without consent. Adults 18+ only.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Community Safety Pledge',
          style: AppTypography.headlineMedium.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Every member agrees to uphold these core standards before joining real-world experiences.',
          style: AppTypography.bodyMedium.copyWith(
            color: mutedText,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              for (int i = 0; i < commitments.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (isDark ? AppColors.luminousMauve : AppColors.sage)
                                .withValues(alpha: isDark ? 0.18 : 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        commitments[i].icon,
                        size: 18,
                        color: isDark
                            ? AppColors.luminousMauve
                            : AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commitments[i].title,
                            style: AppTypography.titleSmall.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            commitments[i].desc,
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (i < commitments.length - 1)
                  Divider(height: 20, color: borderColor),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Mandatory Acceptance Checkbox Card
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _guidelinesAccepted = !_guidelinesAccepted);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _guidelinesAccepted
                  ? (isDark ? AppColors.luminousMauve : AppColors.sage)
                        .withValues(alpha: isDark ? 0.18 : 0.55)
                  : cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _guidelinesAccepted
                    ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                    : borderColor,
                width: _guidelinesAccepted ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _guidelinesAccepted,
                  activeColor: isDark
                      ? AppColors.luminousMauve
                      : AppColors.mauve,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) =>
                      setState(() => _guidelinesAccepted = val ?? false),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'I agree to follow the MELSAVA Community Guidelines, Privacy Policy, and Terms of Service.',
                      style: AppTypography.bodySmall.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool selected,
    required bool isDark,
    Color? accentColor,
    required VoidCallback onTap,
  }) {
    final activeBg =
        accentColor ?? (isDark ? AppColors.luminousMauve : AppColors.mauve);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? activeBg
              : (isDark ? AppColors.darkSurface : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeBg
                : (isDark ? AppColors.darkBorder : AppColors.divider),
            width: 1.1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected
                ? (accentColor == AppColors.softCoral
                      ? AppColors.deepPlum
                      : Colors.white)
                : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
