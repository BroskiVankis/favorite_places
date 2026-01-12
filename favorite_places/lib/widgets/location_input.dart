import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:favorite_places/models/place.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:favorite_places/screens/map.dart';
import 'package:latlong2/latlong.dart';

class LocationInput extends StatefulWidget {
  const LocationInput({super.key, required this.onSelectLocation});

  final void Function(PlaceLocation location) onSelectLocation;

  @override
  State<LocationInput> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  PlaceLocation? _pickedLocation;
  var _isGettingLocation = false;

  String get locationImage {
    if (_pickedLocation == null) {
      return '';
    }
    final lat = _pickedLocation!.latitude;
    final lon = _pickedLocation!.longitude;
    // Using OSM tile server - note: no markers, just shows the location centered
    final zoom = 10;
    return 'https://tile.openstreetmap.org/$zoom/${_lonToTile(lon, zoom)}/${_latToTile(lat, zoom)}.png';
  }

  int _latToTile(double lat, int zoom) {
    return ((1 - (log(tan(lat * pi / 180) + 1 / cos(lat * pi / 180)) / pi)) /
            2 *
            pow(2, zoom))
        .floor();
  }

  int _lonToTile(double lon, int zoom) {
    return ((lon + 180) / 360 * pow(2, zoom)).floor();
  }

  Future<void> _savePlace(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'favorite_places_app/1.0'},
      );
      final resData = json.decode(response.body);
      final address = resData['display_name'];

      setState(() {
        _pickedLocation = PlaceLocation(
          latitude: latitude,
          longitude: longitude,
          address: address,
        );
        _isGettingLocation = false;
      });

      widget.onSelectLocation(_pickedLocation!);
    } catch (error) {
      setState(() {
        _isGettingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get address: $error')),
        );
      }
    }
  }

  void _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    setState(() {
      _isGettingLocation = true;
    });

    locationData = await location.getLocation();
    final lat = locationData.latitude;
    final lon = locationData.longitude;

    if (lat == null || lon == null) {
      return;
    }

    _savePlace(lat, lon);
  }

  void _selectOnMap() async {
    final selectedLocation = await Navigator.of(
      context,
    ).push<LatLng>(MaterialPageRoute(builder: (ctx) => const MapScreen()));

    if (selectedLocation == null) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    await _savePlace(selectedLocation.latitude, selectedLocation.longitude);
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = Text(
      'No Location Chosen',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );

    if (_pickedLocation != null) {
      previewContent = Image.network(
        locationImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_isGettingLocation) {
      previewContent = const CircularProgressIndicator();
    }

    return Column(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: previewContent,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.location_on),
              label: const Text('Get Current Location'),
              onPressed: _getCurrentLocation,
            ),
            TextButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Select on Map'),
              onPressed: _selectOnMap,
            ),
          ],
        ),
      ],
    );
  }
}
