import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddBinDialog {
  static void showAddBinDialog(
      BuildContext context,
      LatLng position,
      void Function(LatLng, String) addMarker,
      Future<void> Function(LatLng, String) addTrashBinLocation) {
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Trash Bin"),
          content: TextField(
            controller: descriptionController,
            decoration: InputDecoration(hintText: "Enter description here"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Add"),
              onPressed: () {
                Navigator.of(context).pop();
                addMarker(position, descriptionController.text);
                addTrashBinLocation(position, descriptionController.text);
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
