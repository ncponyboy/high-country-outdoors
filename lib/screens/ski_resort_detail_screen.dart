import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ski_resort.dart';

class SkiResortDetailScreen extends StatelessWidget {
  final SkiResort resort;

  const SkiResortDetailScreen({super.key, required this.resort});

  @override
  Widget build(BuildContext context) {
    final trailFraction = resort.totalTrails > 0
        ? (resort.openTrails / resort.totalTrails).clamp(0.0, 1.0)
        : 0.0;
    final liftFraction = resort.totalLifts > 0
        ? (resort.openLifts / resort.totalLifts).clamp(0.0, 1.0)
        : 0.0;

    String baseDepthLabel = '—';
    if (resort.baseDepthLow != null && resort.baseDepthHigh != null) {
      baseDepthLabel = '${resort.baseDepthLow}"–${resort.baseDepthHigh}"';
    } else if (resort.baseDepthLow != null) {
      baseDepthLabel = '${resort.baseDepthLow}"';
    } else if (resort.baseDepthHigh != null) {
      baseDepthLabel = '${resort.baseDepthHigh}"';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0D3A1A),
            foregroundColor: Colors.white,
            title: Text(
              resort.name,
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

              // Status banner
              _StatusBanner(resort: resort),

              const SizedBox(height: 12),

              // Snow stats
              _SectionCard(
                title: 'Snow Report',
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Base Depth',
                      value: baseDepthLabel,
                      icon: Icons.layers_outlined,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _InfoRow(
                      label: 'New Snow (72h)',
                      value: resort.newSnow72h != null
                          ? '${resort.newSnow72h!.toStringAsFixed(1)}"'
                          : '—',
                      icon: Icons.cloudy_snowing,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _InfoRow(
                      label: 'Surface',
                      value: resort.surface ?? '—',
                      icon: Icons.texture,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _InfoRow(
                      label: 'Last Updated',
                      value: resort.lastUpdated.isNotEmpty
                          ? resort.lastUpdated
                          : '—',
                      icon: Icons.access_time,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Trails & Lifts
              _SectionCard(
                title: 'Open Runs & Lifts',
                child: Column(
                  children: [
                    _ProgressSection(
                      label: 'Trails Open',
                      open: resort.openTrails,
                      total: resort.totalTrails,
                      fraction: trailFraction,
                      color: resort.status.color,
                      icon: Icons.downhill_skiing,
                    ),
                    const SizedBox(height: 12),
                    _ProgressSection(
                      label: 'Lifts Open',
                      open: resort.openLifts,
                      total: resort.totalLifts,
                      fraction: liftFraction,
                      color: Colors.blue,
                      icon: Icons.arrow_upward,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Map
              _SectionCard(
                title: 'Location',
                child: _ResortMap(
                  latitude: resort.latitude,
                  longitude: resort.longitude,
                  resortName: resort.name,
                ),
              ),

              const SizedBox(height: 12),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ActionButton(
                      label: 'Get Directions',
                      icon: Icons.directions,
                      color: const Color(0xFF0D3A1A),
                      onTap: () => _launchMaps(
                        resort.latitude,
                        resort.longitude,
                      ),
                    ),
                    if (resort.websiteUrl != null &&
                        resort.websiteUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _ActionButton(
                        label: 'Visit Website',
                        icon: Icons.open_in_new,
                        color: Colors.blue.shade700,
                        onTap: () => _launchUrl(resort.websiteUrl!),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ]),
          ),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// Status Banner
// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  final SkiResort resort;
  const _StatusBanner({required this.resort});

  @override
  Widget build(BuildContext context) {
    final color = resort.status.color;
    return Container(
      width: double.infinity,
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.ac_unit, size: 22, color: color),
          const SizedBox(width: 10),
          Text(
            resort.status.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            resort.region,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress Section
// ---------------------------------------------------------------------------

class _ProgressSection extends StatelessWidget {
  final String label;
  final int open;
  final int total;
  final double fraction;
  final Color color;
  final IconData icon;

  const _ProgressSection({
    required this.label,
    required this.open,
    required this.total,
    required this.fraction,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '$open / $total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _ResortMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String resortName;

  const _ResortMap({
    required this.latitude,
    required this.longitude,
    required this.resortName,
  });

  @override
  State<_ResortMap> createState() => _ResortMapState();
}

class _ResortMapState extends State<_ResortMap> {
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('resort'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(title: widget.resortName),
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
