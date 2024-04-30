import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DocumentSnapshot>> loadMarkers() async {
    var snapshot = await _db.collection('trash_bins').get();
    return snapshot.docs;
  }

  Future<void> addTrashBinLocation(LatLng position, String description) async {
    await _db.collection('trash_bins').add({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
