import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// AppFallbackAssets
///
/// Centralized registry of high-fidelity local fallback assets for experiences,
/// activities, and user profile avatars to guarantee that broken image icons
/// or empty boxes never appear anywhere in the app.
class AppFallbackAssets {
  static const String defaultExperienceCover =
      'assets/images/live_meetup_cafe_bg.png';
  static const String defaultProfileAvatar = 'assets/images/sneha_avatar.png';
  static const String sportsCover = 'assets/images/badminton_court_play.png';
  static const String outdoorsCover = 'assets/images/hikers_mountain_trek.png';
  static const String coffeeCover = 'assets/images/coffee_latte_art.png';
  static const String foodCover = 'assets/images/sourdough_bread_art.png';
  static const String wellnessCover = 'assets/images/morning_yoga_zen.png';
  static const String musicCultureCover =
      'assets/images/concert_party_crowd.png';

  static const List<String> avatarPool = [
    'assets/images/sneha_avatar.png',
    'assets/images/rohan_avatar.png',
    'assets/images/aditi_avatar.png',
    'assets/images/priya_avatar.png',
    'assets/images/vikram_avatar.png',
  ];

  /// Resolves the optimal default cover asset based on category name or activity title
  static String getCategoryCover(String? categoryOrTitle) {
    if (categoryOrTitle == null || categoryOrTitle.trim().isEmpty) {
      return defaultExperienceCover;
    }
    final lower = categoryOrTitle.toLowerCase();

    // 1. High-specificity activity themes: Meditation & Wellness
    if (lower.contains('well') ||
        lower.contains('yoga') ||
        lower.contains('zen') ||
        lower.contains('mindful') ||
        lower.contains('meditat') ||
        lower.contains('sound bath')) {
      return wellnessCover;
    }

    // 2. High-specificity: Photography & Scenic Walks
    if (lower.contains('photo') ||
        lower.contains('camera') ||
        lower.contains('sunset') ||
        lower.contains('scenic')) {
      return 'assets/images/splash_scenic_backdrop.png';
    }

    // 3. High-specificity: Outdoors & Nature
    if (lower.contains('outdoor') ||
        lower.contains('trek') ||
        lower.contains('hike') ||
        lower.contains('camp') ||
        lower.contains('mountain') ||
        lower.contains('nature')) {
      return outdoorsCover;
    }

    // 4. Sports & Fitness
    if (lower.contains('sport') ||
        lower.contains('cycl') ||
        lower.contains('bike') ||
        lower.contains('ride') ||
        lower.contains('badminton') ||
        lower.contains('run') ||
        lower.contains('fitness') ||
        lower.contains('gym')) {
      return sportsCover;
    }

    // 5. Food & Baking
    if (lower.contains('food') ||
        lower.contains('baking') ||
        lower.contains('bake') ||
        lower.contains('cook') ||
        lower.contains('culinary') ||
        lower.contains('dine') ||
        lower.contains('dinner') ||
        lower.contains('sourdough')) {
      return foodCover;
    }

    // 6. Coffee, Cafes & Tasting
    if (lower.contains('coffee') ||
        lower.contains('cafe') ||
        lower.contains('tea') ||
        lower.contains('latte') ||
        lower.contains('roaster') ||
        lower.contains('tasting')) {
      return coffeeCover;
    }

    // 7. Art & Music
    if (lower.contains('art') ||
        lower.contains('music') ||
        lower.contains('concert') ||
        lower.contains('jam') ||
        lower.contains('culture') ||
        lower.contains('acoustic') ||
        lower.contains('open mic')) {
      return musicCultureCover;
    }

    // 8. General social / reading
    if (lower.contains('social') ||
        lower.contains('chat') ||
        lower.contains('book')) {
      return coffeeCover;
    }

    return defaultExperienceCover;
  }

  /// Resolves a deterministic or named default profile avatar
  static String getAvatar([String? nameHint]) {
    if (nameHint == null || nameHint.trim().isEmpty) {
      return defaultProfileAvatar;
    }
    final lower = nameHint.toLowerCase();
    if (lower.contains('rohan')) return 'assets/images/rohan_avatar.png';
    if (lower.contains('aditi')) return 'assets/images/aditi_avatar.png';
    if (lower.contains('priya')) return 'assets/images/priya_avatar.png';
    if (lower.contains('vikram')) return 'assets/images/vikram_avatar.png';
    if (lower.contains('sneha')) return 'assets/images/sneha_avatar.png';

    final index = nameHint.hashCode.abs() % avatarPool.length;
    return avatarPool[index];
  }
}

/// AppSmartImage
///
/// Intelligently renders local assets, device files, or remote network images with
/// smooth caching and an automatic, graceful local image fallback system so that
/// missing or broken images seamlessly show a themed default illustration/photo.
class AppSmartImage extends StatelessWidget {
  final String? imagePath;
  final bool isAvatar;
  final String? fallbackAsset;
  final String? categoryHint;
  final String? nameHint;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppSmartImage({
    super.key,
    this.imagePath,
    this.isAvatar = false,
    this.fallbackAsset,
    this.categoryHint,
    this.nameHint,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  String _resolveEffectiveFallback() {
    if (fallbackAsset != null && fallbackAsset!.trim().isNotEmpty) {
      return fallbackAsset!;
    }
    if (isAvatar) {
      return AppFallbackAssets.getAvatar(nameHint);
    }
    return AppFallbackAssets.getCategoryCover(categoryHint);
  }

  Widget _buildFallback(String fallbackAssetPath) {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Image.asset(
      fallbackAssetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: const Color(0xFF6E32EC).withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Icon(
          isAvatar ? Icons.person_rounded : Icons.image_rounded,
          color: const Color(0xFF6E32EC),
          size: (width != null && height != null)
              ? (width! < height! ? width! * 0.45 : height! * 0.45).clamp(
                  16.0,
                  48.0,
                )
              : 24.0,
        ),
      ),
    );
  }

  bool _isLocalFilePath(String path) {
    if (kIsWeb) return false;
    return path.startsWith('/') ||
        path.contains(':\\') ||
        path.contains(':/') ||
        path.startsWith('file:');
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFallback = _resolveEffectiveFallback();

    final fallbackPlaceholder =
        placeholder ??
        Container(width: width, height: height, color: const Color(0xFFF3EDF8));

    Widget content;
    final path = imagePath?.trim();

    if (path == null || path.isEmpty) {
      content = _buildFallback(effectiveFallback);
    } else if (path.startsWith('assets/')) {
      content = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallback(effectiveFallback),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => fallbackPlaceholder,
        errorWidget: (context, url, error) => _buildFallback(effectiveFallback),
      );
    } else if (_isLocalFilePath(path)) {
      final cleanPath = path.startsWith('file://')
          ? path.replaceFirst('file://', '')
          : path;
      final file = File(cleanPath);
      if (file.existsSync()) {
        content = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallback(effectiveFallback),
        );
      } else {
        content = _buildFallback(effectiveFallback);
      }
    } else {
      content = _buildFallback(effectiveFallback);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }
}
