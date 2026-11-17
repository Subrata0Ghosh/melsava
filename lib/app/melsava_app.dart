import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';
import 'app_theme.dart';
import 'theme_provider.dart';
import '../core/constants/app_constants.dart';

/// Global custom scroll behavior that ensures ClampingScrollPhysics across all platforms
/// preventing pull-down overscroll voids and blank gaps.
class MelsavaScrollBehavior extends MaterialScrollBehavior {
  const MelsavaScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

/// Root widget for the MELSAVA application supporting both Light and Dark themes.
class MelsavaApp extends ConsumerWidget {
  const MelsavaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MelsavaScrollBehavior(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
