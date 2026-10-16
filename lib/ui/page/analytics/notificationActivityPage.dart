// ignore_for_file: avoid_print

import 'dart:math' as math;
import 'dart:ui' as ui;

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
// NotificationActivityPage
//
// Displays:
//   • Notification Types Bar Chart – grouped bars for Like / Retweet / Follow
//   • Recent Notification Feed     – last 20 notifications (icon + time + actor)
//   • Most Engaged Tweet stat card – tweet with highest like + retweet count
// ---------------------------------------------------------------------------

class NotificationActivityPage extends StatelessWidget {
  const NotificationActivityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAnalyticsBackground,
      body: SafeArea(
        child: Consumer2<FeedState, NotificationState>(
          builder: (context, feedState, notifState, _) {
            final tweets = feedState.feedList ?? [];
            final notifications = notifState.notificationList ?? [];
            return _NotificationActivityBody(
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

class _NotificationActivityBody extends StatelessWidget {
  const _NotificationActivityBody({
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
            'Notification Activity',
            style: GoogleFonts.mulish(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kAnalyticsOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Likes, retweets & follows at a glance',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kAnalyticsPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Most Engaged Tweet stat card ─────────────────────────────────
          _MostEngagedTweetCard(tweets: tweets),
          const SizedBox(height: 16),

          // ── Notification Types Bar Chart ─────────────────────────────────
          _NotificationBarChartCard(notifications: notifications),
          const SizedBox(height: 16),

          // ── Recent Notification Feed ─────────────────────────────────────
          _RecentNotificationFeedCard(notifications: notifications),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Most Engaged Tweet stat card
// ---------------------------------------------------------------------------

class _MostEngagedTweetCard extends StatelessWidget {
  const _MostEngagedTweetCard({Key? key, required this.tweets})
      : super(key: key);

  final List<FeedModel> tweets;

  FeedModel? _mostEngaged() {
    if (tweets.isEmpty) return null;
    return tweets.reduce((a, b) {
      final ia = (a.likeCount ?? 0) + (a.retweetCount ?? 0);
      final ib = (b.likeCount ?? 0) + (b.retweetCount ?? 0);
      return ia >= ib ? a : b;
    });
  }

  @override
  Widget build(BuildContext context) {
    final best = _mostEngaged();
    final snippet = best?.description?.replaceAll('\n', ' ') ?? '—';
    final display =
        snippet.length > 80 ? '${snippet.substring(0, 80)}…' : snippet;
    final engagements =
        best == null ? 0 : (best.likeCount ?? 0) + (best.retweetCount ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Engaged Tweet',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kAnalyticsPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCount(engagements),
            style: GoogleFonts.mulish(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: kAnalyticsAccent,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            display,
            style: GoogleFonts.mulish(
              fontSize: 13,
              color: kAnalyticsOnSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (best != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _StatPill(
                  icon: Icons.favorite,
                  value: best.likeCount ?? 0,
                  label: 'likes',
                ),
                const SizedBox(width: 10),
                _StatPill(
                  icon: Icons.repeat,
                  value: best.retweetCount ?? 0,
                  label: 'retweets',
                ),
              ],
            ),
          ],
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

class _StatPill extends StatelessWidget {
  const _StatPill({
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
        Icon(icon, size: 13, color: kAnalyticsAccent),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: GoogleFonts.mulish(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kAnalyticsPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Types Bar Chart card
// ---------------------------------------------------------------------------

class _NotificationBarChartCard extends StatelessWidget {
  const _NotificationBarChartCard({Key? key, required this.notifications})
      : super(key: key);

  final List<NotificationModel> notifications;

  /// Count notifications by type bucket.
  _BarCounts _buildCounts() {
    int likes = 0, retweets = 0, follows = 0, other = 0;
    for (final n in notifications) {
      final t = (n.type ?? '').toLowerCase();
      if (t == 'like') {
        likes++;
      } else if (t == 'retweet') {
        retweets++;
      } else if (t == 'follow') {
        follows++;
      } else {
        other++;
      }
    }
    // If no real data, show demo values so the chart is always visible.
    if (likes == 0 && retweets == 0 && follows == 0 && other == 0) {
      return _BarCounts(likes: 14, retweets: 8, follows: 5, other: 3);
    }
    return _BarCounts(
        likes: likes, retweets: retweets, follows: follows, other: other);
  }

  @override
  Widget build(BuildContext context) {
    final counts = _buildCounts();

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
                'Notification Types',
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
                  color: kAnalyticsAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${notifications.length} total',
                  style: GoogleFonts.mulish(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: kAnalyticsAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar chart
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _BarChartPainter(counts: counts),
              size: Size.infinite,
            ),
          ),

          const SizedBox(height: 12),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LegendItem(color: kAnalyticsAccent, label: 'Likes'),
              _LegendItem(
                  color: kAnalyticsAccent.withOpacity(0.65),
                  label: 'Retweets'),
              _LegendItem(
                  color: kAnalyticsAccent.withOpacity(0.40),
                  label: 'Follows'),
              _LegendItem(
                  color: kAnalyticsPrimary.withOpacity(0.50), label: 'Other'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarCounts {
  const _BarCounts({
    required this.likes,
    required this.retweets,
    required this.follows,
    required this.other,
  });
  final int likes;
  final int retweets;
  final int follows;
  final int other;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({Key? key, required this.color, required this.label})
      : super(key: key);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kAnalyticsPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bar chart painter
// ---------------------------------------------------------------------------

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.counts});

  final _BarCounts counts;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 36;
    const double bottomPad = 28;
    const double topPad = 8;
    final double chartW = size.width - leftPad;
    final double chartH = size.height - bottomPad - topPad;

    final bars = [
      _Bar(label: 'Likes', value: counts.likes, color: kAnalyticsAccent),
      _Bar(
          label: 'Retweets',
          value: counts.retweets,
          color: kAnalyticsAccent.withOpacity(0.65)),
      _Bar(
          label: 'Follows',
          value: counts.follows,
          color: kAnalyticsAccent.withOpacity(0.40)),
      _Bar(
          label: 'Other',
          value: counts.other,
          color: kAnalyticsPrimary.withOpacity(0.50)),
    ];

    final maxVal =
        bars.map((b) => b.value).reduce(math.max).toDouble();
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    // ── Grid lines ──────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = kAnalyticsBorder
      ..strokeWidth = 0.8;

    final labelStyle = GoogleFonts.mulish(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: kAnalyticsPrimary,
    ).copyWith(fontSize: 9);

    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH - (i / 4) * chartH;
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width, y), gridPaint);

      final val = ((safeMax * i) / 4).round();
      final tp = TextPainter(
        text: TextSpan(
          text: val >= 1000
              ? '${(val / 1000).toStringAsFixed(0)}k'
              : '$val',
          style: labelStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // ── Bars ─────────────────────────────────────────────────────────────────
    final barCount = bars.length;
    final groupW = chartW / barCount;
    const barPadRatio = 0.25; // padding on each side of bar within group

    for (int i = 0; i < barCount; i++) {
      final bar = bars[i];
      final barW = groupW * (1 - barPadRatio * 2);
      final x = leftPad + i * groupW + groupW * barPadRatio;
      final barH = (bar.value / safeMax) * chartH;
      final y = topPad + chartH - barH;

      // Bar fill
      final barPaint = Paint()..color = bar.color;
      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barW, barH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rrect, barPaint);

      // X-axis label
      final tp = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: labelStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: groupW);
      tp.paint(
        canvas,
        Offset(
          x + barW / 2 - tp.width / 2,
          topPad + chartH + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.counts != counts;
}

class _Bar {
  const _Bar({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
}

// ---------------------------------------------------------------------------
// Recent Notification Feed card
// ---------------------------------------------------------------------------

class _RecentNotificationFeedCard extends StatelessWidget {
  const _RecentNotificationFeedCard({Key? key, required this.notifications})
      : super(key: key);

  final List<NotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    // Show last 20, most-recent first.
    final recent = notifications.length > 20
        ? notifications.sublist(notifications.length - 20).reversed.toList()
        : List<NotificationModel>.from(notifications.reversed);

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
                'Recent Notifications',
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
                  color: kAnalyticsAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'last 20',
                  style: GoogleFonts.mulish(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: kAnalyticsAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No notifications yet',
                  style: GoogleFonts.mulish(color: kAnalyticsPrimary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const Divider(
                color: kAnalyticsBorder,
                height: 1,
                thickness: 0.5,
              ),
              itemBuilder: (context, index) {
                final n = recent[index];
                return _NotificationRow(notification: n);
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single notification row
// ---------------------------------------------------------------------------

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({Key? key, required this.notification})
      : super(key: key);

  final NotificationModel notification;

  IconData _iconForType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'like':
        return Icons.favorite;
      case 'retweet':
        return Icons.repeat;
      case 'follow':
        return Icons.person_add;
      case 'reply':
        return Icons.reply;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'like':
        return kAnalyticsAccent;
      case 'retweet':
        return kAnalyticsAccent.withOpacity(0.75);
      case 'follow':
        return kAnalyticsAccent.withOpacity(0.55);
      default:
        return kAnalyticsPrimary;
    }
  }

  String _actorName(NotificationModel n) {
    try {
      final user = n.user;
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      }
      if (user.userName != null && user.userName!.isNotEmpty) {
        return '@${user.userName!}';
      }
    } catch (_) {}
    return 'Someone';
  }

  String _formattedTime(NotificationModel n) {
    try {
      final ts = n.timeStamp;
      if (ts == null) return '';
      final now = DateTime.now();
      final diff = now.difference(ts);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d').format(ts);
    } catch (_) {
      return '';
    }
  }

  String _typeLabel(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'like':
        return 'liked your tweet';
      case 'retweet':
        return 'retweeted your tweet';
      case 'follow':
        return 'followed you';
      case 'reply':
        return 'replied to your tweet';
      case 'mention':
        return 'mentioned you';
      default:
        return 'sent a notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _colorForType(notification.type);
    final actor = _actorName(notification);
    final time = _formattedTime(notification);
    final label = _typeLabel(notification.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconForType(notification.type),
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),

          // Actor + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: actor,
                        style: GoogleFonts.mulish(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kAnalyticsOnSurface,
                        ),
                      ),
                      TextSpan(
                        text: ' $label',
                        style: GoogleFonts.mulish(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kAnalyticsPrimary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Timestamp
          if (time.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              time,
              style: GoogleFonts.mulish(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kAnalyticsPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
