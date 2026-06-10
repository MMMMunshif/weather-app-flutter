import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedLocationData {
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  const SavedLocationData({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  String get id {
    return '${city}_${country}'.toLowerCase().replaceAll(' ', '_');
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory SavedLocationData.fromMap(Map<String, dynamic> map) {
    return SavedLocationData(
      city: (map['city'] ?? '').toString(),
      country: (map['country'] ?? '').toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SavedLocationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _savedLocationsRef() {
    final user = _auth.currentUser;

    if (user == null) return null;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedLocations');
  }

  Future<List<SavedLocationData>> getSavedLocations() async {
    final ref = _savedLocationsRef();

    if (ref == null) return [];

    final snapshot = await ref.orderBy('createdAt', descending: false).get();

    return snapshot.docs.map((doc) {
      return SavedLocationData.fromMap(doc.data());
    }).toList();
  }

  Future<void> addSavedLocation({
    required String city,
    required String country,
    required double latitude,
    required double longitude,
  }) async {
    final ref = _savedLocationsRef();

    if (ref == null) {
      throw Exception('Please login first.');
    }

    final location = SavedLocationData(
      city: city,
      country: country,
      latitude: latitude,
      longitude: longitude,
    );

    await ref.doc(location.id).set(
      location.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> removeSavedLocation({
    required String city,
    required String country,
  }) async {
    final ref = _savedLocationsRef();

    if (ref == null) return;

    final id = '${city}_${country}'.toLowerCase().replaceAll(' ', '_');

    await ref.doc(id).delete();
  }
}