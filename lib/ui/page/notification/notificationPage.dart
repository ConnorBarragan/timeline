import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/notificationModel.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/state/notificationState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/emptyList.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
const Color _kPrimary = Color(0xFF1DA1F2);
const Color _kSecondary = Color(0xFF14171A);
const Color _kLightGrey = Color(0xFFAAB8C2);
const Color _kExtraLight = Color(0xFFE1E8ED);
const Color _kBackground = Color(0xFFF5F8FA);
const double _kRadius = 12.0;

// ---------------------------------------------------------------------------
// Filter enum – exactly 3 values: All, Likes, Follows
// ---------------------------------------------------------------------------
enum _NotifFilter { all, likes, follows }

// ---------------------------------------------------------------------------
// NotificationPage – NotificationHub
// ---------------------------------------------------------------------------

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  _NotifFilter _activeFilter = _NotifFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<NotificationState>(context, listen: false);
      final authState = Provider.of<AuthState>(context, listen: false);
      state.getDataFromDatabase(authState.userId);
    });
  }

  List<NotificationModel> _applyFilter(List<NotificationModel> list) {
    switch (_activeFilter) {
      case _NotifFilter.all:
        return list;
      case _NotifFilter.likes:
        return list
            .where((n) => n.type == NotificationType.Like.toString())
            .toList();
      case _NotifFilter.follows:
        return list
            .where((n) => n.type == NotificationType.Follow.toString())
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.mulish(
            color: _kSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _kSecondary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FilterChipRow(
            activeFilter: _activeFilter,
            onFilterChanged: (f) => setState(() => _activeFilter = f),
          ),
        ),
      ),
      body: Consumer<NotificationState>(
        builder: (context, state, _) {
          if (state.isbusy) {
            return const LinearProgressIndicator(color: _kPrimary);
          }

          final all = state.notificationList ?? [];
          final filtered = _applyFilter(all);

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: EmptyList(
                _emptyTitle,
                subTitle: _emptySubtitle,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) =>
                _NotificationItem(model: filtered[index]),
          );
        },
      ),
    );
  }

  String get _emptyTitle {
    switch (_activeFilter) {
      case _NotifFilter.all:
        return 'No notifications yet';
      case _NotifFilter.likes:
        return 'No likes yet';
      case _NotifFilter.follows:
        return 'No follows yet';
    }
  }

  String get _emptySubtitle {
    switch (_activeFilter) {
      case _NotifFilter.all:
        return 'When someone interacts with you, it will show up here.';
      case _NotifFilter.likes:
        return 'When someone likes your tweet, it will show up here.';
      case _NotifFilter.follows:
        return 'When someone follows you, it will show up here.';
    }
  }
}

// ---------------------------------------------------------------------------
// NotificationBottomSheet – slide-up sheet used by feedPage.dart
// ---------------------------------------------------------------------------

class NotificationBottomSheet extends StatefulWidget {
  const NotificationBottomSheet({Key? key}) : super(key: key);

  @override
  State<NotificationBottomSheet> createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  _NotifFilter _filter = _NotifFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<NotificationState>(context, listen: false);
      final authState = Provider.of<AuthState>(context, listen: false);
      state.getDataFromDatabase(authState.userId);
    });
  }

  List<NotificationModel> _applyFilter(List<NotificationModel> list) {
    switch (_filter) {
      case _NotifFilter.all:
        return list;
      case _NotifFilter.likes:
        return list
            .where((n) => n.type == NotificationType.Like.toString())
            .toList();
      case _NotifFilter.follows:
        return list
            .where((n) => n.type == NotificationType.Follow.toString())
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _kExtraLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.mulish(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _kExtraLight),
              // Filter chips row
              _FilterChipRow(
                activeFilter: _filter,
                onFilterChanged: (f) => setState(() => _filter = f),
              ),
              const Divider(height: 1, color: _kExtraLight),
              // Notification list
              Expanded(
                child: Consumer<NotificationState>(
                  builder: (context, state, _) {
                    if (state.isbusy) {
                      return const LinearProgressIndicator(color: _kPrimary);
                    }
                    final list = _applyFilter(state.notificationList ?? []);
                    if (list.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: EmptyList(
                          'No notifications yet',
                          subTitle:
                              'When someone interacts with you, it will show up here.',
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: list.length,
                      itemBuilder: (context, index) =>
                          _NotificationItem(model: list[index]),
                    );
                  },
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
// _FilterChipRow – exactly 3 FilterChip widgets: All, Likes, Follows
// ---------------------------------------------------------------------------

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    Key? key,
    required this.activeFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  final _NotifFilter activeFilter;
  final ValueChanged<_NotifFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // Chip 1: All
          FilterChip(
            label: Text(
              'All',
              style: GoogleFonts.mulish(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: activeFilter == _NotifFilter.all
                    ? Colors.white
                    : _kSecondary,
              ),
            ),
            selected: activeFilter == _NotifFilter.all,
            onSelected: (_) => onFilterChanged(_NotifFilter.all),
            selectedColor: _kPrimary,
            backgroundColor: _kBackground,
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: activeFilter == _NotifFilter.all
                  ? _kPrimary
                  : _kExtraLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kRadius),
            ),
          ),
          const SizedBox(width: 8),
          // Chip 2: Likes
          FilterChip(
            label: Text(
              'Likes',
              style: GoogleFonts.mulish(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: activeFilter == _NotifFilter.likes
                    ? Colors.white
                    : _kSecondary,
              ),
            ),
            selected: activeFilter == _NotifFilter.likes,
            onSelected: (_) => onFilterChanged(_NotifFilter.likes),
            selectedColor: _kPrimary,
            backgroundColor: _kBackground,
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: activeFilter == _NotifFilter.likes
                  ? _kPrimary
                  : _kExtraLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kRadius),
            ),
          ),
          const SizedBox(width: 8),
          // Chip 3: Follows
          FilterChip(
            label: Text(
              'Follows',
              style: GoogleFonts.mulish(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: activeFilter == _NotifFilter.follows
                    ? Colors.white
                    : _kSecondary,
              ),
            ),
            selected: activeFilter == _NotifFilter.follows,
            onSelected: (_) => onFilterChanged(_NotifFilter.follows),
            selectedColor: _kPrimary,
            backgroundColor: _kBackground,
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: activeFilter == _NotifFilter.follows
                  ? _kPrimary
                  : _kExtraLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kRadius),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NotificationItem – single notification card
// ---------------------------------------------------------------------------

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({Key? key, required this.model}) : super(key: key);
  final NotificationModel model;

  bool get _isFollow =>
      model.type == NotificationType.Follow.toString();
  bool get _isLike =>
      model.type == NotificationType.Like.toString();

  IconData get _icon {
    if (_isLike) return Icons.favorite;
    if (_isFollow) return Icons.person_add;
    if (model.type == NotificationType.Retweet.toString()) return Icons.repeat;
    return Icons.notifications;
  }

  Color get _iconColor {
    if (_isLike) return const Color(0xFFE0245E);
    if (_isFollow) return _kPrimary;
    if (model.type == NotificationType.Retweet.toString()) {
      return const Color(0xFF17BF63);
    }
    return _kPrimary;
  }

  String get _actionText {
    if (_isLike) return 'liked your tweet';
    if (_isFollow) return 'followed you';
    if (model.type == NotificationType.Retweet.toString()) {
      return 'retweeted your tweet';
    }
    return 'interacted with you';
  }

  @override
  Widget build(BuildContext context) {
    final user = model.user;
    final displayName = user.displayName ?? user.userName ?? 'Someone';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kExtraLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(_kRadius),
            onTap: user.userId != null
                ? () => Navigator.push(
                      context,
                      ProfilePage.getRoute(profileId: user.userId!),
                    )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: _iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  // Avatar
                  CircularImage(path: user.profilePic, height: 36),
                  const SizedBox(width: 10),
                  // Name + action
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: displayName,
                            style: GoogleFonts.mulish(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: _kSecondary,
                            ),
                          ),
                          TextSpan(
                            text: ' $_actionText',
                            style: GoogleFonts.mulish(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: _kLightGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Referenced tweet preview (for non-follow notifications) ──
          if (!_isFollow && model.tweetKey != null)
            _ReferencedTweetPreview(tweetKey: model.tweetKey!),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ReferencedTweetPreview – public widget for external use
// ---------------------------------------------------------------------------

class ReferencedTweetPreview extends StatelessWidget {
  const ReferencedTweetPreview({Key? key, required this.tweetKey})
      : super(key: key);

  final String tweetKey;

  @override
  Widget build(BuildContext context) {
    return _ReferencedTweetPreview(tweetKey: tweetKey);
  }
}

// ---------------------------------------------------------------------------
// _ReferencedTweetPreview – inline tweet card shown beneath a notification
// ---------------------------------------------------------------------------

class _ReferencedTweetPreview extends StatelessWidget {
  const _ReferencedTweetPreview({Key? key, required this.tweetKey})
      : super(key: key);

  final String tweetKey;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<NotificationState>(context, listen: false);

    return FutureBuilder<FeedModel?>(
      future: state.getTweetDetail(tweetKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: LinearProgressIndicator(
              color: _kPrimary,
              minHeight: 2,
            ),
          );
        }

        final tweet = snapshot.data;
        if (tweet == null) return const SizedBox.shrink();

        return InkWell(
          onTap: () {
            final feedState =
                Provider.of<FeedState>(context, listen: false);
            feedState.getPostDetailFromDatabase(null, model: tweet);
            Navigator.push(context, FeedPostDetail.getRoute(tweet.key!));
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kBackground,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: _kExtraLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    CircularImage(
                      path: tweet.user?.profilePic,
                      height: 24,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tweet.user?.displayName ?? '',
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _kSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '@${tweet.user?.userName ?? ''}',
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        color: _kLightGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Tweet text
                if (tweet.description != null &&
                    tweet.description!.isNotEmpty)
                  Text(
                    tweet.description!,
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      color: _kSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Tweet image thumbnail
                if (tweet.imagePath != null && tweet.imagePath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_kRadius),
                      child: CachedNetworkImage(
                        imageUrl: tweet.imagePath!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
