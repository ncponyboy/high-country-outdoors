import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum WaterfallDifficulty {
  easy,
  moderate,
  strenuous,
  roadside;

  String get label {
    switch (this) {
      case WaterfallDifficulty.easy:
        return 'Easy';
      case WaterfallDifficulty.moderate:
        return 'Moderate';
      case WaterfallDifficulty.strenuous:
        return 'Strenuous';
      case WaterfallDifficulty.roadside:
        return 'Roadside';
    }
  }

  IconData get icon {
    switch (this) {
      case WaterfallDifficulty.easy:
        return Icons.directions_walk;
      case WaterfallDifficulty.moderate:
        return Icons.hiking;
      case WaterfallDifficulty.strenuous:
        return Icons.terrain;
      case WaterfallDifficulty.roadside:
        return Icons.directions_car;
    }
  }

  Color get color {
    switch (this) {
      case WaterfallDifficulty.easy:
        return Colors.green;
      case WaterfallDifficulty.moderate:
        return Colors.blue;
      case WaterfallDifficulty.strenuous:
        return Colors.orange;
      case WaterfallDifficulty.roadside:
        return Colors.grey;
    }
  }

  static WaterfallDifficulty fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'easy':
        return WaterfallDifficulty.easy;
      case 'moderate':
        return WaterfallDifficulty.moderate;
      case 'strenuous':
        return WaterfallDifficulty.strenuous;
      case 'roadside':
        return WaterfallDifficulty.roadside;
      default:
        return WaterfallDifficulty.moderate;
    }
  }
}

enum FlowStatus {
  low,
  normal,
  high,
  flood,
  unknown;

  String get label {
    switch (this) {
      case FlowStatus.low:
        return 'Low Flow';
      case FlowStatus.normal:
        return 'Normal Flow';
      case FlowStatus.high:
        return 'High Flow';
      case FlowStatus.flood:
        return 'Flood Warning';
      case FlowStatus.unknown:
        return 'Flow Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case FlowStatus.low:
        return Icons.water_drop_outlined;
      case FlowStatus.normal:
        return Icons.water_drop;
      case FlowStatus.high:
        return Icons.waves;
      case FlowStatus.flood:
        return Icons.warning_amber;
      case FlowStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (this) {
      case FlowStatus.low:
        return Colors.blue;
      case FlowStatus.normal:
        return Colors.green;
      case FlowStatus.high:
        return Colors.orange;
      case FlowStatus.flood:
        return Colors.red;
      case FlowStatus.unknown:
        return Colors.grey;
    }
  }

  // Google Maps marker hue (0-360)
  double get markerHue {
    switch (this) {
      case FlowStatus.low:
        return 210.0; // blue
      case FlowStatus.normal:
        return 120.0; // green
      case FlowStatus.high:
        return 45.0;  // yellow-orange
      case FlowStatus.flood:
        return 0.0;   // red
      case FlowStatus.unknown:
        return 195.0; // cyan-ish
    }
  }

  static FlowStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return FlowStatus.low;
      case 'normal':
        return FlowStatus.normal;
      case 'high':
        return FlowStatus.high;
      case 'flood':
        return FlowStatus.flood;
      default:
        return FlowStatus.unknown;
    }
  }
}

enum PrecipStatus {
  dry,
  normal,
  wet;

  String get label {
    switch (this) {
      case PrecipStatus.dry:
        return 'Dry Conditions';
      case PrecipStatus.normal:
        return 'Normal Rainfall';
      case PrecipStatus.wet:
        return 'Recent Heavy Rain';
    }
  }

  IconData get icon {
    switch (this) {
      case PrecipStatus.dry:
        return Icons.wb_sunny;
      case PrecipStatus.normal:
        return Icons.grain;
      case PrecipStatus.wet:
        return Icons.umbrella;
    }
  }

  Color get color {
    switch (this) {
      case PrecipStatus.dry:
        return Colors.orange;
      case PrecipStatus.normal:
        return Colors.blue;
      case PrecipStatus.wet:
        return Colors.indigo;
    }
  }

  static PrecipStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'dry':
        return PrecipStatus.dry;
      case 'wet':
        return PrecipStatus.wet;
      default:
        return PrecipStatus.normal;
    }
  }
}

// ---------------------------------------------------------------------------
// Waterfall model
// ---------------------------------------------------------------------------

class Waterfall {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final int? heightFt;
  final double? heightM;
  final WaterfallDifficulty difficulty;
  final double? trailMiles;
  final String county;
  final String state;
  final String? usgsGaugeId;
  final String? npsUnit;
  final String source;
  final int? osmId;
  final String? description;
  final FlowStatus flowStatus;
  final double? flowCfs;
  final double? precip7dayIn;
  final PrecipStatus? precipStatus;
  final bool trailClosed;
  final String? closureDescription;
  final String lastUpdated;

  const Waterfall({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.heightFt,
    this.heightM,
    required this.difficulty,
    this.trailMiles,
    required this.county,
    required this.state,
    this.usgsGaugeId,
    this.npsUnit,
    required this.source,
    this.osmId,
    this.description,
    required this.flowStatus,
    this.flowCfs,
    this.precip7dayIn,
    this.precipStatus,
    required this.trailClosed,
    this.closureDescription,
    required this.lastUpdated,
  });

  // Haversine distance in miles
  double distanceMiles(double userLat, double userLng) {
    const double earthRadiusMiles = 3958.8;
    final double dLat = _toRad(userLat - lat);
    final double dLng = _toRad(userLng - lon);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat)) *
            cos(_toRad(userLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  double _toRad(double deg) => deg * pi / 180.0;

  String? get heightDisplay => heightFt != null ? '$heightFt ft' : null;

  String? get trailDisplay {
    if (trailMiles == null) return null;
    if (trailMiles! < 0.1) return 'Roadside';
    return '${trailMiles!.toStringAsFixed(1)} mi';
  }

  Waterfall copyWith({
    FlowStatus? flowStatus,
    double? flowCfs,
    double? precip7dayIn,
    PrecipStatus? precipStatus,
  }) {
    return Waterfall(
      id: id,
      name: name,
      lat: lat,
      lon: lon,
      heightFt: heightFt,
      heightM: heightM,
      difficulty: difficulty,
      trailMiles: trailMiles,
      county: county,
      state: state,
      usgsGaugeId: usgsGaugeId,
      npsUnit: npsUnit,
      source: source,
      osmId: osmId,
      description: description,
      flowStatus: flowStatus ?? this.flowStatus,
      flowCfs: flowCfs ?? this.flowCfs,
      precip7dayIn: precip7dayIn ?? this.precip7dayIn,
      precipStatus: precipStatus ?? this.precipStatus,
      trailClosed: trailClosed,
      closureDescription: closureDescription,
      lastUpdated: lastUpdated,
    );
  }

  factory Waterfall.fromJson(Map<String, dynamic> json) {
    return Waterfall(
      id:                 (json['id'] ?? '').toString(),
      name:               (json['name'] ?? 'Unknown Falls').toString(),
      lat:                _parseDouble(json['lat']) ?? 36.0,
      lon:                _parseDouble(json['lon']) ?? -82.0,
      heightFt:           _parseInt(json['height_ft']),
      heightM:            _parseDouble(json['height_m']),
      difficulty:         WaterfallDifficulty.fromString(json['difficulty']?.toString()),
      trailMiles:         _parseDouble(json['trail_miles']),
      county:             (json['county'] ?? '').toString(),
      state:              (json['state'] ?? 'NC').toString(),
      usgsGaugeId:        json['usgs_gauge_id']?.toString(),
      npsUnit:            json['nps_unit']?.toString(),
      source:             (json['source'] ?? 'unknown').toString(),
      osmId:              _parseInt(json['osm_id']),
      description:        json['description']?.toString(),
      flowStatus:         FlowStatus.fromString(json['flow_status']?.toString()),
      flowCfs:            _parseDouble(json['flow_cfs']),
      precip7dayIn:       _parseDouble(json['precip_7day_in']),
      precipStatus:       json['precip_status'] != null
                            ? PrecipStatus.fromString(json['precip_status'].toString())
                            : null,
      trailClosed:        json['trail_closed'] == true,
      closureDescription: json['closure_description']?.toString(),
      lastUpdated:        (json['last_updated'] ?? '').toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Parse helpers
// ---------------------------------------------------------------------------

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
