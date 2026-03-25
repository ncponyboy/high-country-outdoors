import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum TrailRegion {
  highCountryNC,
  easternTN,
  swVirginia;

  String get label {
    switch (this) {
      case TrailRegion.highCountryNC:
        return 'High Country NC';
      case TrailRegion.easternTN:
        return 'Eastern TN';
      case TrailRegion.swVirginia:
        return 'SW Virginia';
    }
  }

  static TrailRegion fromString(String? value) {
    switch (value) {
      case 'highCountryNC':
      case 'high_country_nc':
        return TrailRegion.highCountryNC;
      case 'easternTN':
      case 'eastern_tn':
        return TrailRegion.easternTN;
      case 'swVirginia':
      case 'sw_virginia':
        return TrailRegion.swVirginia;
      default:
        return TrailRegion.highCountryNC;
    }
  }
}

enum TrailDifficulty {
  easy,
  moderate,
  hard,
  expert;

  String get label {
    switch (this) {
      case TrailDifficulty.easy:
        return 'Easy';
      case TrailDifficulty.moderate:
        return 'Moderate';
      case TrailDifficulty.hard:
        return 'Hard';
      case TrailDifficulty.expert:
        return 'Expert';
    }
  }

  Color get color {
    switch (this) {
      case TrailDifficulty.easy:
        return Colors.green;
      case TrailDifficulty.moderate:
        return Colors.blue;
      case TrailDifficulty.hard:
        return Colors.orange;
      case TrailDifficulty.expert:
        return Colors.red;
    }
  }

  static TrailDifficulty fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'easy':
        return TrailDifficulty.easy;
      case 'moderate':
        return TrailDifficulty.moderate;
      case 'hard':
        return TrailDifficulty.hard;
      case 'expert':
        return TrailDifficulty.expert;
      default:
        return TrailDifficulty.moderate;
    }
  }
}

enum ActivityType {
  hiking,
  running,
  biking,
  skiing,
  climbing,
  horsebackRiding,
  backpacking,
  fishing,
  other;

  IconData get icon {
    switch (this) {
      case ActivityType.hiking:
        return Icons.hiking;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.biking:
        return Icons.directions_bike;
      case ActivityType.skiing:
        return Icons.downhill_skiing;
      case ActivityType.climbing:
        return Icons.terrain;
      case ActivityType.horsebackRiding:
        return Icons.emoji_nature;
      case ActivityType.backpacking:
        return Icons.backpack;
      case ActivityType.fishing:
        return Icons.set_meal;
      case ActivityType.other:
        return Icons.more_horiz;
    }
  }

  String get label {
    switch (this) {
      case ActivityType.hiking:
        return 'Hiking';
      case ActivityType.running:
        return 'Running';
      case ActivityType.biking:
        return 'Biking';
      case ActivityType.skiing:
        return 'Skiing';
      case ActivityType.climbing:
        return 'Climbing';
      case ActivityType.horsebackRiding:
        return 'Horseback Riding';
      case ActivityType.backpacking:
        return 'Backpacking';
      case ActivityType.fishing:
        return 'Fishing';
      case ActivityType.other:
        return 'Other';
    }
  }

  static ActivityType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'hiking':
        return ActivityType.hiking;
      case 'running':
        return ActivityType.running;
      case 'biking':
      case 'mtb':
      case 'mountain_biking':
      case 'mountain biking':
        return ActivityType.biking;
      case 'skiing':
        return ActivityType.skiing;
      case 'climbing':
        return ActivityType.climbing;
      case 'horseback_riding':
      case 'horseback riding':
      case 'horsebackriding':
        return ActivityType.horsebackRiding;
      case 'backpacking':
        return ActivityType.backpacking;
      case 'fishing':
        return ActivityType.fishing;
      default:
        return ActivityType.other;
    }
  }
}

enum TrailConditionStatus {
  open,
  caution,
  closed;

  Color get color {
    switch (this) {
      case TrailConditionStatus.open:
        return Colors.green;
      case TrailConditionStatus.caution:
        return Colors.orange;
      case TrailConditionStatus.closed:
        return Colors.red;
    }
  }

  String get label {
    switch (this) {
      case TrailConditionStatus.open:
        return 'OPEN';
      case TrailConditionStatus.caution:
        return 'CAUTION';
      case TrailConditionStatus.closed:
        return 'CLOSED';
    }
  }

  static TrailConditionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'open':
        return TrailConditionStatus.open;
      case 'caution':
        return TrailConditionStatus.caution;
      case 'closed':
        return TrailConditionStatus.closed;
      default:
        return TrailConditionStatus.open;
    }
  }
}

enum AlertType {
  closure,
  fire,
  flood,
  bearActivity,
  other;

  IconData get icon {
    switch (this) {
      case AlertType.closure:
        return Icons.block;
      case AlertType.fire:
        return Icons.local_fire_department;
      case AlertType.flood:
        return Icons.water;
      case AlertType.bearActivity:
        return Icons.pets;
      case AlertType.other:
        return Icons.warning_amber;
    }
  }

  String get label {
    switch (this) {
      case AlertType.closure:
        return 'Closure';
      case AlertType.fire:
        return 'Fire';
      case AlertType.flood:
        return 'Flood';
      case AlertType.bearActivity:
        return 'Bear Activity';
      case AlertType.other:
        return 'Alert';
    }
  }

  static AlertType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'closure':
        return AlertType.closure;
      case 'fire':
        return AlertType.fire;
      case 'flood':
        return AlertType.flood;
      case 'bear_activity':
      case 'bearactivity':
      case 'bear':
        return AlertType.bearActivity;
      default:
        return AlertType.other;
    }
  }
}

// ---------------------------------------------------------------------------
// TrailAlert
// ---------------------------------------------------------------------------

class TrailAlert {
  final String id;
  final AlertType type;
  final String message;
  final String posted;

  const TrailAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.posted,
  });

  factory TrailAlert.fromJson(Map<String, dynamic> json) {
    return TrailAlert(
      id: (json['id'] ?? '').toString(),
      type: AlertType.fromString(json['type'] as String?),
      message: (json['message'] ?? '') as String,
      posted: (json['posted'] ?? '') as String,
    );
  }
}

// ---------------------------------------------------------------------------
// TrailConditions
// ---------------------------------------------------------------------------

class TrailConditions {
  final TrailConditionStatus status;
  final String? surface;
  final String? waterCrossings;
  final String? blowdowns;
  final String? snow;
  final String? airQuality;
  final String? trailheadStatus;
  final String lastUpdated;

  const TrailConditions({
    required this.status,
    this.surface,
    this.waterCrossings,
    this.blowdowns,
    this.snow,
    this.airQuality,
    this.trailheadStatus,
    required this.lastUpdated,
  });

  static String? _str(dynamic v) {
    if (v == null || v == '') return null;
    if (v == false) return 'None';      // JSON boolean false = none/clear
    if (v == true) return 'Reported';   // JSON boolean true = reported
    final s = v.toString();
    // Capitalize first letter for display
    if (s.isEmpty) return null;
    return s[0].toUpperCase() + s.substring(1);
  }

  factory TrailConditions.fromJson(Map<String, dynamic> json) {
    return TrailConditions(
      status: TrailConditionStatus.fromString(json['status']?.toString()),
      surface: _str(json['surface']),
      waterCrossings: _str(json['water_crossings']),
      blowdowns: _str(json['blowdowns']),
      snow: _str(json['snow_level'] ?? json['snow']) ?? 'None',  // default: None
      airQuality: _str(json['air_quality']) ?? 'Good',          // default: Good
      trailheadStatus: _str(json['trailhead_access'] ?? json['trailhead_status']) ?? 'Open',
      lastUpdated: (json['last_updated'] ?? '').toString(),
    );
  }

  factory TrailConditions.empty() {
    return const TrailConditions(
      status: TrailConditionStatus.open,
      lastUpdated: '',
    );
  }
}

// ---------------------------------------------------------------------------
// Trail
// ---------------------------------------------------------------------------

class Trail {
  final String id;
  final String name;
  final TrailRegion region;
  final String parkForest;
  final double latitude;
  final double longitude;
  final TrailDifficulty difficulty;
  final double lengthMiles;
  final int elevationGainFt;
  final List<ActivityType> activityTypes;
  final TrailConditions conditions;
  final List<TrailAlert> alerts;

  const Trail({
    required this.id,
    required this.name,
    required this.region,
    required this.parkForest,
    required this.latitude,
    required this.longitude,
    required this.difficulty,
    required this.lengthMiles,
    required this.elevationGainFt,
    required this.activityTypes,
    required this.conditions,
    required this.alerts,
  });

  /// Haversine formula — returns distance in miles.
  double distanceMiles(double lat, double lng) {
    const double earthRadiusMiles = 3958.8;
    final double dLat = _toRad(lat - latitude);
    final double dLng = _toRad(lng - longitude);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(latitude)) *
            cos(_toRad(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  double _toRad(double deg) => deg * pi / 180.0;

  factory Trail.fromJson(Map<String, dynamic> json) {
    // Parse activity types
    final rawActivities = json['activity_types'];
    List<ActivityType> activities = [];
    if (rawActivities is List) {
      activities = rawActivities
          .map((e) => ActivityType.fromString(e?.toString()))
          .toList();
    }

    // Parse alerts
    final rawAlerts = json['alerts'];
    List<TrailAlert> alerts = [];
    if (rawAlerts is List) {
      alerts = rawAlerts
          .whereType<Map<String, dynamic>>()
          .map(TrailAlert.fromJson)
          .toList();
    }

    // Parse conditions — trailhead_access lives at trail level in this JSON schema,
    // so inject it into the conditions map before parsing.
    TrailConditions conditions;
    final rawConditions = json['conditions'];
    if (rawConditions is Map<String, dynamic>) {
      final condMap = Map<String, dynamic>.from(rawConditions);
      condMap['trailhead_access'] ??= json['trailhead_access'];
      conditions = TrailConditions.fromJson(condMap);
    } else {
      conditions = TrailConditions.empty();
    }

    return Trail(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown Trail') as String,
      region: TrailRegion.fromString(json['region'] as String?),
      parkForest: (json['park'] ?? json['park_forest'] ?? '') as String,
      latitude: _parseDouble(json['latitude']) ?? 36.0,
      longitude: _parseDouble(json['longitude']) ?? -82.0,
      difficulty: TrailDifficulty.fromString(json['difficulty'] as String?),
      lengthMiles: _parseDouble(json['length_miles']) ?? 0.0,
      elevationGainFt: _parseInt(json['elevation_gain_ft']) ?? 0,
      activityTypes: activities.isEmpty ? [ActivityType.hiking] : activities,
      conditions: conditions,
      alerts: alerts,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
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
