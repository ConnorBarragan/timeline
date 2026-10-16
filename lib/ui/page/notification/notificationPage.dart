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
import 'package:flutter_twitter_clone/ui/theme/app_theme.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/emptyList.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// NotificationPage – chronological activity feed
//
// Shows all notification types (likes, retweets, follows, mentions, replies)
// sorted newest-first.  Items that reference a tweet show an inline
// "Referenced Tweet Preview" card (12 px radius, Mulish font, rust #C0522B
// left-border accent).
// ---------------------------------------------------------------------------

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<NotificationState>(context, listen: false);
      final authState = Provider.of<AuthState>(context, listen: false);
      state.getDataFromDatabase(authState.userId);
    });
  }

  Future<void> _onRefresh() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    Provider.of<NotificationState>(context, listen: false)
        .getDataFromDatabase(authState.userId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kSecondaryColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.mulish(
            color: kOffWhiteColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: kOffWhiteColor),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: kExtraLightColor),
        ),
      ),
      body: Consumer<NotificationState>(
        builder: (context, state, _) {
          if (state.isbusy) {
            return const LinearProgressIndicator(
              color: kPrimaryColor,
              minHeight: 3,
            );
          }

          final all = List<NotificationModel>.from(
            state.notificationList ?? [],
          );

          if (all.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: EmptyList(
                'No notifications yet',
                subTitle:
                    'When someone likes, retweets, or follows you, it will show up here.',
              ),
            );
          }

          // Sort chronologically – newest first.
          all.sort((a, b) {
            final ta = a.timeStamp;
            final tb = b.timeStamp;
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });

          return RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: all.length,
              itemBuilder: (context, index) =>
                  _NotificationItem(model: all[index]),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NotificationItem – single activity card (12 px radius, Mulish)
// ---------------------------------------------------------------------------

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({Key? key, required this.model}) : super(key: key);

  final NotificationModel model;

  // ── Type helpers ──────────────────────────────────────────────────────────

  bool get _isFollow =>
      model.type == NotificationType.Follow.toString();
  bool get _isLike =>
      model.type == NotificationType.Like.toString();
  bool get _isRetweet =>
      model.type == NotificationType.Retweet.toString();
  bool get _isMention =>
      model.type == NotificationType.Mention.toString();
  bool get _isReply =>
      model.type == NotificationType.Reply.toString();

  /// Whether this notification references a tweet (and should show a preview).
  bool get _hasTweetRef =>
      !_isFollow && model.tweetKey != null && model.tweetKey!.isNotEmpty;

  IconData get _icon {
    if (_isLike) return Icons.favorite;
    if (_isFollow) return Icons.person_add;
    if (_isRetweet) return Icons.repeat;
    if (_isMention) return Icons.alternate_email;
    if (_isReply) return Icons.chat_bubble;
    return Icons.notifications;
  }

  Color get _iconColor {
    if (_isLike) return kLikeColor;
    if (_isFollow) return kPrimaryColor;
    if (_isRetweet) return kRetweetColor;
    if (_isMention) return kPrimaryColor;
    if (_isReply) return kPrimaryColor;
    return kPrimaryColor;
  }

  String get _actionText {
    if (_isLike) return 'liked your tweet';
    if (_isFollow) return 'followed you';
    if (_isRetweet) return 'retweeted your tweet';
    if (_isMention) return 'mentioned you';
    if (_isReply) return 'replied to your tweet';
    return 'interacted with you';
  }

  @override
  Widget build(BuildContext context) {
    final user = model.user;
    final displayName = user.displayName ?? user.userName ?? 'Someone';
    final ts = model.timeStamp;
    final timeLabel = ts != null ? _formatTime(ts) : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: const BorderSide(color: kExtraLightColor),
      ),
      elevation: 0,
      // Activity card background: dark card surface #3A2E28
      color: kExtraLightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(kCardRadius),
            onTap: user.userId != null
                ? () => Navigator.push(
                      context,
                      ProfilePage.getRoute(profileId: user.userId!),
                    )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coloured icon badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: _iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  // User avatar
                  CircularImage(path: user.profilePic, height: 36),
                  const SizedBox(width: 10),
                  // Name + action text + timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: displayName,
                                style: GoogleFonts.mulish(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  // Display name: off-white #F2EDE8
                                  color: kOffWhiteColor,
                                ),
                              ),
                              TextSpan(
                                text: ' $_actionText',
                                style: GoogleFonts.mulish(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  // Action text: taupe #8C7B72
                                  color: kLightGreyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (timeLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              // Timestamp: taupe #8C7B72
                              color: kLightGreyColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Referenced tweet preview ─────────────────────────────────
          if (_hasTweetRef)
            _ReferencedTweetPreview(tweetKey: model.tweetKey!),
        ],
      ),
    );
  }

  /// Human-readable relative time label.
  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }
}

// ---------------------------------------------------------------------------
// ReferencedTweetPreview – public widget (used by other screens if needed)
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
// _ReferencedTweetPreview – inline tweet snippet
//   background #2A1F1A, 3 px left border rust #C0522B, radius 12 px, Mulish
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: LinearProgressIndicator(
              color: kPrimaryColor,
              minHeight: 2,
            ),
          );
        }

        final tweet = snapshot.data;
        if (tweet == null) return const SizedBox.shrink();

        final hasImage =
            tweet.imagePath != null && tweet.imagePath!.isNotEmpty;

        return InkWell(
          onTap: () {
            final feedState =
                Provider.of<FeedState>(context, listen: false);
            feedState.getPostDetailFromDatabase(null, model: tweet);
            Navigator.push(context, FeedPostDetail.getRoute(tweet.key!));
          },
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(kCardRadius),
            bottomRight: Radius.circular(kCardRadius),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Inset background: darkest cinder #2A1F1A
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(kCardRadius),
              // 3 px left border in rust #C0522B; other sides transparent
              border: Border(
                left: const BorderSide(color: kPrimaryColor, width: 3),
                top: BorderSide(color: kExtraLightColor.withOpacity(0.5)),
                right: BorderSide(color: kExtraLightColor.withOpacity(0.5)),
                bottom: BorderSide(color: kExtraLightColor.withOpacity(0.5)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Author row ───────────────────────────────────────
                Row(
                  children: [
                    CircularImage(
                      path: tweet.user?.profilePic,
                      height: 22,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tweet.user?.displayName ?? '',
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          // Author name: off-white #F2EDE8
                          color: kOffWhiteColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '@${tweet.user?.userName ?? ''}',
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        // Handle: taupe #8C7B72
                        color: kLightGreyColor,
                      ),
                    ),
                  ],
                ),
                // ── Tweet body ───────────────────────────────────────
                if (tweet.description != null &&
                    tweet.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    tweet.description!,
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      // Body text: off-white #F2EDE8
                      color: kOffWhiteColor,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // ── Tweet image thumbnail ────────────────────────────
                if (hasImage) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    child: CachedNetworkImage(
                      imageUrl: tweet.imagePath!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
