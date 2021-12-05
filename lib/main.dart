import 'dart:async';
import 'dart:io' as platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:traking_onmap/follow_y_req.dart';
import 'package:provider/provider.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Builder(builder: (context) {
    return const MyApp();
  }));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  //// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController? gmc;
  LatLng? sources;
  LatLng? destination;
  Polyline? p;
  pickDestination() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacePicker(
          apiKey:
              "AIzaSyC3FEo_7bksnMhiBfGiZ9ruvW7c3bxRf2Y", // Put YOUR OWN KEY here.
          onPlacePicked: (result) {
            destination = LatLng(
                result.geometry!.location.lat, result.geometry!.location.lng);
               createRoute();
            Navigator.of(context).pop();
          },

          initialPosition: sources!,
          useCurrentLocation: true,
        ),
      ),
    );

    ///this method create juerney route after route have been choosen!
 
  }

  createRoute() async {
    var mapKey = "AIzaSyC3FEo_7bksnMhiBfGiZ9ruvW7c3bxRf2Y";
    var s = PointLatLng(sources!.latitude, sources!.longitude);
    var d = PointLatLng(destination!.latitude, destination!.longitude);

    var point = await PolylinePoints().getRouteBetweenCoordinates(mapKey, s, d);
    List<LatLng> points =
        point.points.map((e) => LatLng(e.latitude, e.longitude)).toList();

    p = Polyline(polylineId: const PolylineId("j"), points: points,color:const Color.fromARGB(200, 0, 0, 200));
    setState(() {
      p = p;
    });
  }

  updateMarker(Position p) async {
    var l = LatLng(p.latitude, p.longitude);
    var ic = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(50, 50)), "assets/delivery.png");
    setState(() {
      circle = Circle(
          circleId: CircleId("c"),
          center: l,
          radius: 150,
          strokeColor: Colors.transparent,
          fillColor: Color.fromARGB(300, 0, 0, 255));
      marker = Marker(
          markerId: const MarkerId("a"),
          position: l,
          icon: ic,
          rotation: 0.5,
          anchor: const Offset(0.7, 0.7));
    });
  }

  Future<Position> getCurrentPosition() async {
    var x = await Geolocator.isLocationServiceEnabled();

    if (!x) {
      return Future.error("Service not availbel");
    }
    if (x) {
      var p = await Geolocator.checkPermission();
      print(p);
      if (LocationPermission.denied == p) {
        var rp = await Geolocator.requestPermission();
        print(rp);
        if (LocationPermission.denied == rp) {
          return Future.error("data not avia");
        }
      }
    }
    var po = await Geolocator.getCurrentPosition();
    sources = LatLng(po.latitude, po.longitude);
    return po;
  }

  @override
  void initState() {
    // listenToLocationIsOnOrOf();
    // TODO: implement initState
    super.initState();
  }

  StreamSubscription? st;

  Future listenToLocationIsOnOrOf() async {
    var xt = await Geolocator.isLocationServiceEnabled();

    var x = AlertDialog(
      title: Text("location is disable enable"),
      actions: [
        MaterialButton(
          onPressed: () async {
            // await SystemNavigator.pop();

            // void openLocationSetting() async {
            //   final AndroidIntent intent = new AndroidIntent(
            //     action: 'android.settings.LOCATION_SOURCE_SETTINGS',
            //   );
            //   await intent.launch();
            // }

            // if (platform.Platform.isAndroid) openLocationSetting();
            st = Geolocator.getPositionStream().listen((event) async {
              var l = await Geolocator.isLocationServiceEnabled();
              print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");
              if (l) {
                st!.cancel();
                if (st != null) setState(() {});
              }
            });
            Navigator.pop(context);
          },
          child: Text("enable"),
        ),
        MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("close"),
        )
      ],
    );
    if (!xt) showDialog(context: context, builder: (context) => x);
  }

  // @override
  // void dispose() {
  //   print("dispoooooooooooooooooosed!");
  //   st!.cancel();
  //   // TODO: implement dispose
  //   super.dispose();
  // }
  Marker? marker;
  Circle? circle;
  @override
  Widget build(BuildContext context) {
    print(" er");
    return Scaffold(
      appBar: AppBar(
        title: const Text("TRAKING"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder(
                future: getCurrentPosition(),
                builder: (context, AsyncSnapshot<Position> sa) {
                  if (!sa.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (sa.hasError) {
                    return const Center(
                      child: Text("Location service is disabled in you device"),
                    );
                  }
                  if (sa.hasData) {
                    var co = sa.data;
                    var ll = LatLng(co!.latitude, co.longitude);

                    print("########");
                    print(ll.longitude);

                    return GoogleMap(
                        polylines: {
                          p ?? const Polyline(polylineId: PolylineId("p"))
                        },
                        onMapCreated: (gm) {
                          gmc = gm;
                        },
                        circles: {
                          circle ??
                              const Circle(
                                  circleId: CircleId("c"),
                                  radius: 50,
                                  fillColor: Color.fromARGB(50, 0, 0, 255))
                        },
                        markers: {
                          marker ?? const Marker(markerId: MarkerId("d"))
                        },
                        compassEnabled: true,
                        myLocationButtonEnabled: true,
                        initialCameraPosition:
                            CameraPosition(target: ll, zoom: 15));
                  }
                  return Center(
                    child: Text("Location service is disabled in you device"),
                  );
                }),
            FloatingActionButton(
                child: Text(" sCord"),
                onPressed: () async {
                  if (gmc != null) {
                    // var x = await gmc!.getLatLng(ScreenCoordinate(x: 50, y: 50));
                    // print(x.latitude);
                    //  var x = await gmc!.getZoomLevel();
                    // print(x );

                    ///update camer position
                    ///
                    var newcamera =
                        await gmc!.getLatLng(ScreenCoordinate(x: 0, y: 0));
                    var x = await gmc!.moveCamera(
                        CameraUpdate.newCameraPosition(
                            CameraPosition(target: newcamera, zoom: 15)));
                  }
                }),
            Positioned(
              left: 3,
              bottom: 30,
              child: MaterialButton(
                color: Colors.green,
                onPressed: () {
                  Geolocator.getPositionStream(distanceFilter: 100)
                      .listen((event) async {
                    //  await Future.delayed(const Duration(seconds: 2));
                    var d = await FirebaseFirestore.instance
                        .collection("currentloc")
                        .get();
                    var t = d.docs;
                    var prev = t[0]["location"];
                    if (t.isEmpty) {
                      print("@@@@@@@@@@@@@@@@@@@@@@@@@@");
                      await FirebaseFirestore.instance
                          .collection("currentloc")
                          .add({
                        "location": GeoPoint(event.latitude, event.longitude)
                      });
                    } else {
                      var docs = d.docs;
                      if (docs.isNotEmpty) {
                        var prevd;
                        var dist = Geolocator.distanceBetween(prev.latitude,
                            prev.longitude, event.latitude, event.longitude);

                        print("dist is now $dist");
                        if (dist > 100) {
                          await FirebaseFirestore.instance
                              .collection("currentloc")
                              .doc(docs[0].id)
                              .update({
                            "location":
                                GeoPoint(event.latitude, event.longitude)
                          });
                          await gmc!.moveCamera(CameraUpdate.newCameraPosition(
                              CameraPosition(
                                  target:
                                      LatLng(event.latitude, event.longitude),
                                  zoom: 15)));

                          updateMarker(event);
                        }
                      }
                    }
                    print("changes are ${event.latitude}");
                  });
                },
                child: Text("start Lisent to changes"),
              ),
            ),
            Positioned(
                right: 0,
                top: 10,
                child: MaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ShowReq()));
                  },
                  child: Text("show My Request!"),
                )),
            Positioned(
                top: 100,
                child: MaterialButton(
                  color: Colors.teal,
              onPressed: () {
                pickDestination();
              },
              child: Text("pick A Juerny"),
            ))
          ],
        ),
      ),
    );
  }
}

// class UpdatMarker extends ChangeNotifier {
//   Marker? m = Marker(
//     markerId: MarkerId("sd"),
//   );
//   Marker getmarkers() {
//     return m!;
//   }

//   Future updateMarker(LatLng v) async {
//     m = Marker(markerId: MarkerId("1"), position: v);
//     notifyListeners();
//   }
// }
