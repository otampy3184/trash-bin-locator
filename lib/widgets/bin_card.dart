import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrashBinCard extends StatelessWidget {
  final Marker marker;
  final int index;
  final Color cardColor;

  TrashBinCard(
      {required this.marker,
      required this.index,
      this.cardColor = Colors.white});

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 背景を透明にすることで角丸などのデザインが可能に
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8, // 画面の高さの90%を使用
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, spreadRadius: 5)
              ]),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(marker.infoWindow.title ?? "Unnamed",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(marker.infoWindow.snippet ?? "No description",
                    style: TextStyle(fontSize: 18)),
                // Additional details can be added here
                // Other static content or widgets can be added as needed
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: ListTile(
          title: Text(marker.infoWindow.title ?? "Unnamed"),
          subtitle: Text(marker.infoWindow.snippet ?? "No description"),
        ),
        splashColor: Colors.blueGrey.withOpacity(0.3), // 波紋の色を設定
      ),
    );
  }
}
