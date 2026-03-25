import 'package:flutter/material.dart';
import '../models/ski_resort.dart';

class SkiResortRow extends StatelessWidget {
  final SkiResort resort;
  final VoidCallback onTap;

  const SkiResortRow({
    super.key,
    required this.resort,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trailFraction = resort.totalTrails > 0
        ? resort.openTrails / resort.totalTrails
        : 0.0;
    final liftFraction = resort.totalLifts > 0
        ? resort.openLifts / resort.totalLifts
        : 0.0;

    String baseDepthLabel = '—';
    if (resort.baseDepthLow != null && resort.baseDepthHigh != null) {
      baseDepthLabel =
          '${resort.baseDepthLow}"–${resort.baseDepthHigh}"';
    } else if (resort.baseDepthLow != null) {
      baseDepthLabel = '${resort.baseDepthLow}"';
    } else if (resort.baseDepthHigh != null) {
      baseDepthLabel = '${resort.baseDepthHigh}"';
    }

    String newSnowLabel = '—';
    if (resort.newSnow72h != null) {
      newSnowLabel = '${resort.newSnow72h!.toStringAsFixed(1)}"';
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Snowflake icon
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.ac_unit,
                  size: 22,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 12),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resort name + status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resort.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          resort.status.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: resort.status.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Snow stats row
                    Row(
                      children: [
                        _StatChip(
                          label: 'Base',
                          value: baseDepthLabel,
                          icon: Icons.layers_outlined,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: '72h Snow',
                          value: newSnowLabel,
                          icon: Icons.cloudy_snowing,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Trails progress
                    _ProgressRow(
                      label: 'Trails',
                      open: resort.openTrails,
                      total: resort.totalTrails,
                      fraction: trailFraction,
                      color: resort.status.color,
                    ),
                    const SizedBox(height: 4),
                    // Lifts progress
                    _ProgressRow(
                      label: 'Lifts',
                      open: resort.openLifts,
                      total: resort.totalLifts,
                      fraction: liftFraction,
                      color: Colors.blue.shade300,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int open;
  final int total;
  final double fraction;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.open,
    required this.total,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$open/$total',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
