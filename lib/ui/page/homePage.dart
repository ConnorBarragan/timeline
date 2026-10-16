import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/push_notification_model.dart';
import 'package:flutter_twitter_clone/resource/push_notification_service.dart';
import 'package:flutter_twitter_clone/state/appState.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/chats/chatState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/state/notificationState.dart';
import 'package:flutter_twitter_clone/state/searchState.dart';
import 'package:flutter_twitter_clone/state/suggestionUserState.dart';
import 'package:flutter_twitter_clone/state/bookmarkState.dart';
import 'package:flutter_twitter_clone/ui/page/bookmark/bookmarkPage.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPage.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/feed/suggestedUsers.dart';
import 'package:flutter_twitter_clone/ui/page/message/chatListPage.dart';
import 'package:flutter_twitter_clone/ui/page/notification/notificationPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:flutter_twitter_clone/ui/page/search/SearchPage.dart';
import 'package:flutter_twitter_clone/ui/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'common/locator.dart';

// ---------------------------------------------------------------------------
// Tab indices
// ---------------------------------------------------------------------------
const int _kFeedTab = 0;
const int _kExploreTab = 1;
const int _kNotificationsTab = 2;
const int _kMessagesTab = 3;
const int _kBookmarksTab = 4;

// ---------------------------------------------------------------------------
// Cinder Rust palette constants (local aliases for readability)
// ---------------------------------------------------------------------------
const Color _kNavBackground = Color(0xFF1C1410);   // deep charcoal-brown
const Color _kNavActive     = Color(0xFFC0522B);   // burnt rust
const Color _kNavInactive   = Color(0xFF8C7B72);   // taupe
const Color _kNavLabel      = Color(0xFFF2EDE8);   // warm off-white (active)
const Color _kStackBg       = Color(0xFF2A1F1A);   // darkest cinder

// ---------------------------------------------------------------------------
// HomePage – BottomNavigationBar shell with 5 tabs
//
// Tabs:  0 = Feed  |  1 = Explore  |  2 = Notifications
//        3 = Messages  |  4 = Bookmarks
//
// All five tabs are kept alive inside an IndexedStack so scroll position is
// preserved.  A FAB (compose) is shown only when the Feed tab is active.
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  /// Currently visible tab index (0–4).
  int _currentIndex = _kFeedTab;

  // ignore: cancel_subscriptions
  late StreamSubscription<PushNotificationModel> _pushNotifSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).setPageIndex = 0;
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
    _pushNotifSub.cancel();
    super.dispose();
  }

  // ── Init helpers ──────────────────────────────────────────────────────────

  void _initTweets() {
    final state = Provider.of<FeedState>(context, listen: false);
    state.databaseInit();
    state.getDataFromDatabase();
  }

  void _initProfile() {
    Provider.of<AuthState>(context, listen: false).databaseInit();
  }

  void _initSearch() {
    Provider.of<SearchState>(context, listen: false).getDataFromDatabase();
  }

  void _initNotification() {
    final state = Provider.of<NotificationState>(context, listen: false);
    final authState = Provider.of<AuthState>(context, listen: false);
    state.databaseInit(authState.userId);
    state.initFirebaseService();
    _pushNotifSub = getIt<PushNotificationService>()
        .pushNotificationResponseStream
        .listen(_onPushNotification);
  }

  void _onPushNotification(PushNotificationModel model) {
    final authState = Provider.of<AuthState>(context, listen: false);
    final notifState = Provider.of<NotificationState>(context, listen: false);

    if (model.type == NotificationType.Message.toString() &&
        model.receiverId == authState.user!.uid) {
      notifState.getUserDetail(model.senderId).then((user) {
        final chatState = Provider.of<ChatState>(context, listen: false);
        chatState.setChatUser = user!;
        Navigator.pushNamed(context, '/ChatScreenPage');
      });
    } else if (model.type == NotificationType.Mention.toString() &&
        model.receiverId == authState.user!.uid) {
      final feedState = Provider.of<FeedState>(context, listen: false);
      feedState.getPostDetailFromDatabase(model.tweetId);
      Navigator.push(context, FeedPostDetail.getRoute(model.tweetId));
    }
  }

  void _initChat() {
    final chatState = Provider.of<ChatState>(context, listen: false);
    final authState = Provider.of<AuthState>(context, listen: false);
    chatState.databaseInit(authState.userId, authState.userId);
    authState.updateFCMToken();
    chatState.getFCMServerKey();
  }

  void _initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen(
      (PendingDynamicLinkData? data) async {
        final Uri? link = data?.link;
        if (link != null) _handleDeepLink(link);
      },
      onError: (e) async {
        cprint(e.message, errorIn: 'onLinkError');
      },
    );

    final PendingDynamicLinkData? initial =
        await FirebaseDynamicLinks.instance.getInitialLink();
    if (initial?.link != null) _handleDeepLink(initial!.link!);
  }

  void _handleDeepLink(Uri link) {
    cprint('Deep link: ${link.path}');
    final parts = link.path.split('/');
    if (parts.length < 3) return;
    final type = parts[1];
    final id = parts[2];
    if (type == 'profilePage') {
      Navigator.push(context, ProfilePage.getRoute(profileId: id));
    } else if (type == 'tweet') {
      final feedState = Provider.of<FeedState>(context, listen: false);
      feedState.getPostDetailFromDatabase(id);
      Navigator.push(context, FeedPostDetail.getRoute(id));
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
  }

  /// Navigate to ComposeTweetPage (Feed FAB action).
  void _openCompose() {
    Navigator.pushNamed(context, '/ComposeTweetPage/tweet');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    context.read<SuggestionsState>().initUser(authState.userModel);

    if (context
        .select<SuggestionsState, bool>((s) => s.displaySuggestions)) {
      return const SuggestedUsers();
    }

    return Scaffold(
      key: _scaffoldKey,
      // Darkest cinder background for the IndexedStack container.
      backgroundColor: _kStackBg,
      // FAB is only visible on the Feed tab (index 0).
      floatingActionButton: _currentIndex == _kFeedTab
          ? FloatingActionButton(
              onPressed: _openCompose,
              backgroundColor: _kNavActive,
              tooltip: 'Compose Tweet',
              child: const Icon(Icons.edit, color: Color(0xFFF2EDE8)),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0 – Feed
          FeedPage(
            scaffoldKey: _scaffoldKey,
            refreshIndicatorKey: _refreshIndicatorKey,
          ),
          // Tab 1 – Explore (existing SearchPage, no redesign required)
          SearchPage(scaffoldKey: _scaffoldKey),
          // Tab 2 – Notifications
          NotificationPage(scaffoldKey: _scaffoldKey),
          // Tab 3 – Messages
          ChatListPage(scaffoldKey: _scaffoldKey),
          // Tab 4 – Bookmarks
          ChangeNotifierProvider(
            create: (_) => BookmarkState(),
            child: const BookmarkPage(),
          ),
        ],
      ),
      bottomNavigationBar: _HomeBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HomeBottomNav – 5-item BottomNavigationBar (Cinder Rust palette)
// ---------------------------------------------------------------------------

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kNavBackground,
        border: Border(
          top: BorderSide(color: Color(0xFF3A2E28), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        // Transparent so the Container decoration shows through.
        backgroundColor: Colors.transparent,
        selectedItemColor: _kNavActive,
        unselectedItemColor: _kNavInactive,
        selectedLabelStyle: GoogleFonts.mulish(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: _kNavActive,
        ),
        unselectedLabelStyle: GoogleFonts.mulish(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: _kNavInactive,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            activeIcon: Icon(Icons.mail),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
        ],
      ),
    );
  }
}
