import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/waterfall.dart';
import '../services/waterfall_service.dart';
import '../services/location_service.dart';
import '../services/store_service.dart';
import '../widgets/waterfall_row.dart';
import 'waterfall_detail_screen.dart';
import 'pro_upgrade_screen.dart';

// NC High Country center
const _kInitialCamera = CameraPosition(
  target: LatLng(36.05, -81.70),
  zoom: 8.5,
);

enum _ViewMode { map, list }

class WaterfallsScreen extends StatefulWidget {
  const WaterfallsScreen({super.key});

  @override
  State<WaterfallsScreen> createState() => _WaterfallsScreenState();
}

class _WaterfallsScreenState extends State<WaterfallsScreen> {
  _ViewMode _viewMode = _ViewMode.list;

  // Pro filters
  WaterfallDifficulty? _selectedDifficulty;
  String? _selectedCounty;
  int _minHeightFt = 0;

  GoogleMapController? _mapController;

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  List<Waterfall> _filtered(WaterfallService svc, StoreService storeSvc) {
    var result = svc.waterfalls;
    if (storeSvc.isPro) {
      if (_selectedDifficulty != null) {
        result = result.where((w) => w.difficulty == _selectedDifficulty).toList();
      }
      if (_selectedCounty != null) {
        result = result.where((w) => w.county == _selectedCounty).toList();
      }
      if (_minHeightFt > 0) {
        result = result.where((w) => (w.heightFt ?? 0) >= _minHeightFt).toList();
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer3<WaterfallService, LocationService, StoreService>(
      builder: (context, waterfallSvc, locationSvc, storeSvc, _) {
        final filtered = _filtered(waterfallSvc, storeSvc);

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: Column(
            children: [
              _buildAppBar(context, waterfallSvc, storeSvc, filtered.length),
              if (storeSvc.isPro) _buildFilterBar(waterfallSvc, storeSvc),
              Expanded(
                child: _buildContent(
                  waterfallSvc, locationSvc, storeSvc, filtered),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(
    BuildContext context,
    WaterfallService svc,
    StoreService storeSvc,
    int count,
  ) {
    return Container(
      color: const Color(0xFF0D3A1A),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              // Title + count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Waterfalls',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (svc.waterfalls.isNotEmpty)
                      Text(
                        '$count fall${count == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Map/List toggle
              _ViewToggle(
                current: _viewMode,
                onChanged: (mode) => setState(() => _viewMode = mode),
              ),

              // Refresh
              IconButton(
                icon: svc.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                onPressed:
                    svc.isLoading ? null : () => svc.fetchWaterfalls(),
              ),

              // Pro badge
              if (!storeSvc.isPro)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton(
                    onPressed: () => _showProUpgrade(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      'Go Pro',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter bar (Pro only)
  // ---------------------------------------------------------------------------

  Widget _buildFilterBar(WaterfallService svc, StoreService storeSvc) {
    return Container(
      color: const Color(0xFF0D3A1A),
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // Difficulty
          _DropdownPill<WaterfallDifficulty>(
            label: _selectedDifficulty?.label ?? 'Difficulty',
            isActive: _selectedDifficulty != null,
            items: WaterfallDifficulty.values
                .map((d) => PopupMenuItem(value: d, child: Text(d.label)))
                .toList()
              ..insert(
                  0,
                  const PopupMenuItem(
                      value: null, child: Text('All Difficulty'))),
            onSelected: (v) => setState(() => _selectedDifficulty = v),
          ),
          const SizedBox(width: 8),

          // County
          _DropdownPill<String>(
            label: _selectedCounty ?? 'County',
            isActive: _selectedCounty != null,
            items: svc.counties
                .map((c) => PopupMenuItem(value: c, child: Text(c)))
                .toList()
              ..insert(
                  0,
                  const PopupMenuItem(
                      value: null, child: Text('All Counties'))),
            onSelected: (v) => setState(() => _selectedCounty = v),
          ),
          const SizedBox(width: 8),

          // Min height
          _DropdownPill<int>(
            label: _minHeightFt > 0 ? '$_minHeightFt+ ft' : 'Height',
            isActive: _minHeightFt > 0,
            items: [
              const PopupMenuItem(value: 0, child: Text('Any Height')),
              const PopupMenuItem(value: 25, child: Text('25+ ft')),
              const PopupMenuItem(value: 50, child: Text('50+ ft')),
              const PopupMenuItem(value: 100, child: Text('100+ ft')),
            ],
            onSelected: (v) => setState(() => _minHeightFt = v ?? 0),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    WaterfallService svc,
    LocationService locationSvc,
    StoreService storeSvc,
    List<Waterfall> filtered,
  ) {
    if (svc.isLoading && svc.waterfalls.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (svc.waterfalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              svc.errorMessage ?? 'No waterfall data available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => svc.fetchWaterfalls(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _viewMode == _ViewMode.map
        ? _buildMap(filtered, svc)
        : _buildList(filtered, locationSvc, svc);
  }

  // ---------------------------------------------------------------------------
  // Map view
  // ---------------------------------------------------------------------------

  Widget _buildMap(List<Waterfall> waterfalls, WaterfallService svc) {
    final markers = waterfalls.map((wf) {
      return Marker(
        markerId: MarkerId(wf.id),
        position: LatLng(wf.lat, wf.lon),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          wf.trailClosed ? BitmapDescriptor.hueRed : wf.flowStatus.markerHue,
        ),
        infoWindow: InfoWindow(
          title: wf.name,
          snippet: wf.trailClosed ? 'Trail Closed' : wf.flowStatus.label,
          onTap: () => _openDetail(wf),
        ),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: _kInitialCamera,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  // ---------------------------------------------------------------------------
  // List view
  // ---------------------------------------------------------------------------

  Widget _buildList(
    List<Waterfall> waterfalls,
    LocationService locationSvc,
    WaterfallService svc,
  ) {
    final pos = locationSvc.currentPosition;

    // Section grouping
    final closed = waterfalls.where((w) => w.trailClosed).toList();
    final flooding =
        waterfalls.where((w) => w.flowStatus == FlowStatus.flood && !w.trailClosed).toList();
    final rest = waterfalls
        .where((w) => !w.trailClosed && w.flowStatus != FlowStatus.flood)
        .toList();

    return RefreshIndicator(
      onRefresh: () => svc.fetchWaterfalls(),
      child: ListView(
        children: [
          if (closed.isNotEmpty) ...[
            _SectionHeader(
              title: 'Trail Closures',
              count: closed.length,
              color: Colors.red,
            ),
            ...closed.map((wf) => _rowWithDivider(wf, pos, closed)),
          ],
          if (flooding.isNotEmpty) ...[
            _SectionHeader(
              title: 'Flood Warning',
              count: flooding.length,
              color: Colors.red.shade700,
            ),
            ...flooding.map((wf) => _rowWithDivider(wf, pos, flooding)),
          ],
          _SectionHeader(
            title: 'All Waterfalls',
            count: waterfalls.length,
          ),
          ...rest.map((wf) => _rowWithDivider(wf, pos, rest)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _rowWithDivider(
    Waterfall wf,
    dynamic pos,
    List<Waterfall> list,
  ) {
    final double? dist = pos != null
        ? wf.distanceMiles(pos.latitude, pos.longitude)
        : null;

    return Column(
      children: [
        WaterfallRow(
          waterfall: wf,
          distanceMiles: dist,
          onTap: () => _openDetail(wf),
        ),
        if (wf != list.last)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            color: Colors.grey.shade200,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _openDetail(Waterfall wf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaterfallDetailScreen(waterfall: wf),
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _ViewToggle extends StatelessWidget {
  final _ViewMode current;
  final ValueChanged<_ViewMode> onChanged;
  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            icon: Icons.map_outlined,
            active: current == _ViewMode.map,
            onTap: () => onChanged(_ViewMode.map),
          ),
          _ModeButton(
            icon: Icons.list,
            active: current == _ViewMode.list,
            onTap: () => onChanged(_ViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ModeButton(
      {required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? const Color(0xFF0D3A1A) : Colors.white,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color? color;
  const _SectionHeader(
      {required this.title, required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color ?? Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownPill<T> extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T?> onSelected;

  const _DropdownPill({
    required this.label,
    required this.isActive,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: (v) => onSelected(v),
      itemBuilder: (_) => items,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF0D3A1A) : Colors.white,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? const Color(0xFF0D3A1A) : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
