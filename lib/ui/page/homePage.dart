import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/notificationModel.dart';
import 'package:flutter_twitter_clone/model/push_notification_model.dart';
import 'package:flutter_twitter_clone/resource/push_notification_service.dart';
import 'package:flutter_twitter_clone/state/appState.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/bookmarkState.dart';
import 'package:flutter_twitter_clone/state/chats/chatState.dart';
import 'package:flutter_twitter_clone/state/notificationState.dart';
import 'package:flutter_twitter_clone/state/searchState.dart';
import 'package:flutter_twitter_clone/state/suggestionUserState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/page/bookmark/bookmarkPage.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPage.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/feed/suggestedUsers.dart';
import 'package:flutter_twitter_clone/ui/page/message/chatListPage.dart';
import 'package:flutter_twitter_clone/ui/page/notification/notificationPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'common/locator.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
const Color _kPrimary = Color(0xFF1DA1F2);
const Color _kSecondary = Color(0xFF14171A);
const Color _kLightGrey = Color(0xFFAAB8C2);
const Color _kExtraLight = Color(0xFFE1E8ED);
const Color _kBackground = Color(0xFFF5F8FA);
const double _kRadius = 12.0;
const double _kWideBreakpoint = 800.0;

// ---------------------------------------------------------------------------
// HomePage – HomeCommandCenter
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  /// 0=Feed, 1=Notifications, 2=Bookmarks, 3=Messages, 4=Profile
  int _railIndex = 0;

  // ignore: cancel_subscription
  late StreamSubscription<PushNotificationModel> pushNotificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var state = Provider.of<AppState>(context, listen: false);
      state.setPageIndex = 0;
      _initTweets();
      _initProfile();
      _initSearch();
      _initNotification();
      _initChat();
      _initDynamicLinks();
    });
  }

  @override
  void dispose() {
    pushNotificationSubscription.cancel();
    super.dispose();
  }

  // ── Init helpers ──────────────────────────────────────────────────────────

  void _initTweets() {
    var state = Provider.of<FeedState>(context, listen: false);
    state.databaseInit();
    state.getDataFromDatabase();
  }

  void _initProfile() {
    var state = Provider.of<AuthState>(context, listen: false);
    state.databaseInit();
  }

  void _initSearch() {
    var searchState = Provider.of<SearchState>(context, listen: false);
    searchState.getDataFromDatabase();
  }

  void _initNotification() {
    var state = Provider.of<NotificationState>(context, listen: false);
    var authState = Provider.of<AuthState>(context, listen: false);
    state.databaseInit(authState.userId);
    state.initFirebaseService();
    pushNotificationSubscription = getIt<PushNotificationService>()
        .pushNotificationResponseStream
        .listen(_listenPushNotification);
  }

  void _listenPushNotification(PushNotificationModel model) {
    final authState = Provider.of<AuthState>(context, listen: false);
    var state = Provider.of<NotificationState>(context, listen: false);

    if (model.type == NotificationType.Message.toString() &&
        model.receiverId == authState.user!.uid) {
      state.getUserDetail(model.senderId).then((user) {
        final chatState = Provider.of<ChatState>(context, listen: false);
        chatState.setChatUser = user!;
        Navigator.pushNamed(context, '/ChatScreenPage');
      });
    } else if (model.type == NotificationType.Mention.toString() &&
        model.receiverId == authState.user!.uid) {
      var feedState = Provider.of<FeedState>(context, listen: false);
      feedState.getPostDetailFromDatabase(model.tweetId);
      Navigator.push(context, FeedPostDetail.getRoute(model.tweetId));
    }
  }

  void _initChat() {
    final chatState = Provider.of<ChatState>(context, listen: false);
    final state = Provider.of<AuthState>(context, listen: false);
    chatState.databaseInit(state.userId, state.userId);
    state.updateFCMToken();
    chatState.getFCMServerKey();
  }

  void _initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen(
        (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;
      if (deepLink != null) _redirectFromDeepLink(deepLink);
    }, onError: (e) async {
      cprint(e.message, errorIn: 'onLinkError');
    });

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) _redirectFromDeepLink(deepLink);
  }

  void _redirectFromDeepLink(Uri deepLink) {
    cprint('Found Url from share: ${deepLink.path}');
    var type = deepLink.path.split('/')[1];
    var id = deepLink.path.split('/')[2];
    if (type == 'profilePage') {
      Navigator.push(context, ProfilePage.getRoute(profileId: id));
    } else if (type == 'tweet') {
      var feedState = Provider.of<FeedState>(context, listen: false);
      feedState.getPostDetailFromDatabase(id);
      Navigator.push(context, FeedPostDetail.getRoute(id));
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _onRailTap(int index) {
    if (index == 4) {
      // Profile – push as a separate route
      final authState = Provider.of<AuthState>(context, listen: false);
      if (authState.userModel?.userId != null) {
        Navigator.push(
          context,
          ProfilePage.getRoute(profileId: authState.userModel!.userId!),
        );
      }
      return;
    }
    setState(() => _railIndex = index);
  }

  void _openCompose() {
    Navigator.pushNamed(context, '/ComposeTweetPage/tweet');
  }

  // ── Page body ─────────────────────────────────────────────────────────────

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return FeedPage(
          scaffoldKey: _scaffoldKey,
          refreshIndicatorKey: refreshIndicatorKey,
        );
      case 1:
        return NotificationPage(scaffoldKey: _scaffoldKey);
      case 2:
        return ChangeNotifierProvider(
          create: (_) => BookmarkState(),
          child: const BookmarkPage(),
        );
      case 3:
        return ChatListPage(scaffoldKey: _scaffoldKey);
      default:
        return FeedPage(scaffoldKey: _scaffoldKey);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthState>();
    context.read<SuggestionsState>().initUser(state.userModel);

    if (context
        .select<SuggestionsState, bool>((s) => s.displaySuggestions)) {
      return const SuggestedUsers();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBackground,
      // No BottomNavigationBar – navigation is in the left rail
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        backgroundColor: _kPrimary,
        tooltip: 'Compose Tweet',
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _kWideBreakpoint;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left NavigationRail ──────────────────────────────────
                _LeftRail(
                  selectedIndex: _railIndex,
                  onDestinationSelected: _onRailTap,
                  isWide: isWide,
                ),

                // ── Central feed column ──────────────────────────────────
                Expanded(
                  child: _pageForIndex(_railIndex),
                ),

                // ── Right sidebar (wide screens only) ────────────────────
                if (isWide)
                  const SizedBox(
                    width: 300,
                    child: EngagementStatsSidebar(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<StreamSubscription<PushNotificationModel>>(
            'pushNotificationSubscription', pushNotificationSubscription));
  }
}

// ---------------------------------------------------------------------------
// _LeftRail – persistent NavigationRail with 5 destinations
// ---------------------------------------------------------------------------

class _LeftRail extends StatelessWidget {
  const _LeftRail({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isWide,
  }) : super(key: key);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final notifState = Provider.of<NotificationState>(context);
    final unreadCount = notifState.notificationList?.length ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _kExtraLight)),
      ),
      child: NavigationRail(
        backgroundColor: Colors.white,
        selectedIndex: selectedIndex < 4 ? selectedIndex : 0,
        onDestinationSelected: onDestinationSelected,
        extended: isWide,
        minWidth: 56,
        minExtendedWidth: 200,
        labelType: isWide
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.selected,
        selectedIconTheme: const IconThemeData(color: _kPrimary, size: 26),
        unselectedIconTheme:
            const IconThemeData(color: _kSecondary, size: 24),
        selectedLabelTextStyle: GoogleFonts.mulish(
          color: _kPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
        unselectedLabelTextStyle: GoogleFonts.mulish(
          color: _kSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
        ),
        trailing: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _RailProfileAvatar(
            profilePic: authState.userModel?.profilePic,
            displayName: authState.userModel?.displayName,
            isWide: isWide,
          ),
        ),
        destinations: [
          const NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Feed'),
          ),
          NavigationRailDestination(
            icon: unreadCount > 0
                ? Badge(
                    label: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: GoogleFonts.mulish(
                          fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: const Text('Notifications'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: Text('Bookmarks'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: Text('Messages'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profile'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RailProfileAvatar – small avatar at the bottom of the rail
// ---------------------------------------------------------------------------

class _RailProfileAvatar extends StatelessWidget {
  const _RailProfileAvatar({
    Key? key,
    this.profilePic,
    this.displayName,
    required this.isWide,
  }) : super(key: key);

  final String? profilePic;
  final String? displayName;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return CircularImage(
        path: profilePic ?? Constants.dummyProfilePic,
        height: 32,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularImage(
          path: profilePic ?? Constants.dummyProfilePic,
          height: 32,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            displayName ?? '',
            style: GoogleFonts.mulish(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _kSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// EngagementStatsSidebar – right sidebar showing live notification counts
// ---------------------------------------------------------------------------

class EngagementStatsSidebar extends StatelessWidget {
  const EngagementStatsSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── Engagement stats card ──────────────────────────────────
            _StatsCard(),
            const SizedBox(height: 16),
            // ── Recent notifications card ──────────────────────────────
            _RecentNotificationsCard(),
            const SizedBox(height: 16),
            // ── Quick compose hint ─────────────────────────────────────
            _QuickComposeHint(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatsCard – live engagement counts from NotificationState
// ---------------------------------------------------------------------------

class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationState>(
      builder: (context, state, _) {
        final list = state.notificationList ?? [];
        final likes = list
            .where((n) => n.type == NotificationType.Like.toString())
            .length;
        final follows = list
            .where((n) => n.type == NotificationType.Follow.toString())
            .length;
        final retweets = list
            .where((n) => n.type == NotificationType.Retweet.toString())
            .length;
        final total = list.length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: _kExtraLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text(
                  'Engagement',
                  style: GoogleFonts.mulish(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _kSecondary,
                  ),
                ),
              ),
              const Divider(height: 1, color: _kExtraLight),
              // 2×2 stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      value: '$total',
                      label: 'Total',
                      icon: Icons.notifications_outlined,
                      iconColor: _kPrimary,
                    ),
                  ),
                  Container(width: 1, height: 72, color: _kExtraLight),
                  Expanded(
                    child: _StatCell(
                      value: '$likes',
                      label: 'Likes',
                      icon: Icons.favorite_outline,
                      iconColor: const Color(0xFFE0245E),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, color: _kExtraLight),
              Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      value: '$retweets',
                      label: 'Retweets',
                      icon: Icons.repeat,
                      iconColor: const Color(0xFF17BF63),
                    ),
                  ),
                  Container(width: 1, height: 72, color: _kExtraLight),
                  Expanded(
                    child: _StatCell(
                      value: '$follows',
                      label: 'Follows',
                      icon: Icons.person_add_outlined,
                      iconColor: _kPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    Key? key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.mulish(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kSecondary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.mulish(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kLightGrey,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RecentNotificationsCard – last few notifications
// ---------------------------------------------------------------------------

class _RecentNotificationsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationState>(
      builder: (context, state, _) {
        final list = (state.notificationList ?? []).take(5).toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: _kExtraLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text(
                  'Recent Activity',
                  style: GoogleFonts.mulish(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _kSecondary,
                  ),
                ),
              ),
              const Divider(height: 1, color: _kExtraLight),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No recent activity',
                    style: GoogleFonts.mulish(
                      color: _kLightGrey,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ...list.map((n) => _NotifRow(model: n)).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({Key? key, required this.model}) : super(key: key);
  final NotificationModel model;

  IconData get _icon {
    if (model.type == NotificationType.Like.toString()) {
      return Icons.favorite;
    } else if (model.type == NotificationType.Retweet.toString()) {
      return Icons.repeat;
    } else if (model.type == NotificationType.Follow.toString()) {
      return Icons.person_add;
    }
    return Icons.notifications;
  }

  Color get _iconColor {
    if (model.type == NotificationType.Like.toString()) {
      return const Color(0xFFE0245E);
    } else if (model.type == NotificationType.Retweet.toString()) {
      return const Color(0xFF17BF63);
    }
    return _kPrimary;
  }

  String get _label {
    final name = model.user.displayName ?? model.user.userName ?? 'Someone';
    if (model.type == NotificationType.Like.toString()) {
      return '$name liked your tweet';
    } else if (model.type == NotificationType.Retweet.toString()) {
      return '$name retweeted your tweet';
    } else if (model.type == NotificationType.Follow.toString()) {
      return '$name followed you';
    }
    return '$name interacted with you';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kExtraLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _label,
              style: GoogleFonts.mulish(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _QuickComposeHint – CTA card at the bottom of the sidebar
// ---------------------------------------------------------------------------

class _QuickComposeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share your thoughts',
            style: GoogleFonts.mulish(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: _kSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the compose button to post a new tweet.',
            style: GoogleFonts.mulish(
              fontSize: 12,
              color: _kLightGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/ComposeTweetPage/tweet'),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(
                'Compose',
                style: GoogleFonts.mulish(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
