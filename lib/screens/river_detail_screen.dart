import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/river.dart';
import '../services/store_service.dart';
import 'pro_upgrade_screen.dart';

class RiverDetailScreen extends StatelessWidget {
  final River river;

  const RiverDetailScreen({super.key, required this.river});

  @override
  Widget build(BuildContext context) {
    final String cfsLabel =
        river.currentCfs != null ? '${river.currentCfs!.toStringAsFixed(0)} cfs' : '—';
    final String gaugeLabel =
        river.gaugeFt != null ? '${river.gaugeFt!.toStringAsFixed(2)} ft' : '—';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0D3A1A),
            foregroundColor: Colors.white,
            title: Text(
              river.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),

              // Condition hero
              _ConditionHero(river: river),

              const SizedBox(height: 12),

              // Live flow data (only shown when USGS data is available)
              if (river.currentCfs != null || river.gaugeFt != null)
                _SectionCard(
                  title: 'Live Flow Data',
                  child: Column(
                    children: [
                      if (river.currentCfs != null) ...[
                        _InfoRow(
                          label: 'Current Flow',
                          value: '${river.currentCfs!.toStringAsFixed(0)} cfs',
                          icon: Icons.water_drop_outlined,
                        ),
                        const Divider(height: 1, thickness: 1),
                      ],
                      if (river.gaugeFt != null) ...[
                        _InfoRow(
                          label: 'Gauge Height',
                          value: '${river.gaugeFt!.toStringAsFixed(2)} ft',
                          icon: Icons.straighten,
                        ),
                        const Divider(height: 1, thickness: 1),
                      ],
                      _TrendRow(river: river),
                      if (river.lastUpdated.isNotEmpty) ...[
                        const Divider(height: 1, thickness: 1),
                        _InfoRow(
                          label: 'Last Updated',
                          value: river.lastUpdated,
                          icon: Icons.access_time,
                        ),
                      ],
                    ],
                  ),
                ),

              // No live data yet — show a note
              if (river.currentCfs == null && river.gaugeFt == null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue.shade400),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live flow data coming soon. USGS gauge readings will update hourly.',
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // River info
              _SectionCard(
                title: 'River Info',
                child: Column(
                  children: [
                    if (river.difficulty != null) ...[
                      _InfoRow(
                        label: 'Difficulty',
                        value: river.difficulty!,
                        icon: Icons.waves,
                      ),
                      const Divider(height: 1, thickness: 1),
                    ],
                    _InfoRow(
                      label: 'Region',
                      value: river.region,
                      icon: Icons.map_outlined,
                    ),
                    if (river.activities.isNotEmpty) ...[
                      const Divider(height: 1, thickness: 1),
                      _InfoRow(
                        label: 'Activities',
                        value: river.activities
                            .map((a) => a[0].toUpperCase() + a.substring(1))
                            .join(', '),
                        icon: Icons.kayaking,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Description
              if (river.description.isNotEmpty)
                _SectionCard(
                  title: 'About',
                  child: Text(
                    river.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),

              if (river.description.isNotEmpty) const SizedBox(height: 12),

              // Put-ins
              if (river.putIns.isNotEmpty)
                _SectionCard(
                  title: 'Put-in Locations',
                  child: Column(
                    children: river.putIns.asMap().entries.map((entry) {
                      final i = entry.key;
                      final putIn = entry.value;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.launch,
                                  size: 18,
                                  color: Colors.blue.shade400,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    putIn,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i < river.putIns.length - 1)
                            const Divider(height: 1, thickness: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              if (river.putIns.isNotEmpty) const SizedBox(height: 12),

              // Map
              _SectionCard(
                title: 'Location',
                child: _RiverMap(
                  latitude: river.latitude,
                  longitude: river.longitude,
                  riverName: river.name,
                  accessPoints: river.accessPoints,
                ),
              ),

              const SizedBox(height: 12),

              // Access Points
              if (river.accessPoints.isNotEmpty) ...[
                _AccessPointsSection(accessPoints: river.accessPoints),
                const SizedBox(height: 12),
              ],

              // Get directions to put-in (Pro)
              _GetDirectionsButton(river: river),

              const SizedBox(height: 10),

              // Visit website
              if (river.websiteUrl != null)
                _VisitWebsiteButton(url: river.websiteUrl!),

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Condition Hero
// ---------------------------------------------------------------------------

class _ConditionHero extends StatelessWidget {
  final River river;
  const _ConditionHero({required this.river});

  @override
  Widget build(BuildContext context) {
    final bool hasCondition = river.condition != RiverCondition.unknown;
    final color = hasCondition ? river.condition.color : Colors.blue.shade400;
    final label = hasCondition
        ? river.condition.label.toUpperCase()
        : 'GAUGE DATA ONLY';

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 28, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: hasCondition ? 26 : 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend Row
// ---------------------------------------------------------------------------

class _TrendRow extends StatelessWidget {
  final River river;
  const _TrendRow({required this.river});

  @override
  Widget build(BuildContext context) {
    if (river.trend == RiverTrend.unknown) return const SizedBox.shrink();

    final Color trendColor = _trendColor(river.trend);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            'Trend',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Icon(river.trend.icon, size: 20, color: trendColor),
          const SizedBox(width: 4),
          Text(
            river.trend.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _trendColor(RiverTrend trend) {
    switch (trend) {
      case RiverTrend.rising:
        return Colors.orange;
      case RiverTrend.falling:
        return Colors.blue;
      case RiverTrend.steady:
        return Colors.green;
      case RiverTrend.unknown:
        return Colors.grey;
    }
  }
}

// ---------------------------------------------------------------------------
// Get Directions Button
// ---------------------------------------------------------------------------

class _GetDirectionsButton extends StatelessWidget {
  final River river;
  const _GetDirectionsButton({required this.river});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreService>(
      builder: (context, storeSvc, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                storeSvc.isPro ? Icons.directions : Icons.lock_outline,
              ),
              label: Text(
                storeSvc.isPro
                    ? 'Get Directions to Put-in'
                    : 'Get Directions (Pro)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: storeSvc.isPro
                    ? const Color(0xFF0D3A1A)
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (storeSvc.isPro) {
                  _launchMaps(river.latitude, river.longitude);
                } else {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ProUpgradeScreen(),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------

class _RiverMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String riverName;
  final List<AccessPoint> accessPoints;

  const _RiverMap({
    required this.latitude,
    required this.longitude,
    required this.riverName,
    this.accessPoints = const [],
  });

  @override
  State<_RiverMap> createState() => _RiverMapState();
}

class _RiverMapState extends State<_RiverMap> {
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('river'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(title: widget.riverName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      ...widget.accessPoints.map(
        (point) => Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.latitude, point.longitude),
          infoWindow: InfoWindow(
            title: point.name,
            snippet: point.type.label,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(point.type.markerHue),
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 200,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.latitude, widget.longitude),
            zoom: 12,
          ),
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Access Points Section
// ---------------------------------------------------------------------------

class _AccessPointsSection extends StatelessWidget {
  final List<AccessPoint> accessPoints;
  const _AccessPointsSection({required this.accessPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACCESS POINTS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...accessPoints.asMap().entries.map((entry) {
              final i = entry.key;
              final point = entry.value;
              return Column(
                children: [
                  _AccessPointRow(point: point),
                  if (i < accessPoints.length - 1)
                    const Divider(height: 1, thickness: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AccessPointRow extends StatelessWidget {
  final AccessPoint point;
  const _AccessPointRow({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: point.type.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(point.type.icon, size: 18, color: point.type.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      point.type.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: point.type.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.directions, color: point.type.color),
                onPressed: () => _launchMaps(point.latitude, point.longitude),
                tooltip: 'Get Directions',
              ),
            ],
          ),
          if (point.description != null && point.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text(
                point.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ],
          if (point.notes != null && point.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      point.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// Visit Website Button
// ---------------------------------------------------------------------------

class _VisitWebsiteButton extends StatelessWidget {
  final String url;
  const _VisitWebsiteButton({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Visit Website'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0D3A1A),
            side: const BorderSide(color: Color(0xFF0D3A1A)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
