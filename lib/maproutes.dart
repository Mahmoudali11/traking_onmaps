import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';

class MapRoute extends StatefulWidget {
  const MapRoute({Key? key}) : super(key: key);

  @override
  _MapRouteState createState() => _MapRouteState();
}

class _MapRouteState extends State<MapRoute> {
  Set<Polyline> p = {};
  Position? s;
  getCurrentPosition() async {
    var x = await Geolocator.getCurrentPosition();
    s = x;
    setState(() {});
  }

  @override
  void initState() {
    getCurrentPosition();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: s != null
          ? GoogleMap(
              markers: {
                Marker(
                    markerId: MarkerId("ds"),
                    position: LatLng(s!.latitude, s!.longitude))
              },
              initialCameraPosition:
                  CameraPosition(target: LatLng(s!.latitude, s!.longitude)),
              polylines: p,
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.location_on_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlacePicker(
                apiKey:
                    "AIzaSyC3FEo_7bksnMhiBfGiZ9ruvW7c3bxRf2Y", // Put YOUR OWN KEY here.
                onPlacePicked: (result) {
                  print(result.geometry!.location.lat);
                 
                  Navigator.of(context).pop();
                },

                initialPosition: LatLng(s!.latitude, s!.longitude),
                useCurrentLocation: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
