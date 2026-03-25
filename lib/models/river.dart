import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Access Point
// ---------------------------------------------------------------------------

enum AccessPointType {
  kayak,
  swimming,
  fishing;

  String get label {
    switch (this) {
      case AccessPointType.kayak:    return 'Kayak / Canoe';
      case AccessPointType.swimming: return 'Swimming / Wading';
      case AccessPointType.fishing:  return 'Fishing';
    }
  }

  IconData get icon {
    switch (this) {
      case AccessPointType.kayak:    return Icons.kayaking;
      case AccessPointType.swimming: return Icons.pool;
      case AccessPointType.fishing:  return Icons.phishing;
    }
  }

  Color get color {
    switch (this) {
      case AccessPointType.kayak:    return Colors.blue;
      case AccessPointType.swimming: return Colors.teal;
      case AccessPointType.fishing:  return Colors.green;
    }
  }

  double get markerHue {
    switch (this) {
      case AccessPointType.kayak:    return 210.0;
      case AccessPointType.swimming: return 180.0;
      case AccessPointType.fishing:  return 120.0;
    }
  }

  static AccessPointType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'kayak':    return AccessPointType.kayak;
      case 'swimming': return AccessPointType.swimming;
      case 'fishing':  return AccessPointType.fishing;
      default:         return AccessPointType.kayak;
    }
  }
}

class AccessPoint {
  final String id;
  final String name;
  final AccessPointType type;
  final double latitude;
  final double longitude;
  final String? description;
  final String? notes;

  const AccessPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.description,
    this.notes,
  });

  factory AccessPoint.fromJson(Map<String, dynamic> json) {
    return AccessPoint(
      id:          (json['id'] ?? '').toString(),
      name:        (json['name'] ?? '').toString(),
      type:        AccessPointType.fromString(json['type'] as String?),
      latitude:    _parseDouble(json['latitude']) ?? 36.0,
      longitude:   _parseDouble(json['longitude']) ?? -82.0,
      description: json['description'] as String?,
      notes:       json['notes'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum RiverTrend {
  rising,
  falling,
  steady,
  unknown;

  IconData get icon {
    switch (this) {
      case RiverTrend.rising:
        return Icons.trending_up;
      case RiverTrend.falling:
        return Icons.trending_down;
      case RiverTrend.steady:
        return Icons.trending_flat;
      case RiverTrend.unknown:
        return Icons.remove;
    }
  }

  String get label {
    switch (this) {
      case RiverTrend.rising:
        return 'Rising';
      case RiverTrend.falling:
        return 'Falling';
      case RiverTrend.steady:
        return 'Steady';
      case RiverTrend.unknown:
        return 'Unknown';
    }
  }

  static RiverTrend fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'rising':
        return RiverTrend.rising;
      case 'falling':
        return RiverTrend.falling;
      case 'steady':
        return RiverTrend.steady;
      default:
        return RiverTrend.unknown;
    }
  }
}

enum RiverCondition {
  low,
  optimal,
  high,
  flood,
  unknown;

  Color get color {
    switch (this) {
      case RiverCondition.low:
        return Colors.grey;
      case RiverCondition.optimal:
        return Colors.green;
      case RiverCondition.high:
        return Colors.orange;
      case RiverCondition.flood:
        return Colors.red;
      case RiverCondition.unknown:
        return Colors.grey;
    }
  }

  String get label {
    switch (this) {
      case RiverCondition.low:
        return 'Low';
      case RiverCondition.optimal:
        return 'Optimal';
      case RiverCondition.high:
        return 'High';
      case RiverCondition.flood:
        return 'Flood';
      case RiverCondition.unknown:
        return 'Unknown';
    }
  }

  static RiverCondition fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return RiverCondition.low;
      case 'optimal':
        return RiverCondition.optimal;
      case 'high':
        return RiverCondition.high;
      case 'flood':
        return RiverCondition.flood;
      default:
        return RiverCondition.unknown;
    }
  }
}

// ---------------------------------------------------------------------------
// River
// ---------------------------------------------------------------------------

class River {
  final String id;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final double? currentCfs;
  final double? gaugeFt;
  final RiverTrend trend;
  final RiverCondition condition;
  final String lastUpdated;
  final String description;
  final List<String> putIns;
  final String? difficulty;
  final String? websiteUrl;
  final List<String> activities;
  final List<AccessPoint> accessPoints;

  const River({
    required this.id,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.currentCfs,
    this.gaugeFt,
    required this.trend,
    required this.condition,
    required this.lastUpdated,
    required this.description,
    required this.putIns,
    this.difficulty,
    this.websiteUrl,
    this.activities = const [],
    this.accessPoints = const [],
  });

  factory River.fromJson(Map<String, dynamic> json) {
    // Support both 'put_ins' (list) and 'put_in' (single string)
    List<String> putIns = [];
    final rawPutIns = json['put_ins'];
    final rawPutIn = json['put_in'];
    if (rawPutIns is List) {
      putIns = rawPutIns.map((e) => e?.toString() ?? '').toList();
    } else if (rawPutIn != null) {
      putIns = [rawPutIn.toString()];
    }

    // Activities list
    final rawActivities = json['activities'];
    List<String> activities = [];
    if (rawActivities is List) {
      activities = rawActivities.map((e) => e?.toString() ?? '').toList();
    }

    // Access points
    final rawAccessPoints = json['access_points'];
    List<AccessPoint> accessPoints = [];
    if (rawAccessPoints is List) {
      accessPoints = rawAccessPoints
          .whereType<Map<String, dynamic>>()
          .map((e) => AccessPoint.fromJson(e))
          .toList();
    }

    return River(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown River') as String,
      region: (json['region'] ?? '') as String,
      latitude: _parseDouble(json['latitude']) ?? 36.0,
      longitude: _parseDouble(json['longitude']) ?? -82.0,
      currentCfs: _parseDouble(json['current_cfs']),
      gaugeFt: _parseDouble(json['gauge_ft']),
      trend: RiverTrend.fromString(json['trend'] as String?),
      condition: RiverCondition.fromString(json['condition'] as String?),
      lastUpdated: (json['last_updated'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      putIns: putIns,
      difficulty: json['difficulty'] as String?,
      websiteUrl: json['website_url'] as String?,
      activities: activities,
      accessPoints: accessPoints,
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
