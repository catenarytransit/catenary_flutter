
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:catenary_flutter/src/rust/api/simple.dart';
import 'package:catenary_flutter/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MaterialApp(home: Catenary()));
}

String stringFromTheme() {
  var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
  bool isDarkMode = brightness == Brightness.dark;

  print(Brightness);

  if (isDarkMode) {
    return "https://raw.githubusercontent.com/catenarytransit/catenary-frontend/refs/heads/main/static/dark-style.json";
  } else {
    return "https://raw.githubusercontent.com/catenarytransit/catenary-frontend/refs/heads/main/static/light-style.json";
  }
}

class Catenary extends StatefulWidget {
  const Catenary({super.key});

  @override
  State<Catenary> createState() => _CatenaryState();
}

class _CatenaryState extends State<Catenary> {
  //Initial State for the App
  Location location = Location();
  MapLibreMapController? mapController;
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _locationData = null;
  bool loadedMap = false;

  Future<void> initHybridComposition() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      if (sdkVersion >= 29) {
        MapLibreMap.useHybridComposition = true;
      } else {
        MapLibreMap.useHybridComposition = false;
      }
    }
  }

  void transferGeolocationOntoMap() async {
    if (mapController != null && loadedMap == true) {
      List<String> mapSourceList = await mapController!.getSourceIds();
      if (_locationData!.latitude != null && _locationData!.longitude != null) {

        developer.log(_locationData!.latitude.toString() ?? "null" , name: "latitude");
        if (mapSourceList.contains("user_location_circle")) {
          developer.log("source list found" , name: "location");

          if (mapController != null  && loadedMap == true) {
            await mapController?.setGeoJsonSource("user_location_circle", {
              "type": "FeatureCollection",
              "features": [{
                "type": "Feature",
                "properties": {},
                "geometry": {
                  "coordinates": [
                    _locationData!.longitude,
                    _locationData!.latitude
                  ],
                  "type": "Point"
                }
              }]
            });
          }
        }

      }



    }
  }

  void startInitAsync() async {
    _permissionGranted = await location.hasPermission();

    location.onLocationChanged.listen((LocationData currentLocation) async {
      _locationData = currentLocation;

      transferGeolocationOntoMap();
    });
  }

  @override
  void initState() {
    super.initState();

    startInitAsync();
  }

  void flyToLocationButtonPressed() async {
    //ask for permission, and if rejected, quit the function
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

   // _locationData = await location.getLocation();

    if (mapController != null && _locationData != null) {
      transferGeolocationOntoMap();

      CameraUpdate c = CameraUpdate.newLatLngZoom( LatLng(_locationData!.latitude!, _locationData!.longitude!), 15);

      mapController!.animateCamera(c, duration: const Duration(milliseconds: 2500));
    }


  }

  void _onMapCreated(MapLibreMapController controller) async {
    mapController = controller;
  }

  Future<void> makeGeolocationShapes(MapLibreMapController controller) async {
    await controller.addGeoJsonSource("user_location_circle", {
      "type": "FeatureCollection",
      "features": []
    });

    await controller.addCircleLayer("user_location_circle", "user_location_circle_shadow",
        const CircleLayerProperties(
            circleColor: "#0011aa",
            circleRadius: 8,
            circleBlur: 3,
            circleOpacity: 0.4,
        )
    );

    await controller.addCircleLayer("user_location_circle", "user_location_circle_white",
        const CircleLayerProperties(
            circleColor: "#ffffff",
            circleRadius: 7
        )
    );

    await controller.addCircleLayer("user_location_circle", "user_location_circle_blue",
        const CircleLayerProperties(
          circleColor: "#4083f5",
          circleRadius: 6
        )

    );
  }

  void runStyleCallbackAsync() async {

    await makeGeolocationShapes(mapController!);
  }

  void runStyleCallback() {
    loadedMap = true;

    runStyleCallbackAsync();
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       floatingActionButton: new FloatingActionButton(onPressed: ()
     {
       flyToLocationButtonPressed();
       },
           child: const Icon(MdiIcons.crosshairsGps),

       ),
      body: MapLibreMap(
        styleString: stringFromTheme(),
        onMapCreated: _onMapCreated,
        myLocationEnabled: _serviceEnabled == true,
        initialCameraPosition: _locationData == null
            ? const CameraPosition(target: LatLng(0.0, 0.0))
            : CameraPosition(target: LatLng(_locationData?.latitude ?? 0,
            _locationData?.longitude ?? 0)),
        trackCameraPosition: true,
        compassEnabled: false,
        onStyleLoadedCallback: runStyleCallback,
      ),
    );
  }
}
