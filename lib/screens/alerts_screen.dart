import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trail.dart';
import '../services/trail_service.dart';
import 'trail_detail_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Active Alerts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Consumer<TrailService>(
        builder: (context, trailSvc, _) {
          if (trailSvc.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final trailsWithAlerts = trailSvc.trailsWithAlerts;

          if (trailsWithAlerts.isEmpty) {
            return _EmptyAlerts();
          }

          // Group alerts by type
          final Map<AlertType, List<_AlertEntry>> grouped = {};
          for (final trail in trailsWithAlerts) {
            for (final alert in trail.alerts) {
              grouped.putIfAbsent(alert.type, () => []);
              grouped[alert.type]!.add(_AlertEntry(trail: trail, alert: alert));
            }
          }

          // Build ordered type list (by enum declaration order)
          final orderedTypes = AlertType.values
              .where((t) => grouped.containsKey(t))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: orderedTypes.length,
            itemBuilder: (context, sectionIndex) {
              final type = orderedTypes[sectionIndex];
              final entries = grouped[type]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Icon(
                          type.icon,
                          size: 18,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${entries.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Alert cards for this type
                  Container(
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
                    child: Column(
                      children: entries.asMap().entries.map((entry) {
                        final i = entry.key;
                        final alertEntry = entry.value;
                        return Column(
                          children: [
                            _AlertCard(
                              entry: alertEntry,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TrailDetailScreen(
                                      trail: alertEntry.trail,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (i < entries.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                indent: 16,
                                color: Colors.grey.shade200,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 4),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alert Entry data class
// ---------------------------------------------------------------------------

class _AlertEntry {
  final Trail trail;
  final TrailAlert alert;
  const _AlertEntry({required this.trail, required this.alert});
}

// ---------------------------------------------------------------------------
// Alert Card
// ---------------------------------------------------------------------------

class _AlertCard extends StatelessWidget {
  final _AlertEntry entry;
  final VoidCallback onTap;

  const _AlertCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final alert = entry.alert;
    final trail = entry.trail;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                alert.type.icon,
                size: 18,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trail.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
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

            // Chevron
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No active alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All trails are clear. Check back after storms.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
