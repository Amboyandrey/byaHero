import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MapSample(),
  ));
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  BitmapDescriptor userIcon = BitmapDescriptor.defaultMarker;
  final places =
      GoogleMapsPlaces(apiKey: 'AIzaSyCOYN8rfj32lgm5nHq1fVH9VetVopr8R5Y');

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(13.763337564032678, 121.05714965214322),
    zoom: 14.4746,
  );

  void setCustomIcon() {
    BitmapDescriptor.fromAssetImage(ImageConfiguration.empty, "assets/user.png")
        .then(
      (icon) {
        userIcon = icon;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    setCustomIcon();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied");
    }
  }

  Future<void> _goToTheUserLocation() async {
    final GoogleMapController controller = await _controller.future;

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId("user_location"),
            position: userLocation,
            icon: userIcon,
          ),
        );
      });

      await controller.animateCamera(CameraUpdate.newLatLng(userLocation));
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _searchPlaces(String query) async {
    PlacesSearchResponse response = await places.searchByText(query);
    if (response.isOkay) {
      setState(() {
        _markers.clear();
      });

      for (PlacesSearchResult result in response.results) {
        final LatLng location = LatLng(
          result.geometry!.location.lat,
          result.geometry!.location.lng,
        );

        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(result.placeId),
              position: location,
              infoWindow: InfoWindow(title: result.name),
            ),
          );
        });
      }
    } else {
      print('Error searching for places: ${response.errorMessage}');
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Where would you prefer to travel today?',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.add_location_outlined),
                    labelText: 'Origin',
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.add_location_rounded),
                    labelText: 'Destination',
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  icon: Icon(Icons.route),
                  label: Text('Search Route'),
                  onPressed: () {
                    // Add your route search logic here
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromRGBO(255, 165, 0, 1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                zoomControlsEnabled: false,
                markers: _markers,
              ),
              Positioned(
                top: 44.0,
                left: 16.0,
                right: 16.0,
                child: SearchBar(onSearch: _searchPlaces),
              ),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 35.0),
              FloatingActionButton.extended(
                onPressed: _showBottomSheet,
                label: const Text('Select Route'),
                backgroundColor: Color.fromRGBO(255, 165, 0, 1),
                icon: const Icon(Icons.route),
              ),
              SizedBox(width: 20.0),
              FloatingActionButton.extended(
                onPressed: _goToTheUserLocation,
                label: const Text('My Location'),
                backgroundColor: Color.fromRGBO(255, 165, 0, 1),
                icon: const Icon(Icons.location_on),
              ),
            ],
          ),
        ));
  }
}

class SearchBar extends StatefulWidget {
  final Function(String) onSearch;

  SearchBar({required this.onSearch});

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        color: Color.fromARGB(255, 255, 255, 255),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 8.0),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search your Destination',
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  if (widget.onSearch != null) {
                    widget.onSearch(query);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
