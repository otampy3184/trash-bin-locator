import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/drawer_menu.dart';
import '../widgets/add_bin_dialog.dart';
import '../widgets/bin_card.dart';

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
    _loadCards();
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
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<double> _calculateDistanceToMarker(LatLng markerPosition) async {
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      markerPosition.latitude,
      markerPosition.longitude,
    );
  }

  void _loadMarkers() async {
    try {
      var docs = await _firestoreService.loadMarkers();
      var markers = await _markerService.getMarkers(
          docs, customIcon!);
      setState(() {
        _markers = markers;
      });
    } catch (e) {
      print("Failed to load markers: $e");
    }
  }

  void _loadCards() async {
    if (mapController != null) {
      LatLngBounds bounds = await mapController!.getVisibleRegion();
      var visibleMarkers =
          _markers.where((marker) => bounds.contains(marker.position)).toList();
      _updateCards(visibleMarkers);
    } else {
      print("mapController is not initialized yet.");
    }
  }

  void _addMarker(LatLng position, String description) async {
    double distance = await _calculateDistanceToMarker(position);
    String distanceText = _formatDistance(distance);

    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(
          title: description, snippet: '現在地から$distanceText'),
      icon: customIcon ?? BitmapDescriptor.defaultMarker,
    );
    setState(() {
      _markers.add(marker);
    });
  }

  String _formatDistance(double distance) {
    return distance < 500
        ? '${distance.toStringAsFixed(0)} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _loadCards();
  }

  void _onCameraIdle() async {
    // カメラが停止したときにビューポートを取得
    LatLngBounds bounds = await mapController!.getVisibleRegion();
    var visibleMarkers =
        _markers.where((marker) => bounds.contains(marker.position)).toList();
    _updateCards(visibleMarkers);
  }

  void _updateCards(List<Marker> visibleMarkers) {
    List<Widget> newCards = visibleMarkers.asMap().entries.map((entry) {
      int idx = entry.key;
      Marker marker = entry.value;
      return TrashBinCard(marker: marker, index: idx, cardColor: Colors.white);
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

  void _goToCurrentLocation() async {
    // 現在の位置情報を取得
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15.0,
      ),
    ));
  }

  void _showAddBinDialog(BuildContext context, LatLng position) {
    AddBinDialog.showAddBinDialog(
        context, position, _addMarker, _firestoreService.addTrashBinLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ごみ箱まっぷ'),
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
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.2,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12.0,
              ),
              myLocationEnabled: true,
              markers: _markers,
              onLongPress: _onMapLongPress,
              onCameraIdle: _onCameraIdle,
            ),
          ),
          Positioned(
            right: 10,
            top: 10, // 任意の位置に配置
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.black),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3, // 画面の高さの30%を使用
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("付近のごみ箱一覧",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.sort),
                              onPressed: () {
                                // TODO: ソートロジックを追加
                                print("Sort button pressed");
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.filter_list),
                              onPressed: () {
                                // TODO: フィルタリングロジックを追加
                                print("Filter button pressed");
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return cards[index];
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
