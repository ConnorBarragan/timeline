import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/bookmarkState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/ui/theme/app_theme.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/emptyList.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// BookmarkPage – Bookmarks Tab
//
// AppBar shows a "Bookmark Count" stat bound to bookmarkState.tweetList.
// Body is a scrollable ListView of saved tweet cards, each with a trailing
// delete IconButton that calls bookmarkState.removeBookmark().
// Cards use 12 px radius, Mulish font, and #1DA1F2 primary colour.
// ---------------------------------------------------------------------------

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({Key? key}) : super(key: key);

  static Route<T> getRoute<T>() {
    return MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => BookmarkState(),
        child: const BookmarkPage(),
      ),
    );
  }

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<BookmarkState>(
      builder: (context, state, _) {
        final count = state.tweetList?.length ?? 0;
        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: _BookmarkAppBar(bookmarkCount: count),
          body: _BookmarkBody(state: state),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _BookmarkAppBar – AppBar with title and bookmark count stat badge
// ---------------------------------------------------------------------------

class _BookmarkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BookmarkAppBar({Key? key, required this.bookmarkCount})
      : super(key: key);

  final int bookmarkCount;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Bookmarks',
        style: GoogleFonts.mulish(
          color: kSecondaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      iconTheme: const IconThemeData(color: kSecondaryColor),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: kExtraLightColor),
      ),
      actions: [
        // Bookmark count stat badge (bound to firebase_rtdb:bookmark via bookmarkState)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark, size: 14, color: kPrimaryColor),
                const SizedBox(width: 4),
                Text(
                  '$bookmarkCount saved',
                  style: GoogleFonts.mulish(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _BookmarkBody – loading / empty / list states
// ---------------------------------------------------------------------------

class _BookmarkBody extends StatelessWidget {
  const _BookmarkBody({Key? key, required this.state}) : super(key: key);

  final BookmarkState state;

  @override
  Widget build(BuildContext context) {
    if (state.isbusy) {
      return const LinearProgressIndicator(
        color: kPrimaryColor,
        minHeight: 3,
      );
    }

    final tweets = state.tweetList ?? [];

    if (tweets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: EmptyList(
          'No Bookmarks yet',
          subTitle:
              'Tap the bookmark icon on any tweet to save it here.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: tweets.length,
      itemBuilder: (context, index) =>
          _BookmarkCard(model: tweets[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// _BookmarkCard – saved tweet card with trailing remove button
// ---------------------------------------------------------------------------

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({Key? key, required this.model}) : super(key: key);

  final FeedModel model;

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = model.user;
    final displayName = user?.displayName ?? '';
    final userName = user?.userName ?? '';
    final hasImage = model.imagePath != null && model.imagePath!.isNotEmpty;
    final timeLabel = _formatTime(model.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: const BorderSide(color: kExtraLightColor),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(kCardRadius),
        onTap: () {
          final feedState =
              Provider.of<FeedState>(context, listen: false);
          feedState.getPostDetailFromDatabase(null, model: model);
          Navigator.push(context, FeedPostDetail.getRoute(model.key!));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: avatar + name + handle + time + remove btn ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircularImage(
                    path: user?.profilePic,
                    height: 42,
                  ),
                  const SizedBox(width: 10),
                  // Name + handle + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: GoogleFonts.mulish(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: kSecondaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user?.isVerified == true) ...[
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.verified,
                                size: 15,
                                color: kPrimaryColor,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '@$userName · $timeLabel',
                          style: GoogleFonts.mulish(
                            fontSize: 13,
                            color: kLightGreyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Remove / delete bookmark button
                  _RemoveBookmarkButton(tweetKey: model.key!),
                ],
              ),

              // ── Tweet body ──────────────────────────────────────────────
              if (model.description != null &&
                  model.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  model.description!,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    color: kSecondaryColor,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],

              // ── Tweet image ─────────────────────────────────────────────
              if (hasImage) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(kCardRadius),
                  child: CachedNetworkImage(
                    imageUrl: model.imagePath!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: kExtraLightColor,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: kPrimaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // ── Stat row: likes + retweets + comments ───────────────────
              const SizedBox(height: 10),
              _TweetStatRow(model: model),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RemoveBookmarkButton – trailing delete IconButton
// ---------------------------------------------------------------------------

class _RemoveBookmarkButton extends StatelessWidget {
  const _RemoveBookmarkButton({Key? key, required this.tweetKey})
      : super(key: key);

  final String tweetKey;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bookmark_remove_outlined),
      color: kLightGreyColor,
      tooltip: 'Remove bookmark',
      splashRadius: 20,
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kCardRadius),
            ),
            title: Text(
              'Remove Bookmark',
              style: GoogleFonts.mulish(
                fontWeight: FontWeight.w800,
                color: kSecondaryColor,
              ),
            ),
            content: Text(
              'Remove this tweet from your bookmarks?',
              style: GoogleFonts.mulish(color: kSecondaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.mulish(color: kLightGreyColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Remove',
                  style: GoogleFonts.mulish(
                    color: kLikeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          Provider.of<BookmarkState>(context, listen: false)
              .removeBookmark(tweetKey);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _TweetStatRow – compact like / retweet / comment counts
// ---------------------------------------------------------------------------

class _TweetStatRow extends StatelessWidget {
  const _TweetStatRow({Key? key, required this.model}) : super(key: key);

  final FeedModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.favorite_border,
          count: model.likeCount ?? 0,
          color: kLikeColor,
        ),
        const SizedBox(width: 16),
        _StatChip(
          icon: Icons.repeat,
          count: model.retweetCount ?? 0,
          color: kRetweetColor,
        ),
        const SizedBox(width: 16),
        _StatChip(
          icon: Icons.chat_bubble_outline,
          count: model.commentCount ?? 0,
          color: kPrimaryColor,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    Key? key,
    required this.icon,
    required this.count,
    required this.color,
  }) : super(key: key);

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: kLightGreyColor),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.mulish(
            fontSize: 12,
            color: kLightGreyColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BookmarkPageBody – kept for any legacy references
// ---------------------------------------------------------------------------

class BookmarkPageBody extends StatelessWidget {
  const BookmarkPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkState>(
      builder: (context, state, _) => _BookmarkBody(state: state),
    );
  }
}
