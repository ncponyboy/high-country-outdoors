import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum SkiResortStatus {
  open,
  closed;

  Color get color {
    switch (this) {
      case SkiResortStatus.open:
        return Colors.green;
      case SkiResortStatus.closed:
        return Colors.red;
    }
  }

  String get label {
    switch (this) {
      case SkiResortStatus.open:
        return 'OPEN';
      case SkiResortStatus.closed:
        return 'CLOSED';
    }
  }

  static SkiResortStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'open':
        return SkiResortStatus.open;
      default:
        return SkiResortStatus.closed;
    }
  }
}

// ---------------------------------------------------------------------------
// SkiResort
// ---------------------------------------------------------------------------

class SkiResort {
  final String id;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final SkiResortStatus status;
  final int? baseDepthLow;
  final int? baseDepthHigh;
  final double? newSnow72h;
  final int openTrails;
  final int totalTrails;
  final int openLifts;
  final int totalLifts;
  final String? surface;
  final String lastUpdated;
  final String? websiteUrl;

  const SkiResort({
    required this.id,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.baseDepthLow,
    this.baseDepthHigh,
    this.newSnow72h,
    required this.openTrails,
    required this.totalTrails,
    required this.openLifts,
    required this.totalLifts,
    this.surface,
    required this.lastUpdated,
    this.websiteUrl,
  });

  factory SkiResort.fromJson(Map<String, dynamic> json) {
    return SkiResort(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown Resort') as String,
      region: (json['region'] ?? '') as String,
      latitude: _parseDouble(json['latitude']) ?? 36.0,
      longitude: _parseDouble(json['longitude']) ?? -82.0,
      status: SkiResortStatus.fromString(json['status'] as String?),
      baseDepthLow: _parseInt(json['base_depth_low']),
      baseDepthHigh: _parseInt(json['base_depth_high']),
      newSnow72h: _parseDouble(json['new_snow_72h']),
      openTrails: _parseInt(json['open_trails']) ?? 0,
      totalTrails: _parseInt(json['total_trails']) ?? 0,
      openLifts: _parseInt(json['open_lifts']) ?? 0,
      totalLifts: _parseInt(json['total_lifts']) ?? 0,
      surface: json['surface'] as String?,
      lastUpdated: (json['last_updated'] ?? '') as String,
      websiteUrl: json['website_url'] as String?,
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
