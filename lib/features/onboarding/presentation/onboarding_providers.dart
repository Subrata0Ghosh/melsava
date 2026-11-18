import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_models.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return SupabaseOnboardingRepository(authRepo);
});

final onboardingReferenceDataProvider = FutureProvider<OnboardingReferenceData>(
  (ref) {
    final repo = ref.watch(onboardingRepositoryProvider);
    return repo.fetchReferenceOptions();
  },
);
