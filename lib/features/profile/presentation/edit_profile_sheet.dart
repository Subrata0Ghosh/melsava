import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../core/services/worldwide_location_service.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../auth/presentation/auth_providers.dart';

/// Full-featured interactive Edit Profile Sheet
/// Allows updating:
/// - Avatar photo (preset selection or camera/gallery picker)
/// - Display Name
/// - City / Location (syncs worldwide location)
/// - Primary Intent (Friendship, Dating, Activity Partner, Serious Relationship)
/// - Bio / Headline
/// - Vibe & Interest Tags
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditProfileSheet(),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late String _selectedAvatar;
  late String _selectedCity;
  late String _selectedIntent;
  final Set<String> _selectedInterests = {};
  XFile? _pendingAvatarFile;
  bool _isSaving = false;

  static const List<String> _cities = [
    'Mumbai',
    'Kolkata',
    'Bengaluru',
    'Delhi NCR',
    'Goa',
    'Pune',
    'Hyderabad',
  ];

  static const List<Map<String, dynamic>> _intentOptions = [
    {
      'name': 'Genuine friendship',
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFF6366F1),
    },
    {
      'name': 'Meaningful dating',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFEC4899),
    },
    {
      'name': 'Casual dating',
      'icon': Icons.wine_bar_rounded,
      'color': Color(0xFFF43F5E),
    },
    {
      'name': 'Activity partner',
      'icon': Icons.extension_rounded,
      'color': Color(0xFFF97316),
    },
    {
      'name': 'Marriage-minded',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Open to discovering',
      'icon': Icons.explore_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'name': 'Serious relationship',
      'icon': Icons.favorite_border_rounded,
      'color': Color(0xFFD946EF),
    },
  ];

  static const List<String> _availableInterests = [
    'Art',
    'Coffee',
    'Cooking',
    'Dancing',
    'Fitness',
    'Gaming',
    'Gardening',
    'Hiking',
    'Languages',
    'Meditation',
    'Movies',
    'Music',
    'Photography',
    'Reading',
    'Technology',
    'Travel',
    'Volunteering',
    'Yoga',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final userLoc = ref.read(userLocationProvider);

    _nameController = TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _selectedAvatar = user?.avatarUrl ?? '';
    _selectedCity = user?.city ?? userLoc.city;
    _selectedIntent = user?.primaryIntent ?? 'Genuine friendship';

    _selectedInterests.addAll(user?.interests ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomAvatar() async {
    HapticFeedback.lightImpact();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _pendingAvatarFile = picked;
          _selectedAvatar = picked.path;
        });
      }
    } catch (e) {
      debugPrint('Avatar pick error: $e');
    }
  }

  Future<void> _saveProfile() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to edit your profile.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name must be at least 2 characters'),
        ),
      );
      return;
    }

    if (name.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name cannot exceed 50 characters'),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      String finalAvatarUrl = _selectedAvatar;

      // If user selected a new custom image from gallery, upload to Supabase Storage
      if (_pendingAvatarFile != null) {
        final uploadedUrl = await ref
            .read(authRepositoryProvider)
            .uploadAvatar(_pendingAvatarFile!);
        if (uploadedUrl == null || uploadedUrl.isEmpty) {
          throw Exception('Failed to upload image. Please try again.');
        }
        finalAvatarUrl = uploadedUrl;
      }

      final updatedUser = currentUser.copyWith(
        displayName: name,
        avatarUrl: finalAvatarUrl,
        city: _selectedCity,
        bio: _bioController.text.trim(),
        primaryIntent: _selectedIntent,
        interests: _selectedInterests.toList(),
      );

      // Persist atomically via update_user_profile RPC only
      await ref.read(authRepositoryProvider).updateProfile(updatedUser);
      ref.read(currentUserProvider.notifier).state = updatedUser;

      // Sync Location Service if city changed without fabricating Mumbai coords
      final matchedCity = WorldwideLocationService.featuredWorldCities
          .where(
            (c) =>
                c.name.toLowerCase() == _selectedCity.toLowerCase() ||
                c.city.toLowerCase() == _selectedCity.toLowerCase(),
          )
          .firstOrNull;

      if (matchedCity != null) {
        await ref.read(userLocationProvider.notifier).setLocation(matchedCity);
      } else {
        final currentLoc = ref.read(userLocationProvider);
        await ref
            .read(userLocationProvider.notifier)
            .setLocation(
              WorldLocation(
                name: _selectedCity,
                city: _selectedCity,
                country: currentLoc.country,
                lat: currentLoc.lat,
                lon: currentLoc.lon,
              ),
            );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Profile updated successfully! ✨',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      // Retain edited form values and offer retry
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
          content: Text('Failed to update profile: $e'),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _saveProfile,
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
        : const Color(0xFF1E1435);
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : const Color(0xFF7E7394);
    final sheetBg = isDark ? const Color(0xFF1A1329) : Colors.white;
    final cardBg = isDark ? const Color(0xFF241C38) : const Color(0xFFF8F6FD);
    final borderColor = isDark
        ? const Color(0xFF382F4D)
        : const Color(0xFFE9E4F5);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Drag Pill
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFDDD6FE),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: mutedTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Edit Profile',
                  style: AppTypography.titleMedium.copyWith(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 17.5,
                  ),
                ),
                GestureDetector(
                  onTap: _isSaving ? null : _saveProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.sunsetCtaGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.7),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar Photo Picker ──
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.brightViolet
                                  : AppColors.primaryPurple,
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? AppColors.brightViolet
                                            : AppColors.primaryPurple)
                                        .withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: AppSmartImage(
                              imagePath: _selectedAvatar,
                              isAvatar: true,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Camera overlay badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickCustomAvatar,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: AppColors.purpleGradient,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: TextButton.icon(
                      onPressed: _pickCustomAvatar,
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: Text(
                        _pendingAvatarFile != null
                            ? 'Change Selected Photo'
                            : 'Upload Profile Photo',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.brightViolet
                            : AppColors.primaryPurple,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  if (_pendingAvatarFile != null)
                    Center(
                      child: Text(
                        'New image selected · Tap Save to upload',
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Display Name Field ──
                  _buildSectionHeader('FULL NAME', isDark),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Your Name',
                    icon: Icons.person_outline_rounded,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: primaryTextColor,
                  ),

                  const SizedBox(height: 20),

                  // ── City Location Dropdown ──
                  _buildSectionHeader('CITY LOCATION', isDark),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primaryTextColor,
                        ),
                        style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        items: _cities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 10),
                                Text(city),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCity = val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Primary Intent Selection ──
                  _buildSectionHeader('PRIMARY INTENT', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _intentOptions.map((opt) {
                      final name = opt['name'] as String;
                      final isSelected = _selectedIntent == name;
                      final color = opt['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedIntent = name);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? color : cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? color : borderColor,
                              width: 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                size: 16,
                                color: isSelected ? Colors.white : color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : primaryTextColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Bio / Headline ──
                  _buildSectionHeader('BIO & PHILOSOPHY', isDark),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: TextField(
                      controller: _bioController,
                      maxLines: 3,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText:
                            'Share a little about who you are and what moments you love...',
                        hintStyle: TextStyle(
                          color: mutedTextColor,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Vibe & Interests Tags ──
                  _buildSectionHeader('INTERESTS & ACTIVITIES', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableInterests.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (isSelected) {
                              _selectedInterests.remove(interest);
                            } else {
                              _selectedInterests.add(interest);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppColors.purpleGradient
                                : null,
                            color: isSelected ? null : cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                        ? AppColors.brightViolet
                                        : AppColors.primaryPurple)
                                  : borderColor,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            interest,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : primaryTextColor,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // ── Full-Width Save CTA ──
                  GestureDetector(
                    onTap: _isSaving ? null : _saveProfile,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.sunsetCtaGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF5E7E,
                            ).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                              ),
                            ),
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        color: isDark ? AppColors.softCoral : AppColors.mauve,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
