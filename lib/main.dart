import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/trail_service.dart';
import 'services/ski_service.dart';
import 'services/river_service.dart';
import 'services/waterfall_service.dart';
import 'services/location_service.dart';
import 'services/store_service.dart';
import 'services/favorites_service.dart';
import 'screens/explore_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/waterfalls_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HighCountryOutdoorsApp());
}

// ---------------------------------------------------------------------------
// Root app
// ---------------------------------------------------------------------------

class HighCountryOutdoorsApp extends StatelessWidget {
  const HighCountryOutdoorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrailService()),
        ChangeNotifierProvider(create: (_) => SkiService()),
        ChangeNotifierProvider(create: (_) => RiverService()),
        ChangeNotifierProvider(create: (_) => WaterfallService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => StoreService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
      ],
      child: MaterialApp(
        title: 'High Country Outdoors',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const _AppStartup(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const Color primary = Color(0xFF0D3A1A);
    const Color accent = Color(0xFF1A5C2E);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      scaffoldBackgroundColor: Colors.grey.shade100,
    );
  }
}

// ---------------------------------------------------------------------------
// App startup: shows splash, then decides onboarding vs main
// ---------------------------------------------------------------------------

class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final trailSvc = context.read<TrailService>();
    final skiSvc = context.read<SkiService>();
    final riverSvc = context.read<RiverService>();
    final storeSvc = context.read<StoreService>();
    final locationSvc = context.read<LocationService>();
    final waterfallSvc = context.read<WaterfallService>();
    final favoritesSvc = context.read<FavoritesService>();

    await Future.wait([
      trailSvc.fetchTrails(),
      skiSvc.fetchResorts(),
      riverSvc.fetchRivers(),
      waterfallSvc.fetchWaterfalls(),
      storeSvc.loadProducts(),
      locationSvc.requestLocation(),
      favoritesSvc.load(),
    ]);
    storeSvc.checkProStatus();
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// ---------------------------------------------------------------------------
// Splash Screen
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), _advance);
  }

  Future<void> _advance() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            hasSeenOnboarding ? const MainTabView() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3A1A),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.landscape,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'High Country Outdoors',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Chase's Software",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.65),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding Screen
// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.landscape,
      title: 'Welcome to\nHigh Country Outdoors',
      subtitle:
          'Real-time trail, ski resort, and river conditions for Eastern TN, Western NC, and SW Virginia.',
    ),
    _OnboardingPageData(
      icon: Icons.check_circle_outline,
      title: 'Always Know\nBefore You Go',
      subtitle:
          'Get current surface conditions, alerts, water crossings, blowdowns, and snow reports — all in one place.',
    ),
    _OnboardingPageData(
      icon: Icons.near_me,
      title: 'Trails\nNear You',
      subtitle:
          'Enable location to sort trails by distance and find the best conditions closest to you.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainTabView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3A1A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) =>
                    _OnboardingPageWidget(page: _pages[i]),
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D3A1A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_currentPage < _pages.length - 1)
              TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              )
            else
              const SizedBox(height: 40),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPageData page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppTab — all navigable sections
// ---------------------------------------------------------------------------

enum AppTab {
  explore,
  waterfalls,
  alerts,
  hiking,
  running,
  biking,
  climbing,
  skiing,
  rivers,
  search,
  ;

  String get label {
    switch (this) {
      case AppTab.explore:    return 'Explore';
      case AppTab.waterfalls: return 'Waterfalls';
      case AppTab.alerts:     return 'Alerts';
      case AppTab.hiking:     return 'Hiking';
      case AppTab.running:    return 'Running';
      case AppTab.biking:     return 'Biking';
      case AppTab.climbing:   return 'Climbing';
      case AppTab.skiing:     return 'Skiing';
      case AppTab.rivers:     return 'Rivers';
      case AppTab.search:     return 'Search';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.explore:    return Icons.map_outlined;
      case AppTab.waterfalls: return Icons.water_outlined;
      case AppTab.alerts:     return Icons.warning_amber_outlined;
      case AppTab.hiking:     return Icons.hiking;
      case AppTab.running:    return Icons.directions_run;
      case AppTab.biking:     return Icons.directions_bike;
      case AppTab.climbing:   return Icons.terrain;
      case AppTab.skiing:     return Icons.downhill_skiing;
      case AppTab.rivers:     return Icons.kayaking;
      case AppTab.search:     return Icons.search_outlined;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case AppTab.explore:    return Icons.map;
      case AppTab.waterfalls: return Icons.water;
      case AppTab.alerts:     return Icons.warning_amber;
      case AppTab.hiking:     return Icons.hiking;
      case AppTab.running:    return Icons.directions_run;
      case AppTab.biking:     return Icons.directions_bike;
      case AppTab.climbing:   return Icons.terrain;
      case AppTab.skiing:     return Icons.downhill_skiing;
      case AppTab.rivers:     return Icons.kayaking;
      case AppTab.search:     return Icons.search;
    }
  }

  Widget get screen {
    switch (this) {
      case AppTab.explore:    return const ExploreScreen();
      case AppTab.waterfalls: return const WaterfallsScreen();
      case AppTab.alerts:     return const AlertsScreen();
      case AppTab.search:     return const SearchScreen();
      case AppTab.hiking:
      case AppTab.running:
      case AppTab.biking:
      case AppTab.climbing:
      case AppTab.skiing:
      case AppTab.rivers:
        return const ExploreScreen();
    }
  }

  static const String defaultFavorites = 'explore,waterfalls,alerts,search';
}

// ---------------------------------------------------------------------------
// Main Tab View
// ---------------------------------------------------------------------------

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  // null = Settings tab is selected; otherwise the specific AppTab is active.
  AppTab? _selectedTab; // starts on first favorite

  List<AppTab> _tabsFromService(FavoritesService svc) {
    return svc.favorites
        .map((id) {
          try {
            return AppTab.values.firstWhere((t) => t.name == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<AppTab>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesSvc, _) {
        final tabs = _tabsFromService(favoritesSvc);
        if (tabs.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If current selected tab was removed from favorites, keep showing it
        // (it's still in the IndexedStack) but fall back to first tab.
        final bool onSettings = _selectedTab == null;
        final int settingsIndex = tabs.length;

        // Compute bottom nav currentIndex
        int currentIndex;
        if (onSettings) {
          currentIndex = settingsIndex;
        } else {
          final idx = tabs.indexOf(_selectedTab!);
          currentIndex = idx >= 0 ? idx : 0;
        }

        // IndexedStack index: favorites 0..n-1, Settings at n
        final int stackIndex = onSettings
            ? settingsIndex
            : (tabs.indexOf(_selectedTab!) >= 0
                ? tabs.indexOf(_selectedTab!)
                : 0);

        return Scaffold(
          body: IndexedStack(
            index: stackIndex,
            children: [
              ...tabs.map((t) => t.screen),
              SettingsScreen(
                onHome: () => setState(() => _selectedTab = tabs.first),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                if (index == settingsIndex) {
                  _selectedTab = null; // Settings
                } else {
                  _selectedTab = tabs[index];
                }
              });
            },
            selectedItemColor: const Color(0xFF0D3A1A),
            unselectedItemColor: Colors.grey.shade500,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            items: [
              ...tabs.map((tab) => BottomNavigationBarItem(
                    icon: Icon(tab.icon),
                    activeIcon: Icon(tab.activeIcon),
                    label: tab.label,
                  )),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
