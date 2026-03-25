import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_service.dart';

class ProUpgradeScreen extends StatelessWidget {
  const ProUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Gradient header
                      _GradientHeader(),

                      const SizedBox(height: 24),

                      // Feature list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _FeatureRow(
                              icon: Icons.directions,
                              iconColor: Colors.blue,
                              title: 'Get Directions',
                              description:
                                  'Navigate directly to any trailhead or put-in with one tap.',
                            ),
                            _FeatureRow(
                              icon: Icons.notifications_active,
                              iconColor: Colors.red,
                              title: 'Priority Trail Alerts',
                              description:
                                  'Be the first to know about closures, fire danger, and bear activity.',
                            ),
                            _FeatureRow(
                              icon: Icons.wb_sunny_outlined,
                              iconColor: Colors.orange,
                              title: 'Trailhead Weather',
                              description:
                                  'See real-time weather conditions at each trailhead before you go.',
                            ),
                            _FeatureRow(
                              icon: Icons.download_outlined,
                              iconColor: Colors.green,
                              title: 'Offline Conditions',
                              description:
                                  'Download conditions for offline access in areas without service.',
                            ),
                            _FeatureRow(
                              icon: Icons.favorite_outline,
                              iconColor: Color(0xFFE91E63),
                              title: 'Support the Mission',
                              description:
                                  'Help fund data collection and keep the app free for everyone.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Subscribe button
                      _SubscribeButton(),

                      const SizedBox(height: 12),

                      // Restore
                      _RestoreButton(),

                      const SizedBox(height: 8),

                      Text(
                        'Cancel anytime. Billed annually.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient Header
// ---------------------------------------------------------------------------

class _GradientHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D3A1A), Color(0xFF1A5C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Mountain icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.landscape,
              size: 36,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'High Country Outdoors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature Row
// ---------------------------------------------------------------------------

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
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
// Subscribe Button
// ---------------------------------------------------------------------------

class _SubscribeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<StoreService>(
      builder: (context, storeSvc, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: storeSvc.isLoading
                  ? null
                  : () async {
                      await storeSvc.purchasePro();
                      if (!context.mounted) return;
                      if (storeSvc.isPro) {
                        Navigator.pop(context);
                      } else if (storeSvc.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(storeSvc.errorMessage!),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D3A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: storeSvc.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Subscribe — ${storeSvc.priceString}/year',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Restore Button
// ---------------------------------------------------------------------------

class _RestoreButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<StoreService>(
      builder: (context, storeSvc, _) {
        return TextButton(
          onPressed: storeSvc.isLoading
              ? null
              : () async {
                  await storeSvc.restorePurchases();
                  if (storeSvc.isPro && context.mounted) {
                    Navigator.pop(context);
                  }
                },
          child: Text(
            'Restore Purchases',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      },
    );
  }
}
