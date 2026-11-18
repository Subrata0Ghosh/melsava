import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a city, district, or neighborhood anywhere in the world.
class WorldLocation {
  final String name;
  final String city;
  final String country;
  final String countryCode;
  final double lat;
  final double lon;

  const WorldLocation({
    required this.name,
    required this.city,
    required this.country,
    this.countryCode = '',
    this.lat = 0.0,
    this.lon = 0.0,
  });

  String get displayName => city.isNotEmpty && city != name
      ? '$name, $city, $country'
      : '$name, $country';

  String get shortLabel =>
      city.isNotEmpty ? '$city, $country' : '$name, $country';

  Map<String, dynamic> toJson() => {
    'name': name,
    'city': city,
    'country': country,
    'countryCode': countryCode,
    'lat': lat,
    'lon': lon,
  };

  factory WorldLocation.fromJson(Map<String, dynamic> json) => WorldLocation(
    name: json['name'] as String? ?? 'Global',
    city: json['city'] as String? ?? 'Mumbai',
    country: json['country'] as String? ?? 'India',
    countryCode: json['countryCode'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
    lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
  );

  static const WorldLocation defaultLocation = WorldLocation(
    name: 'Mumbai',
    city: 'Mumbai',
    country: 'India',
    countryCode: 'IN',
    lat: 19.0760,
    lon: 72.8777,
  );
}

/// Represents a specific meetup spot (cafe, restaurant, board game hub, park, etc.)
class MeetupVenue {
  final String name;
  final String
  category; // 'cafe', 'restaurant', 'board_games', 'park', 'culture'
  final String address;
  final String city;
  final String country;
  final double lat;
  final double lon;

  const MeetupVenue({
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.country,
    this.lat = 0.0,
    this.lon = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'address': address,
    'city': city,
    'country': country,
    'lat': lat,
    'lon': lon,
  };

  factory MeetupVenue.fromJson(Map<String, dynamic> json) => MeetupVenue(
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? 'cafe',
    address: json['address'] as String? ?? '',
    city: json['city'] as String? ?? '',
    country: json['country'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
    lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Worldwide Location & Venue Service using free Photon (OpenStreetMap) API
/// with instant offline fallback catalog.
class WorldwideLocationService {
  static final WorldwideLocationService instance = WorldwideLocationService();
  static const String _savedLocationKey = 'melsava_selected_world_location';

  final http.Client _client;

  WorldwideLocationService({http.Client? client})
    : _client = client ?? http.Client();

  /// Curated top world cities for instant zero-latency suggestions
  static const List<WorldLocation> featuredWorldCities = [
    WorldLocation(
      name: 'Mumbai',
      city: 'Mumbai',
      country: 'India',
      countryCode: 'IN',
      lat: 19.0760,
      lon: 72.8777,
    ),
    WorldLocation(
      name: 'Tokyo',
      city: 'Tokyo',
      country: 'Japan',
      countryCode: 'JP',
      lat: 35.6762,
      lon: 139.6503,
    ),
    WorldLocation(
      name: 'London',
      city: 'London',
      country: 'United Kingdom',
      countryCode: 'GB',
      lat: 51.5074,
      lon: -0.1278,
    ),
    WorldLocation(
      name: 'New York',
      city: 'New York',
      country: 'United States',
      countryCode: 'US',
      lat: 40.7128,
      lon: -74.0060,
    ),
    WorldLocation(
      name: 'Paris',
      city: 'Paris',
      country: 'France',
      countryCode: 'FR',
      lat: 48.8566,
      lon: 2.3522,
    ),
    WorldLocation(
      name: 'Berlin',
      city: 'Berlin',
      country: 'Germany',
      countryCode: 'DE',
      lat: 52.5200,
      lon: 13.4050,
    ),
    WorldLocation(
      name: 'Singapore',
      city: 'Singapore',
      country: 'Singapore',
      countryCode: 'SG',
      lat: 1.3521,
      lon: 103.8198,
    ),
    WorldLocation(
      name: 'Sydney',
      city: 'Sydney',
      country: 'Australia',
      countryCode: 'AU',
      lat: -33.8688,
      lon: 151.2093,
    ),
    WorldLocation(
      name: 'Bengaluru',
      city: 'Bengaluru',
      country: 'India',
      countryCode: 'IN',
      lat: 12.9716,
      lon: 77.5946,
    ),
    WorldLocation(
      name: 'Delhi NCR',
      city: 'New Delhi',
      country: 'India',
      countryCode: 'IN',
      lat: 28.6139,
      lon: 77.2090,
    ),
    WorldLocation(
      name: 'Toronto',
      city: 'Toronto',
      country: 'Canada',
      countryCode: 'CA',
      lat: 43.6532,
      lon: -79.3832,
    ),
    WorldLocation(
      name: 'Dubai',
      city: 'Dubai',
      country: 'UAE',
      countryCode: 'AE',
      lat: 25.2048,
      lon: 55.2708,
    ),
    WorldLocation(
      name: 'San Francisco',
      city: 'San Francisco',
      country: 'United States',
      countryCode: 'US',
      lat: 37.7749,
      lon: -122.4194,
    ),
    WorldLocation(
      name: 'Seoul',
      city: 'Seoul',
      country: 'South Korea',
      countryCode: 'KR',
      lat: 37.5665,
      lon: 126.9780,
    ),
    WorldLocation(
      name: 'Amsterdam',
      city: 'Amsterdam',
      country: 'Netherlands',
      countryCode: 'NL',
      lat: 52.3676,
      lon: 4.9041,
    ),
  ];

  /// Request user GPS permission and fetch actual device coordinates & location
  Future<WorldLocation?> getCurrentGpsLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return await reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Device GPS location error: $e');
      return null;
    }
  }

  /// Reverse geocode GPS coordinates to city, district, and country
  /// (Zero sign-in, zero keys — uses BigDataCloud Client API with OSM Nominatim fallback)
  Future<WorldLocation> reverseGeocode(double lat, double lon) async {
    // 1. Try BigDataCloud free client reverse geocoder
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final locality = data['locality'] as String? ?? '';
        final city = (data['city'] as String?)?.isNotEmpty == true
            ? data['city'] as String
            : ((data['principalSubdivision'] as String?) ?? locality);
        final country = data['countryName'] as String? ?? 'Global';
        final countryCode = data['countryCode'] as String? ?? '';

        final name = locality.isNotEmpty
            ? locality
            : (city.isNotEmpty ? city : 'My Area');
        return WorldLocation(
          name: name,
          city: city.isNotEmpty ? city : name,
          country: country,
          countryCode: countryCode.toUpperCase(),
          lat: lat,
          lon: lon,
        );
      }
    } catch (e) {
      debugPrint('BigDataCloud reverse geocode error: $e');
    }

    // 2. Fallback to OpenStreetMap Nominatim
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1',
      );
      final res = await _client
          .get(
            uri,
            headers: {'User-Agent': 'MelsavaApp/1.0 (dating.experience.app)'},
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final placeName =
            addr['suburb'] ??
            addr['neighbourhood'] ??
            addr['village'] ??
            addr['town'] ??
            addr['city'] ??
            'My Area';
        final city =
            addr['city'] ?? addr['town'] ?? addr['county'] ?? placeName;
        final country = addr['country'] as String? ?? '';
        final countryCode = addr['country_code'] as String? ?? '';

        return WorldLocation(
          name: placeName.toString(),
          city: city.toString(),
          country: country,
          countryCode: countryCode.toUpperCase(),
          lat: lat,
          lon: lon,
        );
      }
    } catch (e) {
      debugPrint('Nominatim reverse geocode error: $e');
    }

    return WorldLocation(
      name: 'Local Area',
      city: 'Local Area',
      country: '',
      lat: lat,
      lon: lon,
    );
  }

  /// Search ANY city, town, village, neighborhood, district, or local area worldwide.
  /// (Zero limitations — supports any small town or region globally)
  Future<List<WorldLocation>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return featuredWorldCities;

    final results = <WorldLocation>[];
    final seen = <String>{};

    // Prepare search token variants (handles "kalyani,westbangal,nadia", commas, typos)
    final clean = trimmed
        .replaceAll(RegExp(r'[,;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = clean.split(' ');
    final queriesToTry = <String>[trimmed];
    if (clean != trimmed) queriesToTry.add(clean);
    if (words.length > 1) {
      queriesToTry.add(words[0]); // first token like 'kalyani'
      queriesToTry.add('${words[0]} ${words.last}'); // 'kalyani nadia'
    }

    // Tier 1: OpenStreetMap Nominatim (Official global address, district, village, and town search)
    for (final q in queriesToTry) {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&addressdetails=1&limit=10',
        );
        final res = await _client
            .get(
              uri,
              headers: {'User-Agent': 'MelsavaApp/1.0 (dating.experience.app)'},
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final items =
              jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>? ?? [];
          for (final item in items) {
            final addr = item['address'] as Map<String, dynamic>? ?? {};
            final displayName = item['display_name'] as String? ?? '';
            final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
            final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;

            final placeName =
                addr['city'] ??
                addr['town'] ??
                addr['village'] ??
                addr['suburb'] ??
                addr['municipality'] ??
                addr['county'] ??
                displayName.split(',').first.trim();

            final state =
                addr['state'] as String? ?? addr['county'] as String? ?? '';
            final country = addr['country'] as String? ?? '';
            final countryCode = addr['country_code'] as String? ?? '';

            final key = '$placeName-$state-$country'.toLowerCase();
            if (!seen.contains(key) && lat != 0.0 && lon != 0.0) {
              seen.add(key);
              results.add(
                WorldLocation(
                  name: placeName.toString(),
                  city: state.isNotEmpty
                      ? '$placeName, $state'
                      : placeName.toString(),
                  country: country,
                  countryCode: countryCode.toUpperCase(),
                  lat: lat,
                  lon: lon,
                ),
              );
            }
          }
        }
        if (results.isNotEmpty) break;
      } catch (e) {
        debugPrint('Nominatim search failed for $q: $e');
      }
    }

    // Tier 2: Photon Worldwide API (Unfiltered — matches any place/amenity/town)
    if (results.isEmpty) {
      for (final q in queriesToTry) {
        try {
          final uri = Uri.parse(
            'https://photon.komoot.io/api/?q=${Uri.encodeComponent(q)}&limit=10',
          );
          final res = await _client
              .get(uri)
              .timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data =
                jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
            final features = data['features'] as List<dynamic>? ?? [];
            for (final item in features) {
              final props = item['properties'] as Map<String, dynamic>? ?? {};
              final coords =
                  (item['geometry']?['coordinates'] as List<dynamic>?) ??
                  [0.0, 0.0];
              final name = props['name'] as String? ?? '';
              final state =
                  props['state'] as String? ??
                  props['district'] as String? ??
                  '';
              final country = props['country'] as String? ?? '';
              final countryCode = props['countrycode'] as String? ?? '';

              final key = '$name-$state-$country'.toLowerCase();
              if (name.isNotEmpty && !seen.contains(key)) {
                seen.add(key);
                results.add(
                  WorldLocation(
                    name: name,
                    city: state.isNotEmpty ? '$name, $state' : name,
                    country: country,
                    countryCode: countryCode.toUpperCase(),
                    lon: (coords[0] as num).toDouble(),
                    lat: (coords[1] as num).toDouble(),
                  ),
                );
              }
            }
          }
          if (results.isNotEmpty) break;
        } catch (e) {
          debugPrint('Photon search failed for $q: $e');
        }
      }
    }

    // Tier 3: Local fuzzy matches
    if (results.isEmpty) {
      final lower = trimmed.toLowerCase();
      final localMatches = featuredWorldCities
          .where(
            (loc) =>
                loc.name.toLowerCase().contains(lower) ||
                loc.city.toLowerCase().contains(lower) ||
                loc.country.toLowerCase().contains(lower),
          )
          .toList();
      return localMatches;
    }

    return results;
  }

  /// Search real cafes, restaurants, lounges, shops, and stores in any chosen city or town
  Future<List<MeetupVenue>> searchVenues({
    required String query,
    required WorldLocation location,
    String? categoryFilter,
  }) async {
    final trimmedQuery = query.trim();
    final venues = <MeetupVenue>[];
    final seen = <String>{};

    final baseLat = location.lat != 0.0 ? location.lat : 19.0760;
    final baseLon = location.lon != 0.0 ? location.lon : 72.8777;

    // Build search term
    final searchTerm = trimmedQuery.isNotEmpty
        ? trimmedQuery
        : (categoryFilter != null && categoryFilter != 'all'
              ? categoryFilter
              : 'cafe restaurant park bakery shop');

    // 1. Photon search biased around this location coordinates
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(searchTerm)}&lat=$baseLat&lon=$baseLon&limit=15',
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        for (final item in features) {
          final props = item['properties'] as Map<String, dynamic>? ?? {};
          final coords =
              (item['geometry']?['coordinates'] as List<dynamic>?) ??
              [0.0, 0.0];
          final name = props['name'] as String? ?? '';
          final street =
              props['street'] as String? ?? props['district'] as String? ?? '';
          final osmVal =
              (props['osm_value'] as String? ??
                      props['type'] as String? ??
                      'cafe')
                  .toLowerCase();

          final key = name.toLowerCase();
          if (name.isNotEmpty && !seen.contains(key)) {
            seen.add(key);
            venues.add(
              MeetupVenue(
                name: name,
                category: _mapOsmToCategory(osmVal),
                address: street.isNotEmpty
                    ? '$street, ${location.shortLabel}'
                    : location.shortLabel,
                city: location.city,
                country: location.country,
                lon: (coords[0] as num).toDouble(),
                lat: (coords[1] as num).toDouble(),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Photon venue search error: $e');
    }

    // 2. If user searched for a specific shop by name, also query Nominatim for exact matches
    if (trimmedQuery.isNotEmpty && venues.length < 3) {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent('$trimmedQuery ${location.city}')}&format=json&limit=6',
        );
        final res = await _client
            .get(
              uri,
              headers: {'User-Agent': 'MelsavaApp/1.0 (dating.experience.app)'},
            )
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final items =
              jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>? ?? [];
          for (final item in items) {
            final displayName = item['display_name'] as String? ?? '';
            final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
            final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
            final name = displayName.split(',').first.trim();
            final key = name.toLowerCase();
            if (name.isNotEmpty &&
                !seen.contains(key) &&
                lat != 0.0 &&
                lon != 0.0) {
              seen.add(key);
              venues.add(
                MeetupVenue(
                  name: name,
                  category: 'shop',
                  address: displayName,
                  city: location.city,
                  country: location.country,
                  lat: lat,
                  lon: lon,
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Nominatim shop search error: $e');
      }
    }

    if (venues.isNotEmpty) return venues;
    return _getCuratedFallbackVenues(location, categoryFilter);
  }

  String _mapOsmToCategory(String osm) {
    if (osm.contains('restaurant') ||
        osm.contains('food') ||
        osm.contains('bistro') ||
        osm.contains('bakery') ||
        osm.contains('sweet')) {
      return 'restaurant';
    } else if (osm.contains('park') ||
        osm.contains('garden') ||
        osm.contains('lake') ||
        osm.contains('ridge')) {
      return 'park';
    } else if (osm.contains('museum') ||
        osm.contains('gallery') ||
        osm.contains('theatre') ||
        osm.contains('cinema')) {
      return 'culture';
    } else if (osm.contains('bar') ||
        osm.contains('pub') ||
        osm.contains('lounge')) {
      return 'lounge';
    } else if (osm.contains('shop') ||
        osm.contains('store') ||
        osm.contains('mall') ||
        osm.contains('supermarket') ||
        osm.contains('book')) {
      return 'shop';
    }
    return 'cafe';
  }

  List<MeetupVenue> _getCuratedFallbackVenues(
    WorldLocation location,
    String? category,
  ) {
    final baseLat = (location.lat != 0.0) ? location.lat : 19.0760;
    final baseLon = (location.lon != 0.0) ? location.lon : 72.8777;
    final city = location.city;

    final venues = [
      MeetupVenue(
        name: 'Artisan Coffee Roasters',
        category: 'cafe',
        address: 'Downtown Arts Quarter, $city',
        city: city,
        country: location.country,
        lat: baseLat + 0.0035,
        lon: baseLon - 0.0042,
      ),
      MeetupVenue(
        name: 'Tabletop & Dice Game Lounge',
        category: 'board_games',
        address: 'Central Plaza 4th Floor, $city',
        city: city,
        country: location.country,
        lat: baseLat - 0.0028,
        lon: baseLon + 0.0048,
      ),
      MeetupVenue(
        name: 'The Botanical Greenhouse Bistro',
        category: 'restaurant',
        address: 'Civic Garden Way, $city',
        city: city,
        country: location.country,
        lat: baseLat + 0.0052,
        lon: baseLon + 0.0025,
      ),
      MeetupVenue(
        name: 'Heritage Bookshop & Tearoom',
        category: 'cafe',
        address: 'Old Quarter Promenade, $city',
        city: city,
        country: location.country,
        lat: baseLat - 0.0045,
        lon: baseLon - 0.0032,
      ),
      MeetupVenue(
        name: 'Riverside Walk & Sunset Trail',
        category: 'park',
        address: 'Harbor Waterfront, $city',
        city: city,
        country: location.country,
        lat: baseLat + 0.0070,
        lon: baseLon - 0.0060,
      ),
      MeetupVenue(
        name: 'Clay & Canvas Ceramic Studio',
        category: 'culture',
        address: 'Craftworks Avenue, $city',
        city: city,
        country: location.country,
        lat: baseLat - 0.0062,
        lon: baseLon + 0.0038,
      ),
    ];

    if (category != null && category.isNotEmpty && category != 'all') {
      return venues.where((v) => v.category == category).toList();
    }
    return venues;
  }

  // ── Persistence ───────────────────────────────────────────────────

  Future<void> saveUserLocation(WorldLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedLocationKey, jsonEncode(location.toJson()));
    } catch (_) {}
  }

  Future<WorldLocation> getSavedUserLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_savedLocationKey);
      if (str != null) {
        return WorldLocation.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
    } catch (_) {}
    return WorldLocation.defaultLocation;
  }
}
