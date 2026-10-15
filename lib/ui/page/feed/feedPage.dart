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
      appBar: _FeedAppBar(),
      body: _TweetListBody(
        refreshIndicatorKey: widget.refreshIndicatorKey,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FeedAppBar – AppBar with title and Online Users stat badge
// ---------------------------------------------------------------------------

class _FeedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FeedAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Feed',
        style: GoogleFonts.mulish(
          color: kSecondaryColor,
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
// _OnlineUsersBadge – chip showing the count of registered/online users
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
              color: kPrimaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
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
                    color: kPrimaryColor,
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
          color: kPrimaryColor,
          onRefresh: () async {
            state.getDataFromDatabase();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: list!.length,
            itemBuilder: (context, index) => _TweetCard(model: list[index]),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _TweetCard – Material Card with avatar, name, handle, body, optional image,
//              and inline Like / Retweet IconButtons
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(kCardRadius),
        onTap: () {
          final feedState = Provider.of<FeedState>(context, listen: false);
          feedState.getPostDetailFromDatabase(null, model: model);
          Navigator.push(context, FeedPostDetail.getRoute(model.key!));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar + name row ──────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircularImage(
                    path: user?.profilePic ?? Constants.dummyProfilePic,
                    height: 44,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.mulish(
                            color: kSecondaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  if (model.createdAt.isNotEmpty)
                    Text(
                      Utility.getPostTime2(model.createdAt),
                      style: GoogleFonts.mulish(
                        color: kLightGreyColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),

              // ── Tweet body ─────────────────────────────────────────────
              if (model.description != null &&
                  model.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  model.description!,
                  style: GoogleFonts.mulish(
                    color: kSecondaryColor,
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
                  borderRadius: BorderRadius.circular(kCardRadius),
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
                            color: kPrimaryColor,
                            strokeWidth: 2,
                          ),
                        ),
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
      ),
    );
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
          activeColor: kPrimaryColor,
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
