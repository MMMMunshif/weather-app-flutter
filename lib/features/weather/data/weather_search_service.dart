import 'dart:convert';

import 'package:http/http.dart' as http;

class SearchPlace {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final bool isCountry;

  const SearchPlace({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.isCountry,
  });

  String get displayName {
    if (country.isEmpty) return name;
    return '$name, $country';
  }
}

class WeatherSearchService {
  Future<List<SearchPlace>> searchPlaces(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.length < 2) {
      return [];
    }

    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': cleanQuery,
        'count': '15',
        'language': 'en',
        'format': 'json',
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Location search failed. Please try again.');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List results = decoded['results'] as List? ?? [];

      final places = results.map((item) {
        final map = Map<String, dynamic>.from(item as Map);

        final name = (map['name'] ?? '').toString();
        final country = (map['country'] ?? '').toString();
        final latitude = (map['latitude'] as num?)?.toDouble() ?? 0.0;
        final longitude = (map['longitude'] as num?)?.toDouble() ?? 0.0;
        final featureCode = (map['feature_code'] ?? '').toString();

        return SearchPlace(
          name: name,
          country: country,
          latitude: latitude,
          longitude: longitude,
          isCountry: featureCode.startsWith('PCLI'),
        );
      }).where((place) {
        return place.name.isNotEmpty &&
            place.latitude != 0.0 &&
            place.longitude != 0.0;
      }).toList();

      return places;
    } catch (_) {
      throw Exception(
        'Unable to search location. Please check your internet connection.',
      );
    }
  }
}