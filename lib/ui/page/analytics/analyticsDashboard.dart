import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/ui/page/analytics/analyticsTheme.dart';
import 'package:flutter_twitter_clone/ui/page/analytics/bookmarkInsightsPage.dart';
import 'package:flutter_twitter_clone/ui/page/analytics/notificationActivityPage.dart';
import 'package:flutter_twitter_clone/ui/page/analytics/tweetAnalyticsPage.dart';
import 'package:flutter_twitter_clone/ui/page/settings/settingsAndPrivacyPage.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// AnalyticsDashboard
//
// Navigation shell for the analytics section.
//
// • phone  (width < 600) → BottomNavigationBar with 4 tabs
// • tablet / desktop     → left NavigationRail with 4 destinations
//
// Tabs:
//   0 – Overview    → TweetAnalyticsPage
//   1 – Post Stats  → NotificationActivityPage
//   2 – Bookmarks   → BookmarkInsightsPage
//   3 – Settings    → SettingsAndPrivacyPage
//
// Accent colour #F5C518; unselected #6B6B6B; rail background #2C2C2C.
// ---------------------------------------------------------------------------

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  /// Named route for use with Navigator.pushNamed.
  static const String routeName = '/AnalyticsDashboard';

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  int _selectedIndex = 0;

  // ── Destination metadata ─────────────────────────────────────────────────

  static const List<_Destination> _destinations = [
    _Destination(
      label: 'Overview',
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart,
    ),
    _Destination(
      label: 'Post Stats',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
    ),
    _Destination(
      label: 'Bookmarks',
      icon: Icons.bookmark_outline,
      activeIcon: Icons.bookmark,
    ),
    _Destination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
    ),
  ];

  // ── Page bodies ──────────────────────────────────────────────────────────

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const TweetAnalyticsPage();
      case 1:
        return const NotificationActivityPage();
      case 2:
        return const BookmarkInsightsPage();
      case 3:
        return const SettingsAndPrivacyPage();
      default:
        return const TweetAnalyticsPage();
    }
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        return isWide
            ? _WideLayout(
                selectedIndex: _selectedIndex,
                destinations: _destinations,
                onDestinationSelected: _onDestinationSelected,
                body: _buildPage(_selectedIndex),
              )
            : _NarrowLayout(
                selectedIndex: _selectedIndex,
                destinations: _destinations,
                onDestinationSelected: _onDestinationSelected,
                body: _buildPage(_selectedIndex),
              );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Narrow layout – BottomNavigationBar
// ---------------------------------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    Key? key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.body,
  }) : super(key: key);

  final int selectedIndex;
  final List<_Destination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAnalyticsBackground,
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kAnalyticsSurface,
          border: Border(
            top: BorderSide(color: kAnalyticsBorder),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onDestinationSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: kAnalyticsAccent,
          unselectedItemColor: kAnalyticsPrimary,
          selectedLabelStyle: GoogleFonts.mulish(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: kAnalyticsAccent,
          ),
          unselectedLabelStyle: GoogleFonts.mulish(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: kAnalyticsPrimary,
          ),
          elevation: 0,
          items: destinations
              .map(
                (d) => BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  activeIcon: Icon(d.activeIcon),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wide layout – NavigationRail
// ---------------------------------------------------------------------------

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    Key? key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.body,
  }) : super(key: key);

  final int selectedIndex;
  final List<_Destination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAnalyticsBackground,
      body: Row(
        children: [
          // ── Navigation Rail ──────────────────────────────────────────────
          NavigationRail(
            backgroundColor: kAnalyticsSurface,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: kAnalyticsAccent),
            unselectedIconTheme: const IconThemeData(color: kAnalyticsPrimary),
            selectedLabelTextStyle: GoogleFonts.mulish(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: kAnalyticsAccent,
            ),
            unselectedLabelTextStyle: GoogleFonts.mulish(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: kAnalyticsPrimary,
            ),
            indicatorColor: kAnalyticsAccent.withOpacity(0.15),
            leading: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Icon(
                Icons.bar_chart_rounded,
                color: kAnalyticsAccent,
                size: 28,
              ),
            ),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.activeIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          // Vertical divider
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: kAnalyticsBorder,
          ),
          // ── Page body ────────────────────────────────────────────────────
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Destination metadata
// ---------------------------------------------------------------------------

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
