// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/bookmarkState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'analyticsTheme.dart';

// ---------------------------------------------------------------------------
// BookmarkInsightsPage
//
// Displays:
//   • Bookmarks Over Time  – cumulative line chart (CustomPainter)
//   • Most Bookmarked Posts – ListView with yellow badge
//   • Tweet Preview card   – expandable inline detail on tap
// ---------------------------------------------------------------------------

class BookmarkInsightsPage extends StatelessWidget {
  const BookmarkInsightsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAnalyticsBackground,
      body: SafeArea(
        child: Consumer2<BookmarkState, FeedState>(
          builder: (context, bookmarkState, feedState, _) {
            final bookmarkedTweets = bookmarkState.tweetList ?? [];
            final allTweets = feedState.feedList ?? [];
            return _BookmarkInsightsBody(
              bookmarkedTweets: bookmarkedTweets,
              allTweets: allTweets,
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _BookmarkInsightsBody extends StatelessWidget {
  const _BookmarkInsightsBody({
    Key? key,
    required this.bookmarkedTweets,
    required this.allTweets,
  }) : super(key: key);

  final List<FeedModel> bookmarkedTweets;
  final List<FeedModel> allTweets;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────────
          Text(
            'Bookmark Insights',
            style: GoogleFonts.mulish(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kAnalyticsOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved posts & growth over time',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kAnalyticsPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Bookmarks Over Time chart ────────────────────────────────────
          _BookmarksOverTimeCard(bookmarkedTweets: bookmarkedTweets),
          const SizedBox(height: 16),

          // ── Most Bookmarked Posts list ───────────────────────────────────
          _MostBookmarkedPostsCard(
            bookmarkedTweets: bookmarkedTweets,
            allTweets: allTweets,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bookmarks Over Time chart card
// ---------------------------------------------------------------------------

class _BookmarksOverTimeCard extends StatelessWidget {
  const _BookmarksOverTimeCard({Key? key, required this.bookmarkedTweets})
      : super(key: key);

  final List<FeedModel> bookmarkedTweets;

  /// Build cumulative bookmark points bucketed by day.
  List<_ChartPoint> _buildPoints() {
    if (bookmarkedTweets.isEmpty) return _demoPoints();

    final Map<String, int> dailyCounts = {};
    for (final tweet in bookmarkedTweets) {
      try {
        final dt = DateTime.parse(tweet.createdAt);
        final key = DateFormat('MM/dd').format(dt);
        dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
      } catch (_) {}
    }

    if (dailyCounts.isEmpty) return _demoPoints();

    final sorted = dailyCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Build cumulative counts.
    final points = <_ChartPoint>[];
    int cumulative = 0;
    for (final entry in sorted) {
      cumulative += entry.value;
      points.add(_ChartPoint(label: entry.key, value: cumulative.toDouble()));
    }

    // Keep last 7 for readability.
    return points.length > 7 ? points.sublist(points.length - 7) : points;
  }

  List<_ChartPoint> _demoPoints() {
    return [
      _ChartPoint(label: 'Mon', value: 2),
      _ChartPoint(label: 'Tue', value: 5),
      _ChartPoint(label: 'Wed', value: 7),
      _ChartPoint(label: 'Thu', value: 11),
      _ChartPoint(label: 'Fri', value: 14),
      _ChartPoint(label: 'Sat', value: 18),
      _ChartPoint(label: 'Sun', value: 23),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();
    final totalBookmarks = bookmarkedTweets.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bookmarks Over Time',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: kAnalyticsOnSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kAnalyticsAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalBookmarks saved',
                  style: GoogleFonts.mulish(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: kAnalyticsAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cumulative bookmarks',
            style: GoogleFonts.mulish(
              fontSize: 11,
              color: kAnalyticsPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _CumulativeLinePainter(points: points),
              size: const Size(double.infinity, 160),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cumulative line chart painter
// ---------------------------------------------------------------------------

class _ChartPoint {
  const _ChartPoint({required this.label, required this.value});
  final String label;
  final double value;
}

class _CumulativeLinePainter extends CustomPainter {
  const _CumulativeLinePainter({required this.points});

  final List<_ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double leftPad = 36;
    const double bottomPad = 28;
    const double topPad = 8;

    final double chartW = size.width - leftPad;
    final double chartH = size.height - bottomPad - topPad;

    final double maxVal =
        points.map((p) => p.value).reduce(math.max);
    final double safeMax = maxVal == 0 ? 1 : maxVal;

    // ── Grid lines ──────────────────────────────────────────────────────────
    final labelStyle = TextStyle(
      fontSize: 9,
      color: kAnalyticsPrimary,
      fontWeight: FontWeight.w600,
    );

    final gridPaint = Paint()
      ..color = kAnalyticsBorder
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 3; i++) {
      final y = topPad + chartH - (i / 3) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);

      final val = ((safeMax * i) / 3).round();
      final tp = TextPainter(
        text: TextSpan(
          text: val >= 1000 ? '${(val / 1000).toStringAsFixed(0)}k' : '$val',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // ── Compute point positions ──────────────────────────────────────────────
    final List<Offset> offsets = [];
    for (int i = 0; i < points.length; i++) {
      final x = leftPad + (i / (points.length - 1).clamp(1, 9999)) * chartW;
      final y = topPad + chartH - (points[i].value / safeMax) * chartH;
      offsets.add(Offset(x, y));
    }

    // ── Filled area ──────────────────────────────────────────────────────────
    final areaPath = Path();
    areaPath.moveTo(offsets.first.dx, topPad + chartH);
    for (final o in offsets) {
      areaPath.lineTo(o.dx, o.dy);
    }
    areaPath.lineTo(offsets.last.dx, topPad + chartH);
    areaPath.close();

    final areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        kAnalyticsAccent.withOpacity(0.30),
        kAnalyticsAccent.withOpacity(0.02),
      ],
    );
    final areaPaint = Paint()
      ..shader = areaGradient.createShader(
        Rect.fromLTWH(leftPad, topPad, chartW, chartH),
      );
    canvas.drawPath(areaPath, areaPaint);

    // ── Line ─────────────────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = kAnalyticsAccent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      linePath.lineTo(offsets[i].dx, offsets[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // ── Data points ──────────────────────────────────────────────────────────
    final dotPaint = Paint()..color = kAnalyticsAccent;
    final dotBorderPaint = Paint()
      ..color = kAnalyticsSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final o in offsets) {
      canvas.drawCircle(o, 4, dotPaint);
      canvas.drawCircle(o, 4, dotBorderPaint);
    }

    // ── X-axis labels ─────────────────────────────────────────────────────────
    for (int i = 0; i < points.length; i++) {
      final x = leftPad + (i / (points.length - 1).clamp(1, 9999)) * chartW;
      final tp = TextPainter(
        text: TextSpan(text: points[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, size.height - bottomPad + 6),
      );
    }
  }

  @override
  bool shouldRepaint(_CumulativeLinePainter old) => old.points != points;
}

// ---------------------------------------------------------------------------
// Most Bookmarked Posts card
// ---------------------------------------------------------------------------

class _MostBookmarkedPostsCard extends StatelessWidget {
  const _MostBookmarkedPostsCard({
    Key? key,
    required this.bookmarkedTweets,
    required this.allTweets,
  }) : super(key: key);

  final List<FeedModel> bookmarkedTweets;
  final List<FeedModel> allTweets;

  /// Merge bookmarked tweets with any extra data from allTweets.
  /// Returns up to 10 items sorted by like count descending.
  List<FeedModel> _sortedBookmarks() {
    if (bookmarkedTweets.isEmpty) return [];

    // Build a lookup map from allTweets for richer data.
    final Map<String, FeedModel> lookup = {
      for (final t in allTweets)
        if (t.key != null) t.key!: t,
    };

    final enriched = bookmarkedTweets.map((bm) {
      if (bm.key != null && lookup.containsKey(bm.key)) {
        return lookup[bm.key]!;
      }
      return bm;
    }).toList();

    enriched.sort((a, b) =>
        ((b.likeCount ?? 0) + (b.retweetCount ?? 0))
            .compareTo((a.likeCount ?? 0) + (a.retweetCount ?? 0)));

    return enriched.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedBookmarks();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Bookmarked Posts',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: kAnalyticsOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a post to preview details',
            style: GoogleFonts.mulish(
              fontSize: 11,
              color: kAnalyticsPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bookmark_outline,
                        size: 40, color: kAnalyticsPrimary),
                    const SizedBox(height: 8),
                    Text(
                      'No bookmarks yet',
                      style: GoogleFonts.mulish(
                        color: kAnalyticsPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                color: kAnalyticsBorder,
                height: 1,
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                return _BookmarkListItem(
                  tweet: items[index],
                  rank: index + 1,
                );
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bookmark list item with expandable Tweet Preview
// ---------------------------------------------------------------------------

class _BookmarkListItem extends StatefulWidget {
  const _BookmarkListItem({
    Key? key,
    required this.tweet,
    required this.rank,
  }) : super(key: key);

  final FeedModel tweet;
  final int rank;

  @override
  State<_BookmarkListItem> createState() => _BookmarkListItemState();
}

class _BookmarkListItemState extends State<_BookmarkListItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  String _snippet(String? text) {
    if (text == null || text.isEmpty) return '(no text)';
    final clean = text.replaceAll('\n', ' ');
    return clean.length > 60 ? '${clean.substring(0, 60)}…' : clean;
  }

  String _authorName(FeedModel tweet) {
    try {
      final user = tweet.user;
      if (user == null) return 'Unknown';
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      }
      if (user.userName != null && user.userName!.isNotEmpty) {
        return '@${user.userName!}';
      }
    } catch (_) {}
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final tweet = widget.tweet;
    final engagements = (tweet.likeCount ?? 0) + (tweet.retweetCount ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row ──────────────────────────────────────────────────────────────
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rank badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.rank == 1
                        ? kAnalyticsAccent
                        : kAnalyticsAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.rank}',
                      style: GoogleFonts.mulish(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: widget.rank == 1
                            ? kAnalyticsSurface
                            : kAnalyticsAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tweet snippet
                Expanded(
                  child: Text(
                    _snippet(tweet.description),
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kAnalyticsOnSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // Engagement badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kAnalyticsAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatCount(engagements),
                    style: GoogleFonts.mulish(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kAnalyticsAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Expand chevron
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: kAnalyticsPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Expandable Tweet Preview card ─────────────────────────────────────
        SizeTransition(
          sizeFactor: _expandAnim,
          axisAlignment: -1,
          child: _TweetPreviewCard(tweet: tweet, authorName: _authorName(tweet)),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ---------------------------------------------------------------------------
// Tweet Preview detail card (shown when a list item is expanded)
// ---------------------------------------------------------------------------

class _TweetPreviewCard extends StatelessWidget {
  const _TweetPreviewCard({
    Key? key,
    required this.tweet,
    required this.authorName,
  }) : super(key: key);

  final FeedModel tweet;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final description = tweet.description ?? '(no text)';
    final likeCount = tweet.likeCount ?? 0;
    final retweetCount = tweet.retweetCount ?? 0;
    final commentCount = tweet.commentCount ?? 0;

    String formattedDate = '';
    try {
      final dt = DateTime.parse(tweet.createdAt);
      formattedDate = DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kAnalyticsBackground,
        borderRadius: BorderRadius.circular(kAnalyticsRadius),
        border: Border.all(color: kAnalyticsAccent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kAnalyticsAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    authorName.isNotEmpty
                        ? authorName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: kAnalyticsAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kAnalyticsOnSurface,
                      ),
                    ),
                    if (formattedDate.isNotEmpty)
                      Text(
                        formattedDate,
                        style: GoogleFonts.mulish(
                          fontSize: 10,
                          color: kAnalyticsPrimary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tweet text
          Text(
            description,
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kAnalyticsOnSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _PreviewStat(
                icon: Icons.favorite,
                value: likeCount,
                label: 'Likes',
              ),
              const SizedBox(width: 16),
              _PreviewStat(
                icon: Icons.repeat,
                value: retweetCount,
                label: 'Retweets',
              ),
              const SizedBox(width: 16),
              _PreviewStat(
                icon: Icons.chat_bubble_outline,
                value: commentCount,
                label: 'Comments',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
  }) : super(key: key);

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kAnalyticsAccent),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: kAnalyticsAccent,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 11,
            color: kAnalyticsPrimary,
          ),
        ),
      ],
    );
  }
}
