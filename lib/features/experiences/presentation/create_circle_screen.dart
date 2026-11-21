import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/glass_back_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/experiences_repository.dart';
import '../domain/circle_creation_model.dart';

/// Screen allowing any eligible user to create a new local activity/circle.
class CreateCircleScreen extends ConsumerStatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  ConsumerState<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends ConsumerState<CreateCircleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 0);
  int _durationMinutes = 90;
  int _maxParticipants = 6;
  bool _isOnline = false;
  bool _isFree = true;
  bool _isRecurring = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default city from current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user?.city != null && user!.city!.isNotEmpty) {
        _cityController.text = user.city!;
      } else {
        _cityController.text = 'Kolkata';
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  DateTime get _calculatedStartsAt {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now)
          ? now.add(const Duration(days: 1))
          : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleCreate() async {
    if (_isSubmitting) return;

    if (_titleController.text.trim().length < 5) {
      setState(
        () => _errorMessage = 'Activity title must be at least 5 characters.',
      );
      return;
    }

    if (_descController.text.trim().length < 15) {
      setState(
        () => _errorMessage =
            'Please provide a descriptive explanation (minimum 15 characters).',
      );
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select an activity category.');
      return;
    }

    if (!_isOnline && _venueNameController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            'Please specify a public meeting venue or landmark.',
      );
      return;
    }

    final startsAt = _calculatedStartsAt;
    if (startsAt.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      setState(
        () => _errorMessage =
            'Activity start time must be at least 30 minutes in the future.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final input = CircleCreationInput(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategoryId!,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : 'Kolkata',
        area: _areaController.text.trim(),
        venueName: _isOnline
            ? 'Online Video Circle'
            : _venueNameController.text.trim(),
        venueAddress: _venueAddressController.text.trim(),
        isOnline: _isOnline,
        startsAt: startsAt,
        durationMinutes: _durationMinutes,
        maxParticipants: _maxParticipants,
        isFree: _isFree,
        priceAmount: _isFree
            ? 0.0
            : (double.tryParse(_priceController.text) ?? 0.0),
        isRecurring: _isRecurring,
        cancellationPolicy:
            'Free cancellation up to 24 hours before the circle.',
      );

      final result = await ref
          .read(experiencesRepositoryProvider)
          .createCircle(input);

      if (!mounted) return;

      // Invalidate feeds so new circle appears immediately
      ref.invalidate(publishedExperiencesProvider);
      ref.invalidate(myExperiencesProvider);
      ref.invalidate(newInYourAreaExperiencesProvider);

      if (result.isPendingReview) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Circle Submitted for Review'),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: const Text('Understood'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.message.isNotEmpty
                        ? result.message
                        : 'Circle published successfully!',
                  ),
                ),
              ],
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesWithIdsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassBackButton(
            isDark: isDark,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Create a Circle',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.darkSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cold-Start Fairness & Guidance Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.diversity_3_rounded,
                          color: AppColors.primaryPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fair Local Hosting',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.darkSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Anyone can host! New hosts start with intimate circles (up to 10 people) to foster genuine conversations.',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Activity Title
                Text(
                  'Circle Title',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkSurface,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _titleController,
                  hintText: 'e.g. Sunset Photography Walk at Victoria Memorial',
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                const SizedBox(height: 20),

                // Category Selection
                Text(
                  'Category',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkSurface,
                  ),
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => const Text('Failed to load categories'),
                  data: (cats) {
                    if (_selectedCategoryId == null && cats.isNotEmpty) {
                      _selectedCategoryId = cats.first.id;
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: cats.map((c) {
                          final isSelected = _selectedCategoryId == c.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('${c.icon} ${c.name}'),
                              selected: isSelected,
                              selectedColor: AppColors.primaryPurple,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : AppColors.darkSurface),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              backgroundColor: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _selectedCategoryId = c.id);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  'What will you do together?',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkSurface,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _descController,
                  hintText:
                      'Describe the vibe, plan, and what participants should expect or bring...',
                  maxLines: 4,
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
                const SizedBox(height: 20),

                // Date & Time
                Text(
                  'Date & Time',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: AppColors.primaryPurple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: AppColors.primaryPurple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime.format(context),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Duration
                Text(
                  'Duration: $_durationMinutes minutes',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkSurface,
                  ),
                ),
                Slider(
                  value: _durationMinutes.toDouble(),
                  min: 30,
                  max: 240,
                  divisions: 7,
                  activeColor: AppColors.primaryPurple,
                  label: '$_durationMinutes min',
                  onChanged: (val) =>
                      setState(() => _durationMinutes = val.round()),
                ),
                const SizedBox(height: 10),

                // Location / Venue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location & Venue',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Online Circle',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white70
                                : AppColors.mutedText,
                          ),
                        ),
                        Switch(
                          value: _isOnline,
                          activeColor: AppColors.primaryPurple,
                          onChanged: (val) => setState(() => _isOnline = val),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _cityController,
                        hintText: 'City (e.g. Kolkata)',
                        prefixIcon: const Icon(Icons.location_city_rounded),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        controller: _areaController,
                        hintText: 'Area / Neighborhood',
                        prefixIcon: const Icon(Icons.map_rounded),
                      ),
                    ),
                  ],
                ),
                if (!_isOnline) ...[
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _venueNameController,
                    hintText:
                        'Meeting Point (e.g. South Gate, Victoria Memorial)',
                    prefixIcon: const Icon(Icons.place_rounded),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _venueAddressController,
                    hintText: 'Landmark or Address details',
                    prefixIcon: const Icon(Icons.near_me_rounded),
                  ),
                ],
                const SizedBox(height: 20),

                // Max Participants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity: $_maxParticipants members',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkSurface,
                      ),
                    ),
                    Text(
                      '(Max 10 for new hosts)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _maxParticipants.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  activeColor: AppColors.primaryPurple,
                  label: '$_maxParticipants people',
                  onChanged: (val) =>
                      setState(() => _maxParticipants = val.round()),
                ),
                const SizedBox(height: 10),

                // Recurring Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Recurring Circle',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkSurface,
                      ),
                    ),
                    Switch(
                      value: _isRecurring,
                      activeColor: AppColors.primaryPurple,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Free vs Paid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Free Activity',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkSurface,
                      ),
                    ),
                    Switch(
                      value: _isFree,
                      activeColor: AppColors.primaryPurple,
                      onChanged: (val) => setState(() => _isFree = val),
                    ),
                  ],
                ),
                if (!_isFree) ...[
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _priceController,
                    hintText: 'Fee per person (INR) — e.g. entry ticket share',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 32),

                // Submit Button
                PrimaryButton(
                  label: 'Publish Circle',
                  isLoading: _isSubmitting,
                  onPressed: _handleCreate,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
