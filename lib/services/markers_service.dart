import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarkerService {
  Set<Marker> getMarkers(List<DocumentSnapshot> docs, BitmapDescriptor icon) {
    return docs.map((doc) {
      // doc.data() が null でないことを保証し、Map<String, dynamic> として扱う
      var data = doc.data() as Map<String, dynamic>?;

      // 安全な値の取り出しを行う
      if (data != null) {
        double latitude = data['latitude'] as double;
        double longitude = data['longitude'] as double;
        String description = data['description'] as String;

        LatLng position = LatLng(latitude, longitude);

        return Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: InfoWindow(title: 'Trash Bin', snippet: description),
          icon: icon,
        );
      } else {
        // データが null の場合は、適当なデフォルト値を使用するか、このマーカーをスキップする
        LatLng position = LatLng(0.0, 0.0);
        return Marker(
          markerId: MarkerId('default'),
          position: position,
          infoWindow:
              InfoWindow(title: 'Undefined', snippet: 'No data available'),
          icon: icon,
        );
      }
    }).toSet();
  }
}
