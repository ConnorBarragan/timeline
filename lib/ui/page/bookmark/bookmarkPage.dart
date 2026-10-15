import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/bookmarkState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
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
// BookmarkPage – BookmarkShelf
// ---------------------------------------------------------------------------

class BookmarkPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Bookmarks',
          style: GoogleFonts.mulish(
            color: _kSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _kSecondary),
      ),
      body: const _BookmarkShelfBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// _BookmarkShelfBody – stateful body with tag filter, grid, and list
// ---------------------------------------------------------------------------

class _BookmarkShelfBody extends StatefulWidget {
  const _BookmarkShelfBody({Key? key}) : super(key: key);

  @override
  State<_BookmarkShelfBody> createState() => _BookmarkShelfBodyState();
}

class _BookmarkShelfBodyState extends State<_BookmarkShelfBody> {
  String? _activeTag; // null = show all
  String? _expandedTweetKey; // key of the tweet whose preview is expanded

  /// Collect all unique tags from the tweet list.
  List<String> _collectTags(List<FeedModel> tweets) {
    final tags = <String>{};
    for (final tweet in tweets) {
      if (tweet.tags != null) {
        tags.addAll(tweet.tags!);
      }
    }
    return tags.toList()..sort();
  }

  /// Filter tweets by the active tag.
  List<FeedModel> _filterTweets(List<FeedModel> tweets) {
    if (_activeTag == null) return tweets;
    return tweets
        .where((t) => t.tags != null && t.tags!.contains(_activeTag))
        .toList();
  }

  /// Tweets that have an image (for the media grid).
  List<FeedModel> _mediaTweets(List<FeedModel> tweets) {
    return tweets
        .where((t) => t.imagePath != null && t.imagePath!.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkState>(
      builder: (context, state, _) {
        if (state.isbusy) {
          return const LinearProgressIndicator(color: _kPrimary);
        }

        final allTweets = state.tweetList ?? [];

        if (allTweets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: EmptyList(
              'No Bookmarks yet',
              subTitle: 'Tap the bookmark icon on any tweet to save it here.',
            ),
          );
        }

        final tags = _collectTags(allTweets);
        final filtered = _filterTweets(allTweets);
        final mediaTweets = _mediaTweets(filtered);

        return CustomScrollView(
          slivers: [
            // ── Tag filter chips ──────────────────────────────────────
            if (tags.isNotEmpty)
              SliverToBoxAdapter(
                child: _TagFilterRow(
                  tags: tags,
                  activeTag: _activeTag,
                  onTagChanged: (tag) =>
                      setState(() => _activeTag = tag),
                ),
              ),

            // ── Media grid ───────────────────────────────────────────
            if (mediaTweets.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Media',
                    style: GoogleFonts.mulish(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _kSecondary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tweet = mediaTweets[index];
                      return _MediaGridTile(
                        tweet: tweet,
                        isExpanded: _expandedTweetKey == tweet.key,
                        onTap: () => setState(() {
                          _expandedTweetKey =
                              _expandedTweetKey == tweet.key
                                  ? null
                                  : tweet.key;
                        }),
                      );
                    },
                    childCount: mediaTweets.length,
                  ),
                ),
              ),
              // Expanded tweet preview panel (below grid)
              if (_expandedTweetKey != null)
                SliverToBoxAdapter(
                  child: _buildExpandedPreview(
                    context,
                    allTweets.firstWhere(
                      (t) => t.key == _expandedTweetKey,
                      orElse: () => allTweets.first,
                    ),
                  ),
                ),
            ],

            // ── All bookmarked tweets list ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'All Bookmarks',
                  style: GoogleFonts.mulish(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _kSecondary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tweet = filtered[index];
                    final isExpanded = _expandedTweetKey == tweet.key;
                    return Column(
                      children: [
                        _BookmarkListTile(
                          tweet: tweet,
                          isExpanded: isExpanded,
                          onTap: () => setState(() {
                            _expandedTweetKey =
                                isExpanded ? null : tweet.key;
                          }),
                        ),
                        if (isExpanded)
                          TweetPreviewPanel(tweet: tweet),
                      ],
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildExpandedPreview(BuildContext context, FeedModel tweet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TweetPreviewPanel(tweet: tweet),
    );
  }
}

// ---------------------------------------------------------------------------
// _TagFilterRow – horizontal chip row derived from tweet tags
// ---------------------------------------------------------------------------

class _TagFilterRow extends StatelessWidget {
  const _TagFilterRow({
    Key? key,
    required this.tags,
    required this.activeTag,
    required this.onTagChanged,
  }) : super(key: key);

  final List<String> tags;
  final String? activeTag;
  final ValueChanged<String?> onTagChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" chip
            FilterChip(
              label: Text(
                'All',
                style: GoogleFonts.mulish(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: activeTag == null ? Colors.white : _kSecondary,
                ),
              ),
              selected: activeTag == null,
              onSelected: (_) => onTagChanged(null),
              selectedColor: _kPrimary,
              backgroundColor: _kBackground,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: activeTag == null ? _kPrimary : _kExtraLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kRadius),
              ),
            ),
            const SizedBox(width: 8),
            // Tag chips
            ...tags.map((tag) {
              final isActive = activeTag == tag;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    '#$tag',
                    style: GoogleFonts.mulish(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isActive ? Colors.white : _kSecondary,
                    ),
                  ),
                  selected: isActive,
                  onSelected: (_) => onTagChanged(isActive ? null : tag),
                  selectedColor: _kPrimary,
                  backgroundColor: _kBackground,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isActive ? _kPrimary : _kExtraLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadius),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MediaGridTile – single tile in the media GridView
// ---------------------------------------------------------------------------

class _MediaGridTile extends StatelessWidget {
  const _MediaGridTile({
    Key? key,
    required this.tweet,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);

  final FeedModel tweet;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(
            color: isExpanded ? _kPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              CachedNetworkImage(
                imageUrl: tweet.imagePath!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: _kExtraLight),
                errorWidget: (_, __, ___) => Container(
                  color: _kExtraLight,
                  child: const Icon(Icons.broken_image_outlined,
                      color: _kLightGrey),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // Expand indicator
              if (isExpanded)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _kPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.expand_less,
                        color: Colors.white, size: 14),
                  ),
                ),
              // Author handle at bottom
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  '@${tweet.user?.userName ?? ''}',
                  style: GoogleFonts.mulish(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BookmarkListTile – single row in the bookmarks list
// ---------------------------------------------------------------------------

class _BookmarkListTile extends StatelessWidget {
  const _BookmarkListTile({
    Key? key,
    required this.tweet,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);

  final FeedModel tweet;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(
          color: isExpanded ? _kPrimary : _kExtraLight,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircularImage(path: tweet.user?.profilePic, height: 40),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tweet.user?.displayName ?? '',
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _kSecondary,
                      ),
                    ),
                    if (tweet.description != null &&
                        tweet.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          tweet.description!,
                          style: GoogleFonts.mulish(
                            fontSize: 13,
                            color: _kSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Tags
                    if (tweet.tags != null && tweet.tags!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: tweet.tags!
                              .take(3)
                              .map((t) => Text(
                                    '#$t',
                                    style: GoogleFonts.mulish(
                                      fontSize: 12,
                                      color: _kPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              // Thumbnail (if image)
              if (tweet.imagePath != null && tweet.imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: tweet.imagePath!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              // Expand chevron
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _kLightGrey,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TweetPreviewPanel – inline expanded tweet card
// ---------------------------------------------------------------------------

class TweetPreviewPanel extends StatelessWidget {
  const TweetPreviewPanel({Key? key, required this.tweet}) : super(key: key);

  final FeedModel tweet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircularImage(path: tweet.user?.profilePic, height: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tweet.user?.displayName ?? '',
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _kSecondary,
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
                ),
                // Open full tweet button
                IconButton(
                  icon: const Icon(Icons.open_in_new,
                      color: _kPrimary, size: 18),
                  onPressed: () {
                    final feedState =
                        Provider.of<FeedState>(context, listen: false);
                    feedState.getPostDetailFromDatabase(null, model: tweet);
                    Navigator.push(
                        context, FeedPostDetail.getRoute(tweet.key!));
                  },
                ),
              ],
            ),
          ),
          // Tweet text
          if (tweet.description != null && tweet.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                tweet.description!,
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  color: _kSecondary,
                  height: 1.5,
                ),
              ),
            ),
          // Tweet image
          if (tweet.imagePath != null && tweet.imagePath!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kRadius),
                child: CachedNetworkImage(
                  imageUrl: tweet.imagePath!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.favorite_outline,
                  count: tweet.likeCount ?? 0,
                  color: const Color(0xFFE0245E),
                ),
                const SizedBox(width: 16),
                _StatChip(
                  icon: Icons.repeat,
                  count: tweet.retweetCount ?? 0,
                  color: const Color(0xFF17BF63),
                ),
                const SizedBox(width: 16),
                _StatChip(
                  icon: Icons.chat_bubble_outline,
                  count: tweet.commentCount ?? 0,
                  color: _kPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
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
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BookmarkReelWidget – kept for backward compatibility (ProfilePage etc.)
// ---------------------------------------------------------------------------

class BookmarkReelWidget extends StatelessWidget {
  const BookmarkReelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkState>(
      builder: (context, state, _) {
        if (state.isbusy) {
          return const SizedBox(
            height: 3,
            child: LinearProgressIndicator(color: _kPrimary),
          );
        }

        final list = state.tweetList;
        if (list == null || list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: EmptyList(
              'No Bookmarks yet',
              subTitle: 'Tap the bookmark icon on any tweet to save it here.',
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Saved Tweets',
                style: GoogleFonts.mulish(
                  color: _kSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                itemBuilder: (context, index) =>
                    _BookmarkMiniCard(model: list[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookmarkMiniCard extends StatelessWidget {
  const _BookmarkMiniCard({Key? key, required this.model}) : super(key: key);
  final FeedModel model;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final feedState = Provider.of<FeedState>(context, listen: false);
        feedState.getPostDetailFromDatabase(null, model: model);
        Navigator.push(context, FeedPostDetail.getRoute(model.key!));
      },
      child: Container(
        width: 140,
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: _kSecondary,
          borderRadius: BorderRadius.circular(_kRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kRadius),
          child: Stack(
            children: [
              if (model.imagePath != null && model.imagePath!.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: model.imagePath!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _kSecondary.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@${model.user?.userName ?? ''}',
                      style: GoogleFonts.mulish(
                        color: _kPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.description ?? '',
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bookmark,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    return const BookmarkReelWidget();
  }
}
