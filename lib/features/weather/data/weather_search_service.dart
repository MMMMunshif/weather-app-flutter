import 'dart:convert';

import 'package:http/http.dart' as http;

class SearchPlace {
  final String name;
  final String country;
  final String adminArea;
  final double latitude;
  final double longitude;
  final bool isCountry;

  SearchPlace({
    required this.name,
    required this.country,
    required this.adminArea,
    required this.latitude,
    required this.longitude,
    this.isCountry = false,
  });

  String get displayName {
    if (isCountry) {
      return '$country - Capital: $name';
    }

    if (adminArea.isEmpty) {
      return '$name, $country';
    }

    return '$name, $adminArea, $country';
  }
}

class WeatherSearchService {
  Future<List<SearchPlace>> searchPlaces(String query) async {
    final searchText = query.trim();

    if (searchText.length < 2) {
      return [];
    }

    final cityResults = await _searchCities(searchText);
    final countryResults = await _searchCountries(searchText);

    final allResults = [
      ...cityResults,
      ...countryResults,
    ];

    final uniqueResults = <String, SearchPlace>{};

    for (final place in allResults) {
      final key =
          '${place.name}-${place.country}-${place.latitude}-${place.longitude}';

      uniqueResults[key] = place;
    }

    return uniqueResults.values.toList();
  }

  Future<List<SearchPlace>> _searchCities(String query) async {
    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': query,
        'count': '30',
        'language': 'en',
        'format': 'json',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List results = data['results'] as List? ?? [];

    return results.map((item) {
      final map = item as Map<String, dynamic>;

      return SearchPlace(
        name: (map['name'] ?? '').toString(),
        country: (map['country'] ?? '').toString(),
        adminArea: (map['admin1'] ?? '').toString(),
        latitude: _toDouble(map['latitude']),
        longitude: _toDouble(map['longitude']),
      );
    }).where((place) {
      return place.name.isNotEmpty &&
          place.country.isNotEmpty &&
          place.latitude != 0 &&
          place.longitude != 0;
    }).toList();
  }

  Future<List<SearchPlace>> _searchCountries(String query) async {
    final uri = Uri.parse(
      'https://restcountries.com/v3.1/name/${Uri.encodeComponent(query)}?fields=name,capital,latlng,region',
    );

    final response = await http.get(uri);

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      return [];
    }

    final List data = jsonDecode(response.body) as List;

    return data.map((item) {
      final map = item as Map<String, dynamic>;

      final nameMap = map['name'] as Map<String, dynamic>? ?? {};
      final countryName = (nameMap['common'] ?? '').toString();

      final capitalList = map['capital'] as List? ?? [];
      final capitalName = capitalList.isNotEmpty
          ? capitalList.first.toString()
          : countryName;

      final latlng = map['latlng'] as List? ?? [];
      final latitude = latlng.isNotEmpty ? _toDouble(latlng[0]) : 0.0;
      final longitude = latlng.length > 1 ? _toDouble(latlng[1]) : 0.0;

      return SearchPlace(
        name: capitalName,
        country: countryName,
        adminArea: 'Country',
        latitude: latitude,
        longitude: longitude,
        isCountry: true,
      );
    }).where((place) {
      return place.country.isNotEmpty &&
          place.latitude != 0 &&
          place.longitude != 0;
    }).toList();
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}