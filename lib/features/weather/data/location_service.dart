import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class CurrentPlace {
  final double latitude;
  final double longitude;
  final String city;
  final String country;

  CurrentPlace({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
  });
}

class LocationService {
  Future<CurrentPlace> getCurrentPlace() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location service is disabled. Please enable location.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable it from settings.',
      );
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placeData = await _getPlaceName(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return CurrentPlace(
      latitude: position.latitude,
      longitude: position.longitude,
      city: placeData['city'] ?? 'Current Location',
      country: placeData['country'] ?? '',
    );
  }

  Future<Map<String, String>> _getPlaceName({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.bigdatacloud.net',
      '/data/reverse-geocode-client',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'localityLanguage': 'en',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return {
        'city': 'Current Location',
        'country': '',
      };
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final String city = (data['city'] ??
        data['locality'] ??
        data['principalSubdivision'] ??
        'Current Location')
        .toString();

    final String country = (data['countryName'] ?? '').toString();

    return {
      'city': city,
      'country': country,
    };
  }
}