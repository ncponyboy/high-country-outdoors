import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/trail.dart';

class TrailService extends ChangeNotifier {
  List<Trail> trails = [];
  bool isLoading = false;
  String? errorMessage;

  static const String _url =
      'https://raw.githubusercontent.com/ncponyboy/high-country-outdoors/main/trail_conditions.json';

  Future<void> fetchTrails() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> rawTrails =
            (data['trails'] as List<dynamic>?) ?? [];
        trails = rawTrails
            .whereType<Map<String, dynamic>>()
            .map(Trail.fromJson)
            .toList();
        errorMessage = null;
      } else {
        errorMessage =
            'Failed to load trail conditions (${response.statusCode}).';
      }
    } catch (e) {
      errorMessage = 'Could not reach the server. Check your connection.';
      debugPrint('TrailService error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns trails sorted by distance from the given coordinates.
  List<Trail> sortedByDistance(double lat, double lng) {
    final sorted = List<Trail>.from(trails);
    sorted.sort(
      (a, b) =>
          a.distanceMiles(lat, lng).compareTo(b.distanceMiles(lat, lng)),
    );
    return sorted;
  }

  /// Returns trails that have at least one active alert.
  List<Trail> get trailsWithAlerts =>
      trails.where((t) => t.alerts.isNotEmpty).toList();
}
