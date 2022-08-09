import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_maps/Api Data/marker_data.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Markers extends StatefulWidget {
  const Markers({Key? key}) : super(key: key);

  @override
  State<Markers> createState() => _MarkersState();
}

class _MarkersState extends State<Markers> {
  @override
  void initState() {
    getCurrentLocation();
    getMarker();
    getPolyline();
    super.initState();
  }

  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;
  late Position _currentPosition;

  //for initial location
  final startAddressController = TextEditingController();

  //Markers
  final Set<Marker> markers = Set();
  Map<String, dynamic> addedMarkers = {}; //Added Markers
  List mergedLatLng = []; //Merged Lat Lon Value of marker
  List mergedLatLngNoLast = []; //merged Lat lng with no last element

  //Polylines
  Set<Polyline> polylines = {};
  List<LatLng> polyLatLong = [];

  //current location
  getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 12.0,
            ),
          ),
        );
      });
    }).catchError((e) {
      print(e);
    });
  }

  //sets markers from api and on press adds to added marker
  Set<Marker> getMarker() {
    setState(
      () {
        //this loops adds markers to the map from api data
        for (var i = 0; i < markerData.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId(markerData[i]["id"].toString()),
              position: LatLng(double.parse(markerData[i]["lat"].toString()),
                  double.parse(markerData[i]["lon"].toString())),
              infoWindow: InfoWindow(
                title: ' +  ADD',
                snippet: markerData[i]['snippet'].toString(),
                onTap: () {
                  setState(
                    () {
                      addedMarkers.addAll({
                        'lat': markerData[i]['lat'],
                        'lon': markerData[i]['lon'],
                      });
                      mergedLatLng.add(addedMarkers.values.join(","));
                      mergedLatLngNoLast.add(
                        addedMarkers.values.join(","),
                      );
                    },
                  );
                },
              ),
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
        }
      },
    );
    return markers;
  }

//polylines
  Set<Polyline> getPolyline() {
    setState(
      () {
        for (var i = 0; i < markerData.length; i++) {
          polyLatLong.add(LatLng(double.parse(markerData[i]['lat'].toString()),
              double.parse(markerData[i]['lon'].toString())));
          polylines.add(
            Polyline(
              polylineId: PolylineId(markerData[i]['id'].toString()),
              points: polyLatLong,
              color: Colors.teal,
              width: 6,
            ),
          );
        }
      },
    );
    return polylines;
  }

  //Open Google maps
  Future<void> launchGoogleMaps(double latitude, double longitude) async {
    mergedLatLngNoLast.removeLast();
    String googleUrl =
        "google.navigation:q=${mergedLatLng.last}&waypoints=${mergedLatLngNoLast.join("|")}&travelmode=driving&dir_action=navigate";
    launchUrlString(googleUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            markers: Set<Marker>.from(markers),
            initialCameraPosition: _initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            polylines: polylines,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
          ),

          // Show current location button
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                child: ClipOval(
                  child: Material(
                    color: Colors.orange.shade100, // button color
                    child: InkWell(
                      splashColor: Colors.orange, // inkwell color
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.my_location),
                      ),
                      onTap: () {
                        mapController.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                _currentPosition.latitude,
                                _currentPosition.longitude,
                              ),
                              zoom: 13.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          //Page Header
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                        child: Text(
                          'Add Markers',
                          style: TextStyle(fontSize: 20.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    //Go to google maps
                    ClipOval(
                      child: Material(
                        color: Colors.white70, // button color
                        child: InkWell(
                          splashColor: Colors.orangeAccent, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(
                              Icons.mode_of_travel_sharp,
                            ),
                          ),
                          onTap: () => launchGoogleMaps(
                              double.parse(markerData[0]['lat'].toString()),
                              double.parse(markerData[0]['lon'].toString())),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          //Back Button
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 80.0, bottom: 10.0),
                child: ClipOval(
                  child: Material(
                    color: Colors.orange.shade100, // button color
                    child: InkWell(
                      splashColor: Colors.orange, // inkwell color
                      child: SizedBox(
                        width: 55,
                        height: 55,
                        child: Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
