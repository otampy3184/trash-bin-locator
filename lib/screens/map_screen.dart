import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/drawer_menu.dart';
import '../widgets/add_bin_dialog.dart';

import '../services/firestore_service.dart';
import '../services/markers_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _initialPosition = LatLng(35.6895, 139.6917); // デフォルトの位置情報
  GoogleMapController? mapController;
  BitmapDescriptor? customIcon;
  Set<Marker> _markers = {};
  List<Widget> cards = [];

  final FirestoreService _firestoreService = FirestoreService();
  final MarkerService _markerService = MarkerService();
  final PageController _pageController = PageController(
    viewportFraction: 0.9, // ビューポートの90%を各カードが占めるように設定
    initialPage: 0,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _setCustomIcon();
    _loadMarkers();
  }

  void _setCustomIcon() async {
    customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pin/trash-bin-app.png');
  }


  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 位置情報サービスが有効でない場合の処理
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // パーミッションが拒否された場合の処理
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // パーミッションが永久に拒否された場合の処理
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // 現在の位置を取得
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _loadMarkers() async {
    var docs = await _firestoreService.loadMarkers();
    var markers = _markerService.getMarkers(docs, customIcon!);
    setState(() {
      _markers = markers;
    });
  }

  void _addMarker(LatLng position, String description) {
    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(title: 'Trash Bin', snippet: description),
      icon: customIcon ?? BitmapDescriptor.defaultMarker,
    );
    setState(() {
      _markers.add(marker);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onCameraIdle() async {
    // カメラが停止したときにビューポートを取得
    LatLngBounds bounds = await mapController!.getVisibleRegion();
    var visibleMarkers =
        _markers.where((marker) => bounds.contains(marker.position)).toList();
    _updateCards(visibleMarkers);
  }

  void _updateCards(List<Marker> visibleMarkers) {
    List<Widget> newCards = visibleMarkers.map((marker) {
      return Card(
        margin: EdgeInsets.all(8),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          title: Text(marker.infoWindow.title ?? "Unnamed"),
          subtitle: Text(marker.infoWindow.snippet ?? "No description"),
        ),
      );
    }).toList();

    setState(() {
      cards = newCards;
    });
  }

  void _onMapLongPress(LatLng position) {
    if (FirebaseAuth.instance.currentUser != null) {
      _showAddBinDialog(context, position);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You need to log in to add bins.")));
    }
  }

  void _showAddBinDialog(BuildContext context, LatLng position) {
    AddBinDialog.showAddBinDialog(
        context, position, _addMarker, _firestoreService.addTrashBinLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trash Bin Locator'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: DrawerMenu(),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12.0,
              ),
              myLocationEnabled: true,
              markers: _markers,
              onLongPress: _onMapLongPress, // 長押しイベントを追加
              onCameraIdle: _onCameraIdle,
            ),
          ),
          Expanded(
            flex: 1,
            child: PageView(
              children: cards,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
