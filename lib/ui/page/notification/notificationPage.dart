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
// _NotifGroup – the three section types shown in the grouped list
// ---------------------------------------------------------------------------
class _NotifGroup {
  final String label;
  final IconData icon;
  final Color iconColor;
  final List<NotificationModel> items;

  const _NotifGroup({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.items,
  });
}

// ---------------------------------------------------------------------------
// NotificationPage – grouped by type: Likes, Retweets, Follows
// ---------------------------------------------------------------------------

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<NotificationState>(context, listen: false);
      final authState = Provider.of<AuthState>(context, listen: false);
      state.getDataFromDatabase(authState.userId);
    });
  }

  /// Build the three groups from the flat notification list.
  List<_NotifGroup> _buildGroups(List<NotificationModel> all) {
    final likes = all
        .where((n) => n.type == NotificationType.Like.toString())
        .toList();
    final retweets = all
        .where((n) => n.type == NotificationType.Retweet.toString())
        .toList();
    final follows = all
        .where((n) => n.type == NotificationType.Follow.toString())
        .toList();

    return [
      _NotifGroup(
        label: 'Likes',
        icon: Icons.favorite,
        iconColor: const Color(0xFFE0245E),
        items: likes,
      ),
      _NotifGroup(
        label: 'Retweets',
        icon: Icons.repeat,
        iconColor: const Color(0xFF17BF63),
        items: retweets,
      ),
      _NotifGroup(
        label: 'Follows',
        icon: Icons.person_add,
        iconColor: _kPrimary,
        items: follows,
      ),
    ];
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
      ),
      body: Consumer<NotificationState>(
        builder: (context, state, _) {
          if (state.isbusy) {
            return const LinearProgressIndicator(color: _kPrimary);
          }

          final all = state.notificationList ?? [];

          if (all.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: EmptyList(
                'No notifications yet',
                subTitle:
                    'When someone interacts with you, it will show up here.',
              ),
            );
          }

          final groups = _buildGroups(all);
          // Build a flat list of section headers + items
          final List<Widget> rows = [];
          for (final group in groups) {
            if (group.items.isEmpty) continue;
            rows.add(_SectionHeader(
              label: group.label,
              icon: group.icon,
              iconColor: group.iconColor,
            ));
            for (final item in group.items) {
              rows.add(_NotificationItem(model: item));
            }
          }

          if (rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: EmptyList(
                'No notifications yet',
                subTitle:
                    'When someone interacts with you, it will show up here.',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: rows,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionHeader – bold Mulish section label with a coloured icon
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    Key? key,
    required this.label,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.mulish(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _kSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NotificationItem – single notification card (Material Card, radius 12px)
// ---------------------------------------------------------------------------

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({Key? key, required this.model}) : super(key: key);
  final NotificationModel model;

  bool get _isFollow => model.type == NotificationType.Follow.toString();
  bool get _isLike => model.type == NotificationType.Like.toString();

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        side: const BorderSide(color: _kExtraLight),
      ),
      elevation: 0,
      color: Colors.white,
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
// _ReferencedTweetPreview – inline tweet snippet shown beneath a notification
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
            final feedState = Provider.of<FeedState>(context, listen: false);
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
                // Tweet body
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
