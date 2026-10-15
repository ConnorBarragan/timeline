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
import 'package:flutter_twitter_clone/ui/page/feed/feedPage.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/feed/suggestedUsers.dart';
import 'package:flutter_twitter_clone/ui/page/message/chatListPage.dart';
import 'package:flutter_twitter_clone/ui/page/notification/notificationPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'common/locator.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
const Color _kPrimary = Color(0xFF1DA1F2);
const Color _kSecondary = Color(0xFF14171A);
const Color _kExtraLight = Color(0xFFE1E8ED);
const Color _kBackground = Color(0xFFF5F8FA);

// ---------------------------------------------------------------------------
// HomePage – BottomNavigationBar shell with 4 tabs
//
// Tabs:  0 = Feed  |  1 = Notifications  |  2 = Messages  |  3 = Profile
//
// The Profile tab (index 3) pushes ProfilePage as a named route so the user
// can navigate back to the shell.  The first three tabs are kept alive inside
// an IndexedStack so scroll position is preserved.
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

  /// Visible tab index (0–2 map to Feed/Notifications/Messages;
  /// tapping 3 pushes ProfilePage without changing this index).
  int _currentIndex = 0;

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
    if (index == 3) {
      // Profile tab → push as a full route so the user can navigate back
      final authState = Provider.of<AuthState>(context, listen: false);
      if (authState.userModel?.userId != null) {
        Navigator.push(
          context,
          ProfilePage.getRoute(profileId: authState.userModel!.userId!),
        );
      }
      return;
    }
    setState(() => _currentIndex = index);
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
      backgroundColor: _kBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0 – Feed
          FeedPage(
            scaffoldKey: _scaffoldKey,
            refreshIndicatorKey: _refreshIndicatorKey,
          ),
          // Tab 1 – Notifications
          NotificationPage(scaffoldKey: _scaffoldKey),
          // Tab 2 – Messages
          ChatListPage(scaffoldKey: _scaffoldKey),
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
// _HomeBottomNav – 4-item BottomNavigationBar
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
        color: Colors.white,
        border: Border(top: BorderSide(color: _kExtraLight)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _kPrimary,
        unselectedItemColor: _kSecondary,
        selectedLabelStyle: GoogleFonts.mulish(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.mulish(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
