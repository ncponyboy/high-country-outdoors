import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/waterfall.dart';
import '../services/store_service.dart';
import 'pro_upgrade_screen.dart';

class WaterfallDetailScreen extends StatelessWidget {
  final Waterfall waterfall;

  const WaterfallDetailScreen({super.key, required this.waterfall});

  @override
  Widget build(BuildContext context) {
    final storeSvc = context.watch<StoreService>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0D3A1A),
            foregroundColor: Colors.white,
            title: Text(
              waterfall.name,
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
              _StatusBanner(waterfall: waterfall),

              const SizedBox(height: 12),

              // Stats card
              _SectionCard(
                title: 'Waterfall Info',
                child: _StatsSection(waterfall: waterfall),
              ),

              const SizedBox(height: 12),

              // Flow card
              _SectionCard(
                title: 'Stream Flow',
                child: _FlowSection(waterfall: waterfall),
              ),

              const SizedBox(height: 12),

              // Closure card (only if closed)
              if (waterfall.trailClosed) ...[
                _SectionCard(
                  title: 'Trail Closure',
                  child: _ClosureSection(
                    waterfall: waterfall,
                    isPro: storeSvc.isPro,
                    onUpgradeTap: () => _showProUpgrade(context),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Precipitation card (Pro)
              _SectionCard(
                title: '7-Day Precipitation',
                child: _PrecipSection(
                  waterfall: waterfall,
                  isPro: storeSvc.isPro,
                  onUpgradeTap: () => _showProUpgrade(context),
                ),
              ),

              const SizedBox(height: 12),

              // Description
              if (waterfall.description != null &&
                  waterfall.description!.isNotEmpty) ...[
                _SectionCard(
                  title: 'About',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      waterfall.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Map card
              _SectionCard(
                title: 'Location',
                child: _WaterfallMap(waterfall: waterfall),
              ),

              const SizedBox(height: 12),

              // Last updated footer
              _LastUpdatedFooter(waterfall: waterfall),

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  void _showProUpgrade(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProUpgradeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Banner
// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  final Waterfall waterfall;
  const _StatusBanner({required this.waterfall});

  @override
  Widget build(BuildContext context) {
    final Color color = waterfall.trailClosed
        ? Colors.red
        : waterfall.flowStatus.color;
    final String label = waterfall.trailClosed
        ? 'Trail Closed'
        : waterfall.flowStatus.label;
    final IconData icon = waterfall.trailClosed
        ? Icons.block
        : waterfall.flowStatus.icon;

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (waterfall.flowCfs != null) ...[
            const Spacer(),
            Text(
              '${waterfall.flowCfs!.toStringAsFixed(0)} CFS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats Section
// ---------------------------------------------------------------------------

class _StatsSection extends StatelessWidget {
  final Waterfall waterfall;
  const _StatsSection({required this.waterfall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _StatItem(
                icon: Icons.water,
                label: 'Height',
                value: waterfall.heightDisplay ?? '—',
              ),
              _StatItem(
                icon: waterfall.difficulty.icon,
                label: 'Difficulty',
                value: waterfall.difficulty.label,
                valueColor: waterfall.difficulty.color,
              ),
              _StatItem(
                icon: Icons.straighten,
                label: 'Trail',
                value: waterfall.trailDisplay ?? '—',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(
                icon: Icons.location_on_outlined,
                label: 'County',
                value: '${waterfall.county}, ${waterfall.state}',
              ),
              _StatItem(
                icon: Icons.source_outlined,
                label: 'Source',
                value: waterfall.source.toUpperCase(),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
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
// Flow Section
// ---------------------------------------------------------------------------

class _FlowSection extends StatelessWidget {
  final Waterfall waterfall;
  const _FlowSection({required this.waterfall});

  @override
  Widget build(BuildContext context) {
    final color = waterfall.flowStatus.color;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(waterfall.flowStatus.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waterfall.flowStatus.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  waterfall.flowCfs != null
                      ? '${waterfall.flowCfs!.toStringAsFixed(0)} CFS via USGS gauge'
                      : waterfall.usgsGaugeId != null
                          ? 'USGS gauge data unavailable'
                          : 'No USGS gauge — based on nearby precipitation',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
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
// Closure Section
// ---------------------------------------------------------------------------

class _ClosureSection extends StatelessWidget {
  final Waterfall waterfall;
  final bool isPro;
  final VoidCallback onUpgradeTap;

  const _ClosureSection({
    required this.waterfall,
    required this.isPro,
    required this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block, color: Colors.red.shade700, size: 18),
              const SizedBox(width: 8),
              const Text(
                'This trail is currently closed.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isPro && waterfall.closureDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              waterfall.closureDescription!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ] else if (!isPro) ...[
            const SizedBox(height: 10),
            _ProGateRow(
              message: 'Full closure details require Pro',
              onTap: onUpgradeTap,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Precipitation Section
// ---------------------------------------------------------------------------

class _PrecipSection extends StatelessWidget {
  final Waterfall waterfall;
  final bool isPro;
  final VoidCallback onUpgradeTap;

  const _PrecipSection({
    required this.waterfall,
    required this.isPro,
    required this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPro) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _ProGateRow(
          message: 'Recent rainfall indicator — upgrade to Pro',
          onTap: onUpgradeTap,
        ),
      );
    }

    final precip = waterfall.precipStatus;
    if (precip == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Precipitation data unavailable.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      );
    }

    final color = precip.color;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(precip.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  precip.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (waterfall.precip7dayIn != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${waterfall.precip7dayIn!.toStringAsFixed(2)}" over the past 7 days',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------

class _WaterfallMap extends StatelessWidget {
  final Waterfall waterfall;
  const _WaterfallMap({required this.waterfall});

  @override
  Widget build(BuildContext context) {
    final position = LatLng(waterfall.lat, waterfall.lon);
    return SizedBox(
      height: 200,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: position,
          zoom: 13.5,
        ),
        markers: {
          Marker(
            markerId: MarkerId(waterfall.id),
            position: position,
            infoWindow: InfoWindow(title: waterfall.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              waterfall.trailClosed
                  ? BitmapDescriptor.hueRed
                  : waterfall.flowStatus.markerHue,
            ),
          ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Last Updated Footer
// ---------------------------------------------------------------------------

class _LastUpdatedFooter extends StatelessWidget {
  final Waterfall waterfall;
  const _LastUpdatedFooter({required this.waterfall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Updated: ${waterfall.lastUpdated}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            waterfall.source.toUpperCase(),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D3A1A),
                letterSpacing: 0.3,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ProGateRow extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  const _ProGateRow({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
