import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/store_service.dart';
import '../services/favorites_service.dart';
import '../main.dart' show AppTab;
import 'pro_upgrade_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onHome;
  const SettingsScreen({super.key, this.onHome});

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3A1A),
        foregroundColor: Colors.white,
        leading: onHome != null
            ? IconButton(
                icon: const Icon(Icons.home),
                onPressed: onHome,
                tooltip: 'Home',
              )
            : null,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Consumer2<StoreService, FavoritesService>(
        builder: (context, storeSvc, favoritesSvc, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // Pro section
              _SectionHeader(label: 'HIGH COUNTRY OUTDOORS PRO'),
              _ProSection(storeSvc: storeSvc),

              const SizedBox(height: 20),

              // Favorites section
              _SectionHeader(label: 'FAVORITES'),
              _FavoritesSection(favoritesSvc: favoritesSvc),

              const SizedBox(height: 20),

              // Support section
              _SectionHeader(label: 'SUPPORT'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.star_outline,
                    iconColor: Colors.orange,
                    label: 'Rate the App',
                    onTap: () {
                      // TODO: link to App Store rating page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rating coming soon!'),
                        ),
                      );
                    },
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.blue,
                    label: 'Privacy Policy',
                    onTap: () => _launchUrl(
                      'https://ncponyboy.github.io/high-country-outdoors/privacy.html',
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 16,
                        color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // About section
              _SectionHeader(label: 'ABOUT'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    iconColor: Colors.grey,
                    label: 'Version',
                    trailing: Text(
                      _appVersion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    onTap: null,
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.code,
                    iconColor: const Color(0xFF0D3A1A),
                    label: 'Built by Chase\'s Software',
                    onTap: null,
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// Pro Section
// ---------------------------------------------------------------------------

class _ProSection extends StatelessWidget {
  final StoreService storeSvc;
  const _ProSection({required this.storeSvc});

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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D3A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.landscape, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'High Country Outdoors Pro',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        storeSvc.isPro
                            ? 'Active subscription'
                            : 'Unlock all features',
                        style: TextStyle(
                          fontSize: 12,
                          color: storeSvc.isPro
                              ? Colors.green
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (storeSvc.isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.shade200, width: 1),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!storeSvc.isPro) ...[
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ProUpgradeScreen(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Subscribe — \$9.99/year',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          TextButton(
            onPressed: storeSvc.isLoading
                ? null
                : () async {
                    await storeSvc.restorePurchases();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            storeSvc.isPro
                                ? 'Pro restored successfully!'
                                : storeSvc.errorMessage ??
                                    'No purchases to restore.',
                          ),
                        ),
                      );
                    }
                  },
            child: storeSvc.isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Restore Purchases',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

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
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null && trailing == null)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 48,
      color: Colors.grey.shade200,
    );
  }
}

// ---------------------------------------------------------------------------
// Favorites Section
// ---------------------------------------------------------------------------

class _FavoritesSection extends StatelessWidget {
  final FavoritesService favoritesSvc;
  const _FavoritesSection({required this.favoritesSvc});

  // Tabs that can be toggled (Settings is always shown, never a favorite).
  // Search is intentionally last — after all activity categories.
  static const List<AppTab> _toggleableTabs = [
    AppTab.explore,
    AppTab.waterfalls,
    AppTab.alerts,
    AppTab.hiking,
    AppTab.running,
    AppTab.biking,
    AppTab.climbing,
    AppTab.skiing,
    AppTab.rivers,
    AppTab.search,
  ];

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
      child: Column(
        children: [
          ..._toggleableTabs.asMap().entries.map((entry) {
            final tab = entry.value;
            final isFirst = entry.key == 0;
            final isLast = entry.key == _toggleableTabs.length - 1;
            final enabled = favoritesSvc.contains(tab.name);

            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => favoritesSvc.toggle(tab.name),
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(12) : Radius.zero,
                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            enabled ? tab.activeIcon : tab.icon,
                            size: 20,
                            color: enabled
                                ? const Color(0xFF0D3A1A)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tab.label,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Switch(
                            value: enabled,
                            onChanged: (_) => favoritesSvc.toggle(tab.name),
                            activeThumbColor: const Color(0xFF0D3A1A),
                            activeTrackColor: const Color(0xFF0D3A1A).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 48,
                    color: Colors.grey.shade200,
                  ),
              ],
            );
          }),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          TextButton(
            onPressed: () => favoritesSvc.resetToDefault(),
            child: Text(
              'Reset to Default',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
