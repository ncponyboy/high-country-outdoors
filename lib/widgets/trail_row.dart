import 'package:flutter/material.dart';
import '../models/trail.dart';

class TrailRow extends StatelessWidget {
  final Trail trail;
  final VoidCallback onTap;

  const TrailRow({
    super.key,
    required this.trail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final conditions = trail.conditions;
    final primaryActivity =
        trail.activityTypes.isNotEmpty ? trail.activityTypes.first : ActivityType.hiking;

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
              // Status dot
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: conditions.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Activity icon
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  primaryActivity.icon,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 10),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trail name
                    Text(
                      trail.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Park / forest
                    if (trail.parkForest.isNotEmpty)
                      Text(
                        trail.parkForest,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Condition status text + surface
                    Row(
                      children: [
                        Text(
                          conditions.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: conditions.status.color,
                          ),
                        ),
                        if (conditions.surface != null &&
                            conditions.surface!.isNotEmpty) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          Flexible(
                            child: Text(
                              conditions.surface!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Region
                    Text(
                      trail.region.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trail.difficulty.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: trail.difficulty.color.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  trail.difficulty.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trail.difficulty.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
