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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(

MultiProvider(providers: [


  ChangeNotifierProvider(create: (_)=>UpdatMarker())
],child:const MyApp(),)

  );
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
    return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    listenToLocationIsOnOrOf();
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
              print(event.altitude);
              if (l) {
                st!.cancel();
                setState(() {});
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
  Set<Marker> marker = {};
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
                  if (sa.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (sa.hasError) {
                    return const Center(
                      child: Text("Location service is disabled in you device"),
                    );
                  }
                  if (sa.connectionState == ConnectionState.done &&
                      sa.hasData) {
                    var co = sa.data;
                    var ll = LatLng(co!.latitude, co.longitude);
                    if (marker.isEmpty) {
                      marker.add(
                          Marker(markerId: const MarkerId("1"), position: ll));
                    }

                    print("########");
                    print(ll.longitude);

                    return GoogleMap(
                        onMapCreated: (gm) {
                          gmc = gm;
                        },
                        markers:    
                         marker



                        ,
                        compassEnabled: true,
                        myLocationEnabled: true,
                        initialCameraPosition:
                            CameraPosition(target: ll, zoom: 3));
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
                            CameraPosition(target: newcamera, zoom: 3)));
                           
                  }
                }),
            Positioned(
              left: 3,
              bottom: 30,
              child: MaterialButton(
                color: Colors.green,
                onPressed: () {
                  Geolocator.getPositionStream().listen((event) async {
                    await Future.delayed(const Duration(seconds: 2));
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
                        var dist = Geolocator.distanceBetween(prev.latitude,
                            prev.longitude, event.latitude, event.longitude);
                        if (dist > 1) {
                          await FirebaseFirestore.instance
                              .collection("currentloc")
                              .doc(docs[0].id)
                              .update({
                            "location":
                                GeoPoint(event.latitude, event.longitude)
                          });

                          //          setState(() {
                          //   marker = marker;
                          // });

                        }
                      }
                    }
                    print("changes are ${event.latitude}");

                    ///update camere and with new location when user location changed
                    ///
                    if (marker.isNotEmpty) {
                      marker.remove(marker.elementAt(0));
                    }

                    marker.add(Marker(
                        markerId: const MarkerId("1"),
                        position: LatLng(event.latitude, event.longitude)));
                    await gmc!.moveCamera(CameraUpdate.newCameraPosition(
                        CameraPosition(
                            target: LatLng(event.latitude, event.longitude),
                            zoom: 5)));
                    await gmc!.showMarkerInfoWindow(MarkerId("1"));
                   });
                  setState(() {
                    marker = marker;
                  });
                },
                child: Text(" start Lisent to changes"),
              ),
            ),
            Positioned(
                child: MaterialButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ShowReq()));
              },
              child: Text("show My Request!"),
            ))
          ],
        ),
      ),
    );
  }
}

class UpdatMarker extends ChangeNotifier {
   Marker? m=Marker(markerId: MarkerId("sd"),) ;
 Marker getmarkers() {
    return m!;
  }

  Future updateMarker(LatLng v) async {
   
      m=
        Marker(markerId: MarkerId("1"), position: v)
      ;
      notifyListeners();
    }
  }

