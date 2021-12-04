import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traking_onmap/maproutes.dart';

class ShowReq extends StatefulWidget {
  const ShowReq({Key? key}) : super(key: key);

  @override
  _ShowReqState createState() => _ShowReqState();
}

class _ShowReqState extends State<ShowReq> {
  GoogleMapController? gmc;
  Set<Marker> marker = {};
  @override
  void dispose() {
    // if(gmc!=null)
    // gmc!.dispose();
    print("@@@@@hi from dispose method this will realse resources!");
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    //if (gmc != null) gmc!.dispose();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          MaterialButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const MapRoute()));
            },
            child: Text("view Path of Jouerny"),
          ),
          Expanded(
            child: FutureBuilder(
              future: FirebaseFirestore.instance.collection("currentloc").get(),
              builder: (context, AsyncSnapshot<QuerySnapshot> sap) {
                if (sap.connectionState == ConnectionState.waiting) {
                  return Center(child: const CircularProgressIndicator());
                }

                if (sap.hasData) {
                  print("dfdewewewe@@@@@@@@@@@@@@@@@@@@@@@@@@@f");
                  var d = sap.data!.docs;
                  var loc = LatLng(
                      d[0]["location"].latitude, d[0]["location"].longitude);
                  print("lat${d[0]["location"].latitude}");
                  var cam = CameraPosition(target: loc, zoom: 3);
                  if (marker.isEmpty)
                    marker.add(Marker(markerId: MarkerId("d"), position: loc));
                  return GoogleMap(
                    onMapCreated: (c) {
                      gmc = c;
                    },
                    markers: marker,
                    initialCameraPosition: cam,
                  );
                }
                return Center(
                  child: Text("no  juerney is available now!"),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (gmc != null) {
            print("new changes in location!");
            FirebaseFirestore.instance
                .collection("currentloc")
                .snapshots()
                .listen((event) {
              var d = event.docs;

              var loc =
                  LatLng(d[0]["location"].latitude, d[0]["location"].longitude);
              marker.remove(marker.elementAt(0));

              marker.add(Marker(markerId: const MarkerId("3"), position: loc));
              setState(() {
                marker = marker;
              });

              print(d[0]["location"].latitude);
              var cam = CameraPosition(target: loc, zoom: 3);
              gmc!.moveCamera(CameraUpdate.newCameraPosition(cam));
            });
          }
        },
        child: const Text("start Trak you requst"),
      ),
    );
  }
}
