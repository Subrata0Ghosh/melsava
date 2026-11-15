import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'worldwide_location_service.dart';

final worldwideLocationServiceProvider = Provider<WorldwideLocationService>((ref) {
  return WorldwideLocationService();
});

class UserLocationNotifier extends StateNotifier<WorldLocation> {
  final WorldwideLocationService _service;

  UserLocationNotifier(this._service) : super(WorldLocation.defaultLocation) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _service.getSavedUserLocation();
    state = saved;
  }

  Future<void> setLocation(WorldLocation location) async {
    state = location;
    await _service.saveUserLocation(location);
  }
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, WorldLocation>((ref) {
  final service = ref.watch(worldwideLocationServiceProvider);
  return UserLocationNotifier(service);
});
