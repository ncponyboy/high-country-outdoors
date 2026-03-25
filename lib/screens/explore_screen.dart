import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trail.dart';
import '../models/ski_resort.dart';
import '../services/trail_service.dart';
import '../services/ski_service.dart';
import '../services/river_service.dart';
import '../services/waterfall_service.dart';
import '../services/location_service.dart';
import '../services/store_service.dart';
import '../widgets/trail_row.dart';
import '../widgets/ski_resort_row.dart';
import '../widgets/river_row.dart';
import '../widgets/waterfall_row.dart';
import 'trail_detail_screen.dart';
import 'ski_resort_detail_screen.dart';
import 'river_detail_screen.dart';
import 'waterfall_detail_screen.dart';
import 'pro_upgrade_screen.dart';

// Activity filter options shown in the pill bar
enum _ActivityFilter {
  all,
  hiking,
  running,
  biking,
  skiing,
  climbing,
  rivers,
  waterfalls,
}

extension _ActivityFilterLabel on _ActivityFilter {
  String get label {
    switch (this) {
      case _ActivityFilter.all:
        return 'All';
      case _ActivityFilter.hiking:
        return 'Hiking';
      case _ActivityFilter.running:
        return 'Running';
      case _ActivityFilter.biking:
        return 'Biking';
      case _ActivityFilter.skiing:
        return 'Skiing';
      case _ActivityFilter.climbing:
        return 'Climbing';
      case _ActivityFilter.rivers:
        return 'Rivers';
      case _ActivityFilter.waterfalls:
        return 'Waterfalls';
    }
  }

  IconData get icon {
    switch (this) {
      case _ActivityFilter.all:
        return Icons.grid_view;
      case _ActivityFilter.hiking:
        return Icons.hiking;
      case _ActivityFilter.running:
        return Icons.directions_run;
      case _ActivityFilter.biking:
        return Icons.directions_bike;
      case _ActivityFilter.skiing:
        return Icons.downhill_skiing;
      case _ActivityFilter.climbing:
        return Icons.terrain;
      case _ActivityFilter.rivers:
        return Icons.water;
      case _ActivityFilter.waterfalls:
        return Icons.water_drop;
    }
  }
}

// Region filter options
enum _RegionFilter {
  all,
  highCountryNC,
  easternTN,
  swVirginia,
}

extension _RegionFilterLabel on _RegionFilter {
  String get label {
    switch (this) {
      case _RegionFilter.all:
        return 'All Regions';
      case _RegionFilter.highCountryNC:
        return 'High Country NC';
      case _RegionFilter.easternTN:
        return 'Eastern TN';
      case _RegionFilter.swVirginia:
        return 'SW Virginia';
    }
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  _ActivityFilter _selectedActivity = _ActivityFilter.all;
  _RegionFilter _selectedRegion = _RegionFilter.all;
  bool _nearMe = false;

  // ---------------------------------------------------------------------------
  // Filtering helpers
  // ---------------------------------------------------------------------------

  List<Trail> _filteredTrails(List<Trail> trails, LocationService location) {
    List<Trail> filtered = trails;

    // Activity filter
    if (_selectedActivity != _ActivityFilter.all &&
        _selectedActivity != _ActivityFilter.skiing &&
        _selectedActivity != _ActivityFilter.rivers &&
        _selectedActivity != _ActivityFilter.waterfalls) {
      final ActivityType target = _activityTypeForFilter(_selectedActivity);
      filtered =
          filtered.where((t) => t.activityTypes.contains(target)).toList();
    }

    // Region filter
    if (_selectedRegion != _RegionFilter.all) {
      final TrailRegion target = _trailRegionForFilter(_selectedRegion);
      filtered = filtered.where((t) => t.region == target).toList();
    }

    // Near me sort
    if (_nearMe && location.currentPosition != null) {
      final lat = location.currentPosition!.latitude;
      final lng = location.currentPosition!.longitude;
      filtered = List<Trail>.from(filtered)
        ..sort((a, b) =>
            a.distanceMiles(lat, lng).compareTo(b.distanceMiles(lat, lng)));
    }

    return filtered;
  }

  ActivityType _activityTypeForFilter(_ActivityFilter filter) {
    switch (filter) {
      case _ActivityFilter.hiking:
        return ActivityType.hiking;
      case _ActivityFilter.running:
        return ActivityType.running;
      case _ActivityFilter.biking:
        return ActivityType.biking;
      case _ActivityFilter.climbing:
        return ActivityType.climbing;
      default:
        return ActivityType.hiking;
    }
  }

  TrailRegion _trailRegionForFilter(_RegionFilter filter) {
    switch (filter) {
      case _RegionFilter.highCountryNC:
        return TrailRegion.highCountryNC;
      case _RegionFilter.easternTN:
        return TrailRegion.easternTN;
      case _RegionFilter.swVirginia:
        return TrailRegion.swVirginia;
      default:
        return TrailRegion.highCountryNC;
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterfallService>(
      builder: (context, waterfallSvc, _) =>
      Consumer5<TrailService, SkiService, RiverService, LocationService,
          StoreService>(
      builder: (context, trailSvc, skiSvc, riverSvc, locationSvc, storeSvc, _) {
        final filteredTrails =
            _filteredTrails(trailSvc.trails, locationSvc);
        final bool showSkiResorts =
            _selectedActivity == _ActivityFilter.skiing;
        final bool showRivers = _selectedActivity == _ActivityFilter.rivers;
        final bool showWaterfalls =
            _selectedActivity == _ActivityFilter.waterfalls;

        // Determine the count label
        String countLabel;
        if (showSkiResorts) {
          countLabel = 'Ski Resorts (${skiSvc.resorts.length})';
        } else if (showRivers) {
          countLabel = 'Rivers (${riverSvc.rivers.length})';
        } else if (showWaterfalls) {
          countLabel = 'Waterfalls (${waterfallSvc.waterfalls.length})';
        } else {
          countLabel =
              'All Conditions (${filteredTrails.length})';
        }

        final bool isLoading =
            trailSvc.isLoading || skiSvc.isLoading || riverSvc.isLoading ||
            waterfallSvc.isLoading;

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                trailSvc.fetchTrails(),
                skiSvc.fetchResorts(),
                riverSvc.fetchRivers(),
                waterfallSvc.fetchWaterfalls(),
              ]);
            },
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: const Color(0xFF0D3A1A),
                  foregroundColor: Colors.white,
                  title: const Text(
                    'High Country Outdoors',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  actions: [
                    if (!storeSvc.isPro)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const ProUpgradeScreen(),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: isLoading
                          ? null
                          : () async {
                              await Future.wait([
                                trailSvc.fetchTrails(),
                                skiSvc.fetchResorts(),
                                riverSvc.fetchRivers(),
                                waterfallSvc.fetchWaterfalls(),
                              ]);
                            },
                    ),
                  ],
                ),

                // Filter bar
                SliverToBoxAdapter(
                  child: _buildFilterBar(locationSvc),
                ),

                // Count header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      countLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),

                // Loading indicator
                if (isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (showSkiResorts)
                  _buildSkiList(skiSvc.resorts)
                else if (showRivers)
                  _buildRiverList(riverSvc.rivers)
                else if (showWaterfalls)
                  _buildWaterfallList(waterfallSvc.waterfalls)
                else
                  _buildTrailList(filteredTrails, trailSvc.errorMessage),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    ));
  }

  Widget _buildFilterBar(LocationService locationSvc) {
    return Container(
      color: const Color(0xFF0D3A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Activity filter pills
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _ActivityFilter.values.map((filter) {
                final selected = _selectedActivity == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: filter.label,
                    icon: filter.icon,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _selectedActivity = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Region filter pills + Near Me
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                ..._RegionFilter.values.map((filter) {
                  final selected = _selectedRegion == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterPill(
                      label: filter.label,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _selectedRegion = filter;
                        });
                      },
                    ),
                  );
                }),
                // Near Me button
                _FilterPill(
                  label: 'Near Me',
                  icon: Icons.near_me,
                  selected: _nearMe,
                  onTap: () async {
                    if (!_nearMe &&
                        locationSvc.currentPosition == null) {
                      await locationSvc.requestLocation();
                    }
                    setState(() {
                      _nearMe = !_nearMe;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  SliverList _buildTrailList(List<Trail> trails, String? errorMessage) {
    if (errorMessage != null && trails.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _EmptyState(
            icon: Icons.cloud_off_outlined,
            message: errorMessage,
          ),
        ]),
      );
    }
    if (trails.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const _EmptyState(
            icon: Icons.search_off_outlined,
            message: 'No trails found for these filters.',
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final trail = trails[index];
          return Column(
            children: [
              TrailRow(
                trail: trail,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrailDetailScreen(trail: trail),
                    ),
                  );
                },
              ),
              if (index < trails.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  color: Colors.grey.shade200,
                ),
            ],
          );
        },
        childCount: trails.length,
      ),
    );
  }

  SliverList _buildSkiList(List<SkiResort> resorts) {
    if (resorts.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const _EmptyState(
            icon: Icons.ac_unit,
            message: 'No ski resort data available.',
          ),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final resort = resorts[index];
          return Column(
            children: [
              SkiResortRow(
                resort: resort,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SkiResortDetailScreen(resort: resort),
                    ),
                  );
                },
              ),
              if (index < resorts.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  color: Colors.grey.shade200,
                ),
            ],
          );
        },
        childCount: resorts.length,
      ),
    );
  }

  SliverList _buildRiverList(List<dynamic> rivers) {
    if (rivers.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const _EmptyState(
            icon: Icons.water_outlined,
            message: 'No river data available.',
          ),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final river = rivers[index];
          return Column(
            children: [
              RiverRow(
                river: river,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiverDetailScreen(river: river),
                    ),
                  );
                },
              ),
              if (index < rivers.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  color: Colors.grey.shade200,
                ),
            ],
          );
        },
        childCount: rivers.length,
      ),
    );
  }

  SliverList _buildWaterfallList(List<dynamic> waterfalls) {
    if (waterfalls.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const _EmptyState(
            icon: Icons.water_drop_outlined,
            message: 'No waterfall data available.',
          ),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final waterfall = waterfalls[index];
          return Column(
            children: [
              WaterfallRow(
                waterfall: waterfall,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WaterfallDetailScreen(waterfall: waterfall),
                    ),
                  );
                },
              ),
              if (index < waterfalls.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  color: Colors.grey.shade200,
                ),
            ],
          );
        },
        childCount: waterfalls.length,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected
                    ? const Color(0xFF0D3A1A)
                    : Colors.white,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF0D3A1A)
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// Sliver persistent header delegate for the filter bar
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _FilterHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 96;

  @override
  double get minExtent => 96;

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) => true;
}
