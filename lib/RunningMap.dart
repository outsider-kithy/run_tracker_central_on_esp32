import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'RunningData.dart';

// === 埋め込み用ウィジェット ===
class RunningMap extends StatefulWidget {
  
  final List<Point> points;
  const RunningMap({super.key, required this.points});

  @override
  State<RunningMap> createState() => _RunningMapState();
}

class _RunningMapState extends State<RunningMap> {
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  LatLng? startPosition;

  @override
  void initState() {
    super.initState();

    final polylinePoints = widget.points
        .map((p) => LatLng(p.lat, p.lng))
        .toList();

    if (polylinePoints.isNotEmpty) {
      startPosition = polylinePoints.first;
      
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 4,
          points: polylinePoints,
        ),
      );

      markers = {
        Marker(
          markerId: const MarkerId('start'),
          position: polylinePoints.first,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: polylinePoints.last,
          infoWindow: const InfoWindow(title: 'Goal'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (startPosition == null) {
      return const Center(child: Text("位置データがありません"));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: startPosition!,
          zoom: 16,
        ),
        polylines: polylines,
        markers: markers,
        myLocationEnabled: false,
        onMapCreated: (controller) => mapController = controller,
      ),
    );
  }
}
