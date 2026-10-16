import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/state/searchState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/ui/theme/app_theme.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/customLoader.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/emptyList.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// FeedPage – Live Tweet Feed with Online Users stat badge
// ---------------------------------------------------------------------------

class FeedPage extends StatefulWidget {
  const FeedPage({
    Key? key,
    required this.scaffoldKey,
    this.refreshIndicatorKey,
  }) : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: const _FeedAppBar(),
      body: _TweetListBody(
        refreshIndicatorKey: widget.refreshIndicatorKey,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FeedAppBar – dark #1C1410 AppBar with title and Online Users emerald badge
// ---------------------------------------------------------------------------

class _FeedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FeedAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Cinder Rust: deep charcoal-brown AppBar background
      backgroundColor: kSecondaryColor,
      elevation: 0,
      title: Text(
        'Feed',
        style: GoogleFonts.mulish(
          color: kOffWhiteColor,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      actions: [
        // Online Users stat badge (bound to firebase_rtdb:profile via SearchState)
        const _OnlineUsersBadge(),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _OnlineUsersBadge – emerald pill chip showing the count of registered/online users
//
// Bound to firebase_rtdb:profile via SearchState (the same node that
// getDataFromDatabase() subscribes to).  Displays the total user count as a
// proxy for "online users" since the Firebase schema has no explicit
// presence/online field.
// ---------------------------------------------------------------------------

class _OnlineUsersBadge extends StatelessWidget {
  const _OnlineUsersBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchState>(
      builder: (context, searchState, _) {
        final count = searchState.userlist?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              // Timeline Night: emerald accent for the badge
              color: kEmeraldAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF17BF63), // green online dot
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count online',
                  style: GoogleFonts.mulish(
                    color: kOffWhiteColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

// ---------------------------------------------------------------------------
// _TweetListBody – RefreshIndicator + ListView of tweet cards
// ---------------------------------------------------------------------------

class _TweetListBody extends StatelessWidget {
  const _TweetListBody({Key? key, this.refreshIndicatorKey}) : super(key: key);

  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: false);

    return Consumer<FeedState>(
      builder: (context, state, _) {
        final List<FeedModel>? list = state.getTweetList(authState.userModel);

        if (state.isBusy && list == null) {
          return CustomScreenLoader(
            height: double.infinity,
            width: double.infinity,
            backgroundColor: kBackgroundColor,
          );
        }

        if (!state.isBusy && (list == null || list.isEmpty)) {
          return const EmptyList(
            'No Tweets yet',
            subTitle: 'Pull down to refresh or tap the compose button.',
          );
        }

        return RefreshIndicator(
          key: refreshIndicatorKey,
          // Timeline Night: emerald accent for refresh spinner
          color: kEmeraldAccent,
          backgroundColor: kExtraLightColor,
          onRefresh: () async {
            state.getDataFromDatabase();
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: list!.length,
            separatorBuilder: (_, __) => Divider(
              color: kLightGreyColor,
              height: 1,
              thickness: 1,
            ),
            itemBuilder: (context, index) => _TweetCard(model: list[index]),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _TweetCard – Timeline Night card with #1E2329 surface and 16px radius
// ---------------------------------------------------------------------------

class _TweetCard extends StatelessWidget {
  const _TweetCard({Key? key, required this.model}) : super(key: key);

  final FeedModel model;

  @override
  Widget build(BuildContext context) {
    final user = model.user;
    final displayName = user?.displayName ?? '';
    final userName = user?.userName ?? '';
    final hasImage = model.imagePath != null && model.imagePath!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        final feedState = Provider.of<FeedState>(context, listen: false);
        feedState.getPostDetailFromDatabase(model.key, model: model);
        Navigator.push(context, FeedPostDetail.getRoute(model.key));
      },
      child: Container(
        // ── Timeline Night card surface: #1E2329 with 16px radius ──
        decoration: BoxDecoration(
          color: kTweetCardSurface,
          borderRadius: BorderRadius.circular(kTweetCardRadius),
          border: Border.all(
            color: kBackgroundColor,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tweet header: avatar, name, handle, timestamp ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircularImage(
                  path: user?.profilePic,
                  width: 44,
                  height: 44,
                ),
                const SizedBox(width: 10),

                // Author info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.mulish(
                          color: kOffWhiteColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '@$userName',
                        style: GoogleFonts.mulish(
                          color: kLightGreyColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Timestamp
                Text(
                  _formatTime(model.createdAt),
                  style: GoogleFonts.mulish(
                    color: kLightGreyColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            // ── Tweet body text ────────────────────────────────────────
            if (model.description != null && model.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                model.description!,
                style: GoogleFonts.mulish(
                  // Cinder Rust: off-white body text on dark card
                  color: kOffWhiteColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ],

            // ── Tweet image ────────────────────────────────────────────
            if (hasImage) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(kTweetCardRadius),
                child: Image.network(
                  model.imagePath!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      color: kExtraLightColor,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: kEmeraldAccent,
                          strokeWidth: 2,
                        ),
                      );
                    );
                  },
                ),
              ),
            ],

            // ── Inline Like + Retweet action row ──────────────────────
            const SizedBox(height: 10),
            _TweetActionRow(model: model),
          ],
        ),
      ),
    );
  }

  /// Format timestamp to relative time (e.g., "2h", "1d")
  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) {
        return 'now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d';
      } else {
        return dateTime.toString().split(' ')[0];
      }
    } catch (e) {
      return '';
    }
  }
}

// ---------------------------------------------------------------------------
// _TweetActionRow – Like, Retweet, and Comment inline IconButtons
// ---------------------------------------------------------------------------

class _TweetActionRow extends StatelessWidget {
  const _TweetActionRow({Key? key, required this.model}) : super(key: key);

  final FeedModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Comment
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          count: model.commentCount ?? 0,
          activeColor: kEmeraldAccent,
          onTap: () {
            final feedState =
                Provider.of<FeedState>(context, listen: false);
            feedState.setTweetToReply = model;
            Navigator.pushNamed(context, '/ComposeTweetPage/reply');
          },
        ),
        const SizedBox(width: 16),
        // Retweet
        _ActionButton(
          icon: Icons.repeat,
          count: model.retweetCount ?? 0,
          activeColor: kRetweetColor,
          onTap: () {
            final feedState =
                Provider.of<FeedState>(context, listen: false);
            feedState.setTweetToReply = model;
            Navigator.pushNamed(context, '/ComposeTweetPage/retweet');
          },
        ),
        const SizedBox(width: 16),
        // Like
        _ActionButton(
          icon: Icons.favorite_border,
          count: model.likeCount ?? 0,
          activeColor: kLikeColor,
          onTap: () {
            final feedState =
                Provider.of<FeedState>(context, listen: false);
            final authState =
                Provider.of<AuthState>(context, listen: false);
            feedState.addLikeToTweet(model, authState.userId);
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ActionButton – small icon + count label with tap ripple
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    Key? key,
    required this.icon,
    required this.count,
    required this.activeColor,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final int count;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: kLightGreyColor),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: GoogleFonts.mulish(
                color: kLightGreyColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
