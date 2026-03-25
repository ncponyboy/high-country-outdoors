import 'package:flutter/material.dart';
import '../models/waterfall.dart';

class WaterfallRow extends StatelessWidget {
  final Waterfall waterfall;
  final VoidCallback onTap;
  final double? distanceMiles;

  const WaterfallRow({
    super.key,
    required this.waterfall,
    required this.onTap,
    this.distanceMiles,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flow status dot
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: waterfall.trailClosed
                        ? Colors.red
                        : waterfall.flowStatus.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Waterfall icon
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Icon(
                  Icons.water,
                  size: 20,
                  color: Colors.blueGrey.shade400,
                ),
              ),
              const SizedBox(width: 10),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      waterfall.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // County + distance
                    Row(
                      children: [
                        Text(
                          '${waterfall.county} Co., ${waterfall.state}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (distanceMiles != null) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          Text(
                            '${distanceMiles!.toStringAsFixed(1)} mi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Flow status / closed row
                    Row(
                      children: [
                        if (waterfall.trailClosed) ...[
                          Icon(Icons.block,
                              size: 12, color: Colors.red.shade700),
                          const SizedBox(width: 3),
                          Text(
                            'Trail Closed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ] else ...[
                          Icon(waterfall.flowStatus.icon,
                              size: 12,
                              color: waterfall.flowStatus.color),
                          const SizedBox(width: 3),
                          Text(
                            waterfall.flowStatus.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: waterfall.flowStatus.color,
                            ),
                          ),
                        ],

                        // Stats
                        if (waterfall.heightDisplay != null) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          Text(
                            waterfall.heightDisplay!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (waterfall.trailDisplay != null) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          Text(
                            waterfall.trailDisplay!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Difficulty badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      waterfall.difficulty.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: waterfall.difficulty.color.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  waterfall.difficulty.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: waterfall.difficulty.color,
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
