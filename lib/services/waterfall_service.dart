import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/waterfall.dart';

class WaterfallService extends ChangeNotifier {
  List<Waterfall> waterfalls = [];
  bool isLoading = false;
  String? errorMessage;

  static const String _url =
      'https://raw.githubusercontent.com/ncponyboy/high-country-outdoors/main/waterfalls.json';

  Future<void> fetchWaterfalls() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final List<dynamic> raw =
            jsonDecode(response.body) as List<dynamic>;
        waterfalls = raw
            .whereType<Map<String, dynamic>>()
            .map(Waterfall.fromJson)
            .toList();
        errorMessage = null;
      } else {
        errorMessage =
            'Failed to load waterfall data (${response.statusCode}).';
      }
    } catch (e) {
      errorMessage = 'Could not reach the server. Check your connection.';
      debugPrint('WaterfallService error: $e');
    }

    // Enrich with live precipitation regardless of source
    await _fetchPrecipitation();

    isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Open-Meteo Precipitation
  // ---------------------------------------------------------------------------

  Future<void> _fetchPrecipitation() async {
    final snapshot = List<Waterfall>.from(waterfalls);

    // Fire all requests in parallel
    final results = await Future.wait(
      snapshot.map((wf) => _fetchPrecip(wf.id, wf.lat, wf.lon)),
    );

    // Apply results
    for (final result in results) {
      final id = result.$1;
      final inches = result.$2;
      final status = result.$3;

      final idx = waterfalls.indexWhere((w) => w.id == id);
      if (idx == -1) continue;

      final wf = waterfalls[idx];
      FlowStatus newFlow = wf.flowStatus;

      // Derive flow status from precip when no USGS gauge
      if (wf.usgsGaugeId == null && status != null) {
        newFlow = _flowStatusFromPrecip(status);
      }

      waterfalls[idx] = wf.copyWith(
        precip7dayIn: inches,
        precipStatus: status,
        flowStatus: newFlow,
      );
    }
  }

  static Future<(String, double?, PrecipStatus?)> _fetchPrecip(
      String id, double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&daily=precipitation_sum'
      '&past_days=7&forecast_days=0'
      '&timezone=America%2FNew_York',
    );

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return (id, null, null);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;
      final precipList = (daily['precipitation_sum'] as List<dynamic>)
          .whereType<num>()
          .toList();

      final totalMm = precipList.fold<double>(0, (s, v) => s + v.toDouble());
      final inches = totalMm * 0.0394; // mm → inches

      PrecipStatus status;
      if (inches < 0.5) {
        status = PrecipStatus.dry;
      } else if (inches < 2.0) {
        status = PrecipStatus.normal;
      } else {
        status = PrecipStatus.wet;
      }

      return (id, inches, status);
    } catch (e) {
      debugPrint('Open-Meteo error for $id: $e');
      return (id, null, null);
    }
  }

  FlowStatus _flowStatusFromPrecip(PrecipStatus precip) {
    switch (precip) {
      case PrecipStatus.dry:
        return FlowStatus.low;
      case PrecipStatus.normal:
        return FlowStatus.normal;
      case PrecipStatus.wet:
        return FlowStatus.high;
    }
  }

  // ---------------------------------------------------------------------------
  // Filtered views
  // ---------------------------------------------------------------------------

  List<Waterfall> byDifficulty(WaterfallDifficulty difficulty) =>
      waterfalls.where((w) => w.difficulty == difficulty).toList();

  List<Waterfall> byCounty(String county) =>
      waterfalls.where((w) => w.county.toLowerCase() == county.toLowerCase()).toList();

  List<Waterfall> withMinHeight(int minFt) =>
      waterfalls.where((w) => (w.heightFt ?? 0) >= minFt).toList();

  List<Waterfall> get closed =>
      waterfalls.where((w) => w.trailClosed).toList();

  List<Waterfall> get flooding =>
      waterfalls.where((w) => w.flowStatus == FlowStatus.flood && !w.trailClosed).toList();

  List<Waterfall> sortedByDistance(double lat, double lng) {
    final sorted = List<Waterfall>.from(waterfalls);
    sorted.sort(
      (a, b) =>
          a.distanceMiles(lat, lng).compareTo(b.distanceMiles(lat, lng)),
    );
    return sorted;
  }

  List<String> get counties =>
      waterfalls.map((w) => w.county).toSet().toList()..sort();
}
