// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/notificationModel.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/state/notificationState.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'analyticsTheme.dart';

// ---------------------------------------------------------------------------
// TweetAnalyticsPage
//
// Displays:
//   • Engagement Over Time – custom line/area chart (no external chart lib)
//   • Top Posts Table      – DataTable of top-5 tweets by interaction count
//   • Total Interactions   – stat card derived from notification list
// ---------------------------------------------------------------------------

class TweetAnalyticsPage extends StatelessWidget {
  const TweetAnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAnalyticsBackground,
      body: SafeArea(
        child: Consumer2<FeedState, NotificationState>(
          builder: (context, feedState, notifState, _) {
            final tweets = feedState.feedList ?? [];
            final notifications = notifState.notificationList ?? [];
            return _TweetAnalyticsBody(
              tweets: tweets,
              notifications: notifications,
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

class _TweetAnalyticsBody extends StatelessWidget {
  const _TweetAnalyticsBody({
    Key? key,
    required this.tweets,
    required this.notifications,
  }) : super(key: key);

  final List<FeedModel> tweets;
  final List<NotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────────
          Text(
            'Tweet Analytics',
            style: GoogleFonts.mulish(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kAnalyticsOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Engagement & reach overview',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kAnalyticsPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Total Interactions stat card ─────────────────────────────────
          _TotalInteractionsCard(notifications: notifications),
          const SizedBox(height: 16),

          // ── Engagement Over Time chart ───────────────────────────────────
          _EngagementChartCard(tweets: tweets),
          const SizedBox(height: 16),

          // ── Top Posts Table ──────────────────────────────────────────────
          _TopPostsCard(tweets: tweets),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total Interactions stat card
// ---------------------------------------------------------------------------

class _TotalInteractionsCard extends StatelessWidget {
  const _TotalInteractionsCard({
    Key? key,
    required this.notifications,
  }) : super(key: key);

  final List<NotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    final total = notifications.length;
    final formatted = _formatCount(total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Interactions',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kAnalyticsPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatted,
            style: GoogleFonts.mulish(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: kAnalyticsAccent,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'across all notifications',
            style: GoogleFonts.mulish(
              fontSize: 11,
              color: kAnalyticsPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ---------------------------------------------------------------------------
// Engagement Over Time chart card
// ---------------------------------------------------------------------------

class _EngagementChartCard extends StatelessWidget {
  const _EngagementChartCard({Key? key, required this.tweets})
      : super(key: key);

  final List<FeedModel> tweets;

  /// Bucket tweets by day and sum interactions (likes + retweets + comments).
  List<_ChartPoint> _buildPoints() {
    if (tweets.isEmpty) return _demoPoints();

    final Map<String, int> buckets = {};
    for (final t in tweets) {
      try {
        final dt = DateTime.parse(t.createdAt);
        final key = DateFormat('MM/dd').format(dt);
        final interactions =
            (t.likeCount ?? 0) + (t.retweetCount ?? 0) + (t.commentCount ?? 0);
        buckets[key] = (buckets[key] ?? 0) + interactions;
      } catch (_) {}
    }

    if (buckets.isEmpty) return _demoPoints();

    final sorted = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Keep last 7 buckets for readability.
    final slice = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    return slice
        .map((e) => _ChartPoint(label: e.key, value: e.value.toDouble()))
        .toList();
  }

  List<_ChartPoint> _demoPoints() {
    return [
      _ChartPoint(label: 'Mon', value: 12),
      _ChartPoint(label: 'Tue', value: 28),
      _ChartPoint(label: 'Wed', value: 18),
      _ChartPoint(label: 'Thu', value: 35),
      _ChartPoint(label: 'Fri', value: 22),
      _ChartPoint(label: 'Sat', value: 40),
      _ChartPoint(label: 'Sun', value: 30),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();

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
                'Engagement Over Time',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: kAnalyticsOnSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kAnalyticsBorder,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'interactions',
                  style: GoogleFonts.mulish(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kAnalyticsAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 160,
            child: _LineAreaChart(points: points),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom line/area chart painter
// ---------------------------------------------------------------------------

class _ChartPoint {
  const _ChartPoint({required this.label, required this.value});
  final String label;
  final double value;
}

class _LineAreaChart extends StatelessWidget {
  const _LineAreaChart({Key? key, required this.points}) : super(key: key);

  final List<_ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: GoogleFonts.mulish(color: kAnalyticsPrimary),
        ),
      );
    }
    return CustomPaint(
      painter: _LineAreaPainter(points: points),
      child: const SizedBox.expand(),
    );
  }
}

class _LineAreaPainter extends CustomPainter {
  _LineAreaPainter({required this.points});

  final List<_ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double leftPad = 32;
    const double bottomPad = 24;
    const double topPad = 8;
    final double chartW = size.width - leftPad;
    final double chartH = size.height - bottomPad - topPad;

    final maxVal = points.map((p) => p.value).reduce(math.max);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    // Compute pixel positions.
    final List<Offset> pts = [];
    for (int i = 0; i < points.length; i++) {
      final x = leftPad + (i / (points.length - 1)) * chartW;
      final y = topPad + chartH - (points[i].value / safeMax) * chartH;
      pts.add(Offset(x, y));
    }

    // ── Filled area ──────────────────────────────────────────────────────
    final areaPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      areaPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    areaPath
      ..lineTo(pts.last.dx, topPad + chartH)
      ..lineTo(pts.first.dx, topPad + chartH)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF5C518).withOpacity(0.35),
          const Color(0xFFF5C518).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH));
    canvas.drawPath(areaPath, areaPaint);

    // ── Line ─────────────────────────────────────────────────────────────
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    final linePaint = Paint()
      ..color = const Color(0xFFF5C518)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // ── Dots ─────────────────────────────────────────────────────────────
    final dotPaint = Paint()..color = const Color(0xFFF5C518);
    final dotBg = Paint()..color = const Color(0xFF2C2C2C);
    for (final pt in pts) {
      canvas.drawCircle(pt, 5, dotBg);
      canvas.drawCircle(pt, 3.5, dotPaint);
    }

    // ── X-axis labels ─────────────────────────────────────────────────────
    final labelStyle = GoogleFonts.mulish(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF6B6B6B),
    );
    for (int i = 0; i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: points[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pts[i].dx - tp.width / 2, topPad + chartH + 6),
      );
    }

    // ── Y-axis grid lines ─────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 3; i++) {
      final y = topPad + chartH - (i / 3) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);

      // Y label
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
  }

  @override
  bool shouldRepaint(_LineAreaPainter old) => old.points != points;
}

// ---------------------------------------------------------------------------
// Top Posts DataTable card
// ---------------------------------------------------------------------------

class _TopPostsCard extends StatelessWidget {
  const _TopPostsCard({Key? key, required this.tweets}) : super(key: key);

  final List<FeedModel> tweets;

  List<FeedModel> _topFive() {
    final sorted = List<FeedModel>.from(tweets)
      ..sort((a, b) {
        final ia =
            (a.likeCount ?? 0) + (a.retweetCount ?? 0) + (a.commentCount ?? 0);
        final ib =
            (b.likeCount ?? 0) + (b.retweetCount ?? 0) + (b.commentCount ?? 0);
        return ib.compareTo(ia);
      });
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final top = _topFive();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Posts',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: kAnalyticsOnSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No tweets yet',
                  style: GoogleFonts.mulish(color: kAnalyticsPrimary),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 64,
                columnSpacing: 16,
                headingTextStyle: GoogleFonts.mulish(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: kAnalyticsPrimary,
                  letterSpacing: 0.5,
                ),
                dataTextStyle: GoogleFonts.mulish(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kAnalyticsOnSurface,
                ),
                decoration: const BoxDecoration(),
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('TWEET')),
                  DataColumn(label: Text('LIKES'), numeric: true),
                  DataColumn(label: Text('RT'), numeric: true),
                  DataColumn(label: Text('CMT'), numeric: true),
                ],
                rows: top.map((t) {
                  final snippet = (t.description ?? '(no text)')
                      .replaceAll('\n', ' ');
                  final display = snippet.length > 40
                      ? '${snippet.substring(0, 40)}…'
                      : snippet;
                  return DataRow(cells: [
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          display,
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            color: kAnalyticsOnSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(
                      '${t.likeCount ?? 0}',
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        color: kAnalyticsAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    )),
                    DataCell(Text('${t.retweetCount ?? 0}')),
                    DataCell(Text('${t.commentCount ?? 0}')),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
