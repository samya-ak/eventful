import 'dart:io';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';

class KmlData {
  final List<KmlPlacemark> placemarks;
  final List<KmlPolyline> polylines;

  KmlData({required this.placemarks, required this.polylines});
}

class KmlPlacemark {
  final String name;
  final String? description;
  final LatLng coordinates;

  KmlPlacemark({
    required this.name,
    this.description,
    required this.coordinates,
  });
}

class KmlPolyline {
  final String name;
  final String? description;
  final List<LatLng> coordinates;

  KmlPolyline({
    required this.name,
    this.description,
    required this.coordinates,
  });
}

class KmlParser {
  static Future<KmlData?> parseKmlAsset(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      return _parseKmlContent(content);
    } catch (e) {
      print('Error loading KML asset: $e');
      return null;
    }
  }

  static Future<KmlData?> parseKmlFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('KML file not found: $filePath');
        return null;
      }

      final content = await file.readAsString();
      return _parseKmlContent(content);
    } catch (e) {
      print('Error parsing KML file: $e');
      return null;
    }
  }

  static KmlData? _parseKmlContent(String content) {
    try {
      final document = XmlDocument.parse(content);

      final placemarks = <KmlPlacemark>[];
      final polylines = <KmlPolyline>[];

      // Find all placemark elements
      final placemarksElements = document.findAllElements('Placemark');

      for (final placemark in placemarksElements) {
        final name =
            placemark.findElements('name').firstOrNull?.innerText ?? 'Unnamed';
        final description = placemark
            .findElements('description')
            .firstOrNull
            ?.innerText;

        // Check if this is a point placemark
        final pointElement = placemark.findElements('Point').firstOrNull;
        if (pointElement != null) {
          final coordinatesText = pointElement
              .findElements('coordinates')
              .firstOrNull
              ?.innerText
              .trim();

          if (coordinatesText != null && coordinatesText.isNotEmpty) {
            final coords = _parseCoordinates(coordinatesText);
            if (coords.isNotEmpty) {
              placemarks.add(
                KmlPlacemark(
                  name: name,
                  description: description,
                  coordinates: coords.first,
                ),
              );
            }
          }
        }

        // Check if this is a linestring placemark (polyline)
        final lineStringElement = placemark
            .findElements('LineString')
            .firstOrNull;
        if (lineStringElement != null) {
          final coordinatesText = lineStringElement
              .findElements('coordinates')
              .firstOrNull
              ?.innerText
              .trim();

          if (coordinatesText != null && coordinatesText.isNotEmpty) {
            final coords = _parseCoordinates(coordinatesText);
            if (coords.isNotEmpty) {
              polylines.add(
                KmlPolyline(
                  name: name,
                  description: description,
                  coordinates: coords,
                ),
              );
            }
          }
        }
      }

      return KmlData(placemarks: placemarks, polylines: polylines);
    } catch (e) {
      print('Error parsing KML content: $e');
      return null;
    }
  }

  static List<LatLng> _parseCoordinates(String coordinatesText) {
    final coordinates = <LatLng>[];

    try {
      // Split by whitespace and newlines
      final coordStrings = coordinatesText
          .split(RegExp(r'\s+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();

      for (final coordString in coordStrings) {
        final parts = coordString.split(',');
        if (parts.length >= 2) {
          final longitude = double.tryParse(parts[0].trim());
          final latitude = double.tryParse(parts[1].trim());

          if (longitude != null && latitude != null) {
            coordinates.add(LatLng(latitude, longitude));
          }
        }
      }
    } catch (e) {
      print('Error parsing coordinates: $e');
    }

    return coordinates;
  }
}
