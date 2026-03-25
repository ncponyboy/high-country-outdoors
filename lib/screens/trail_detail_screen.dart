import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trail.dart';
import '../services/store_service.dart';
import 'pro_upgrade_screen.dart';

class TrailDetailScreen extends StatelessWidget {
  final Trail trail;

  const TrailDetailScreen({super.key, required this.trail});

  @override
  Widget build(BuildContext context) {
    final conditions = trail.conditions;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: const Color(0xFF0D3A1A),
            foregroundColor: Colors.white,
            title: Text(
              trail.name,
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
              // Status banner
              _StatusBanner(conditions: conditions),

              const SizedBox(height: 12),

              // Conditions grid
              _SectionCard(
                title: 'Trail Conditions',
                child: _ConditionsGrid(conditions: conditions),
              ),

              const SizedBox(height: 12),

              // Info section
              _SectionCard(
                title: 'Trail Info',
                child: _TrailInfoSection(trail: trail),
              ),

              const SizedBox(height: 12),

              // Map section
              _SectionCard(
                title: 'Trailhead Location',
                child: _TrailMap(
                  latitude: trail.latitude,
                  longitude: trail.longitude,
                  trailName: trail.name,
                ),
              ),

              const SizedBox(height: 12),

              // Alerts section
              if (trail.alerts.isNotEmpty) ...[
                _SectionCard(
                  title: 'Active Alerts',
                  child: _AlertsSection(alerts: trail.alerts),
                ),
                const SizedBox(height: 12),
              ],

              // Get Directions button (Pro only)
              _GetDirectionsButton(trail: trail),

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Banner
// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  final TrailConditions conditions;
  const _StatusBanner({required this.conditions});

  @override
  Widget build(BuildContext context) {
    final color = conditions.status.color;
    final label = conditions.status.label;
    final updated = conditions.lastUpdated.isNotEmpty
        ? 'Updated ${conditions.lastUpdated}'
        : '';

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Spacer(),
          if (updated.isNotEmpty)
            Text(
              updated,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conditions Grid
// ---------------------------------------------------------------------------

class _ConditionsGrid extends StatelessWidget {
  final TrailConditions conditions;
  const _ConditionsGrid({required this.conditions});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ConditionItem(label: 'Surface',         value: conditions.surface         ?? '—', icon: Icons.texture),
      _ConditionItem(label: 'Water Crossings', value: conditions.waterCrossings  ?? '—', icon: Icons.water_outlined),
      _ConditionItem(label: 'Blowdowns',       value: conditions.blowdowns       ?? '—', icon: Icons.forest),
      _ConditionItem(label: 'Snow',            value: conditions.snow            ?? '—', icon: Icons.ac_unit),
      _ConditionItem(label: 'Air Quality',     value: conditions.airQuality      ?? '—', icon: Icons.air),
      _ConditionItem(label: 'Trailhead',       value: conditions.trailheadStatus ?? '—', icon: Icons.local_parking),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      padding: EdgeInsets.zero,
      children: items,
    );
  }
}

class _ConditionItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ConditionItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trail Info Section
// ---------------------------------------------------------------------------

class _TrailInfoSection extends StatelessWidget {
  final Trail trail;
  const _TrailInfoSection({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          label: 'Length',
          value: '${trail.lengthMiles.toStringAsFixed(1)} miles',
          icon: Icons.straighten,
        ),
        const Divider(height: 1, thickness: 1),
        _InfoRow(
          label: 'Elevation Gain',
          value: '${trail.elevationGainFt} ft',
          icon: Icons.show_chart,
        ),
        const Divider(height: 1, thickness: 1),
        _InfoRow(
          label: 'Difficulty',
          value: trail.difficulty.label,
          icon: Icons.speed,
          valueColor: trail.difficulty.color,
        ),
        const Divider(height: 1, thickness: 1),
        _InfoRow(
          label: 'Region',
          value: trail.region.label,
          icon: Icons.map_outlined,
        ),
        const Divider(height: 1, thickness: 1),
        _InfoRow(
          label: 'Park / Forest',
          value: trail.parkForest.isNotEmpty ? trail.parkForest : '—',
          icon: Icons.park_outlined,
        ),
        const Divider(height: 1, thickness: 1),
        _InfoRow(
          label: 'Activities',
          value: trail.activityTypes.map((a) => a.label).join(', '),
          icon: Icons.directions_walk,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trail Map
// ---------------------------------------------------------------------------

class _TrailMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String trailName;

  const _TrailMap({
    required this.latitude,
    required this.longitude,
    required this.trailName,
  });

  @override
  State<_TrailMap> createState() => _TrailMapState();
}

class _TrailMapState extends State<_TrailMap> {
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('trailhead'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(title: widget.trailName),
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
            zoom: 13,
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
// Alerts Section
// ---------------------------------------------------------------------------

class _AlertsSection extends StatelessWidget {
  final List<TrailAlert> alerts;
  const _AlertsSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: alerts.asMap().entries.map((entry) {
        final i = entry.key;
        final alert = entry.value;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    alert.type.icon,
                    size: 20,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alert.message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        if (alert.posted.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Posted: ${alert.posted}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < alerts.length - 1)
              const Divider(height: 1, thickness: 1),
          ],
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Get Directions Button
// ---------------------------------------------------------------------------

class _GetDirectionsButton extends StatelessWidget {
  final Trail trail;
  const _GetDirectionsButton({required this.trail});

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
                    ? 'Get Directions to Trailhead'
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
                  _launchMaps(trail.latitude, trail.longitude, trail.name);
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

  Future<void> _launchMaps(
      double lat, double lng, String label) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$label',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// Section Card helper
// ---------------------------------------------------------------------------

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

