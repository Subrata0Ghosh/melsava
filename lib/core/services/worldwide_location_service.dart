import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  String get shortLabel => city.isNotEmpty ? '$city, $country' : '$name, $country';

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
  final String category; // 'cafe', 'restaurant', 'board_games', 'park', 'culture'
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

  WorldwideLocationService({http.Client? client}) : _client = client ?? http.Client();

  /// Curated top world cities for instant zero-latency suggestions
  static const List<WorldLocation> featuredWorldCities = [
    WorldLocation(name: 'Mumbai', city: 'Mumbai', country: 'India', countryCode: 'IN', lat: 19.0760, lon: 72.8777),
    WorldLocation(name: 'Tokyo', city: 'Tokyo', country: 'Japan', countryCode: 'JP', lat: 35.6762, lon: 139.6503),
    WorldLocation(name: 'London', city: 'London', country: 'United Kingdom', countryCode: 'GB', lat: 51.5074, lon: -0.1278),
    WorldLocation(name: 'New York', city: 'New York', country: 'United States', countryCode: 'US', lat: 40.7128, lon: -74.0060),
    WorldLocation(name: 'Paris', city: 'Paris', country: 'France', countryCode: 'FR', lat: 48.8566, lon: 2.3522),
    WorldLocation(name: 'Berlin', city: 'Berlin', country: 'Germany', countryCode: 'DE', lat: 52.5200, lon: 13.4050),
    WorldLocation(name: 'Singapore', city: 'Singapore', country: 'Singapore', countryCode: 'SG', lat: 1.3521, lon: 103.8198),
    WorldLocation(name: 'Sydney', city: 'Sydney', country: 'Australia', countryCode: 'AU', lat: -33.8688, lon: 151.2093),
    WorldLocation(name: 'Bengaluru', city: 'Bengaluru', country: 'India', countryCode: 'IN', lat: 12.9716, lon: 77.5946),
    WorldLocation(name: 'Delhi NCR', city: 'New Delhi', country: 'India', countryCode: 'IN', lat: 28.6139, lon: 77.2090),
    WorldLocation(name: 'Toronto', city: 'Toronto', country: 'Canada', countryCode: 'CA', lat: 43.6532, lon: -79.3832),
    WorldLocation(name: 'Dubai', city: 'Dubai', country: 'UAE', countryCode: 'AE', lat: 25.2048, lon: 55.2708),
    WorldLocation(name: 'San Francisco', city: 'San Francisco', country: 'United States', countryCode: 'US', lat: 37.7749, lon: -122.4194),
    WorldLocation(name: 'Seoul', city: 'Seoul', country: 'South Korea', countryCode: 'KR', lat: 37.5665, lon: 126.9780),
    WorldLocation(name: 'Amsterdam', city: 'Amsterdam', country: 'Netherlands', countryCode: 'NL', lat: 52.3676, lon: 4.9041),
  ];

  /// Search any city, neighborhood, or area in the world with live OpenStreetMap/Photon
  Future<List<WorldLocation>> searchCities(String query) async {
    if (query.trim().isEmpty) return featuredWorldCities;

    final trimmed = query.trim().toLowerCase();

    // 1. Check local match first for instant result
    final localMatches = featuredWorldCities
        .where((loc) =>
            loc.name.toLowerCase().contains(trimmed) ||
            loc.city.toLowerCase().contains(trimmed) ||
            loc.country.toLowerCase().contains(trimmed))
        .toList();

    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&osm_tag=place:city&osm_tag=place:town&limit=8',
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        final results = <WorldLocation>[];
        for (final item in features) {
          final props = item['properties'] as Map<String, dynamic>? ?? {};
          final coords = (item['geometry']?['coordinates'] as List<dynamic>?) ?? [0.0, 0.0];

          final name = props['name'] as String? ?? '';
          final city = props['city'] as String? ?? name;
          final country = props['country'] as String? ?? '';
          final countryCode = props['countrycode'] as String? ?? '';

          if (name.isNotEmpty && country.isNotEmpty) {
            results.add(WorldLocation(
              name: name,
              city: city,
              country: country,
              countryCode: countryCode.toUpperCase(),
              lon: (coords[0] as num).toDouble(),
              lat: (coords[1] as num).toDouble(),
            ));
          }
        }

        if (results.isNotEmpty) return results;
      }
    } catch (e) {
      debugPrint('Photon city search failed, fallback to local: $e');
    }

    return localMatches.isNotEmpty ? localMatches : featuredWorldCities;
  }

  /// Search real cafes, restaurants, lounges, and meetup spaces in a chosen city
  Future<List<MeetupVenue>> searchVenues({
    required String query,
    required WorldLocation location,
    String? categoryFilter,
  }) async {
    final searchTerms = query.trim().isNotEmpty
        ? '${query.trim()} ${location.city}'
        : '${categoryFilter ?? 'cafe'} ${location.city}';

    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(searchTerms)}&limit=10',
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        final venues = <MeetupVenue>[];
        for (final item in features) {
          final props = item['properties'] as Map<String, dynamic>? ?? {};
          final coords = (item['geometry']?['coordinates'] as List<dynamic>?) ?? [0.0, 0.0];

          final name = props['name'] as String? ?? '';
          final street = props['street'] as String? ?? '';
          final osmVal = (props['osm_value'] as String? ?? 'cafe').toLowerCase();

          if (name.isNotEmpty) {
            venues.add(MeetupVenue(
              name: name,
              category: _mapOsmToCategory(osmVal),
              address: street.isNotEmpty ? '$street, ${location.city}' : location.city,
              city: location.city,
              country: location.country,
              lon: (coords[0] as num).toDouble(),
              lat: (coords[1] as num).toDouble(),
            ));
          }
        }

        if (venues.isNotEmpty) return venues;
      }
    } catch (e) {
      debugPrint('Photon venue search failed, returning curated venues: $e');
    }

    return _getCuratedFallbackVenues(location, categoryFilter);
  }

  String _mapOsmToCategory(String osm) {
    if (osm.contains('restaurant') || osm.contains('food') || osm.contains('bistro')) {
      return 'restaurant';
    } else if (osm.contains('park') || osm.contains('garden')) {
      return 'park';
    } else if (osm.contains('museum') || osm.contains('gallery') || osm.contains('theatre')) {
      return 'culture';
    } else if (osm.contains('bar') || osm.contains('pub')) {
      return 'lounge';
    }
    return 'cafe';
  }

  List<MeetupVenue> _getCuratedFallbackVenues(WorldLocation location, String? category) {
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
