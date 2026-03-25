import 'package:flutter/material.dart';
import '../models/river.dart';

class RiverRow extends StatelessWidget {
  final River river;
  final VoidCallback onTap;

  const RiverRow({
    super.key,
    required this.river,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String cfsLabel = river.currentCfs != null
        ? '${river.currentCfs!.toStringAsFixed(0)} cfs'
        : river.gaugeFt != null
            ? '${river.gaugeFt!.toStringAsFixed(2)} ft'
            : '— cfs';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Water drop icon
              Icon(
                Icons.water_drop_outlined,
                size: 22,
                color: Colors.blue.shade400,
              ),
              const SizedBox(width: 12),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // River name
                    Text(
                      river.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Region
                    Text(
                      river.region,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // CFS + trend
                    Row(
                      children: [
                        Text(
                          cfsLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (river.trend != RiverTrend.unknown) ...[
                          const SizedBox(width: 6),
                          Icon(
                            river.trend.icon,
                            size: 14,
                            color: _trendColor(river.trend),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            river.trend.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: _trendColor(river.trend),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Condition badge — only shown when a real condition is known
              if (river.condition != RiverCondition.unknown)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: river.condition.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: river.condition.color.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    river.condition.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: river.condition.color,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
