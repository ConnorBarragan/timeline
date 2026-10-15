import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/customLoader.dart';
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
// FeedPage – ListView of tweet cards
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

  void _openCompose() {
    Navigator.pushNamed(context, '/ComposeTweetPage/tweet');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Feed',
          style: GoogleFonts.mulish(
            color: _kSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: _kSecondary),
            tooltip: 'Search',
            onPressed: () => Navigator.pushNamed(context, '/SearchPage'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        backgroundColor: _kPrimary,
        tooltip: 'Compose Tweet',
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: _TweetListBody(
        refreshIndicatorKey: widget.refreshIndicatorKey,
      ),
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
            backgroundColor: _kBackground,
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
          color: _kPrimary,
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
// _TweetCard – Material Card with avatar, name, handle, body, optional image
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
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(_kRadius),
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
                            color: _kSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '@$userName',
                          style: GoogleFonts.mulish(
                            color: _kLightGrey,
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
                        color: _kLightGrey,
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
                    color: _kSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],

              // ── Tweet image (Image.network when tweetImage is present) ─
              if (hasImage) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(_kRadius),
                  child: Image.network(
                    model.imagePath!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 180,
                        color: _kExtraLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: _kPrimary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // ── Stats row ──────────────────────────────────────────────
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.chat_bubble_outline,
                    count: model.commentCount ?? 0,
                  ),
                  const SizedBox(width: 20),
                  _StatChip(
                    icon: Icons.repeat,
                    count: model.retweetCount ?? 0,
                    color: const Color(0xFF17BF63),
                  ),
                  const SizedBox(width: 20),
                  _StatChip(
                    icon: Icons.favorite_border,
                    count: model.likeCount ?? 0,
                    color: const Color(0xFFE0245E),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatChip – small icon + count label
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  const _StatChip({
    Key? key,
    required this.icon,
    required this.count,
    this.color,
  }) : super(key: key);

  final IconData icon;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _kLightGrey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.mulish(
            color: c,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
