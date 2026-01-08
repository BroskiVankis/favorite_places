import 'package:favorite_places/models/place.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  String get locationImage {
    final lat = place.location.latitude;
    final lon = place.location.longitude;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(place.title)),
      body: Stack(
        children: [
          Image.file(
            place.image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage(locationImage),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    textAlign: TextAlign.center,
                    place.location.address,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
