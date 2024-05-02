import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class MarkerService {
  Future<Set<Marker>> getMarkers(
      List<DocumentSnapshot> docs, BitmapDescriptor icon) async {
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        double latitude = data['latitude'] as double;
        double longitude = data['longitude'] as double;
        String description = data['description'] as String;

        LatLng position = LatLng(latitude, longitude);
        double distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          latitude,
          longitude,
        );
        String formattedDistance = _formatDistance(distance);

        return Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: InfoWindow(
              title: description,
              snippet: '現在地から$formattedDistance'),
          icon: icon,
        );
      } else {
        LatLng position = const LatLng(0.0, 0.0);
        return Marker(
          markerId: const MarkerId('default'),
          position: position,
          infoWindow:
              const InfoWindow(title: 'Undefined', snippet: 'No data available'),
          icon: icon,
        );
      }
    }).toSet();
  }

  String _formatDistance(double distance) {
    return distance < 500
        ? '${distance.toStringAsFixed(0)} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';
  }
}
