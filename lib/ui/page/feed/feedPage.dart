import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/page/bookmark/bookmarkPage.dart';
import 'package:flutter_twitter_clone/ui/page/feed/composeTweet/composeTweet.dart';
import 'package:flutter_twitter_clone/ui/page/feed/composeTweet/state/composeTweetState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/notification/notificationPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/customLoader.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/emptyList.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Twitter-blue primary and near-black card surface
const Color _kPrimary = Color(0xFF1DA1F2);
const Color _kCardSurface = Color(0xFF14171A);
const Color _kLightGrey = Color(0xFFAAB8C2);

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

class _FeedPageState extends State<FeedPage> {
  // 0=Home, 1=Explore, 2=Compose(FAB), 3=Notifications, 4=Profile
  int _dockIndex = 0;

  void _openCompose(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<ComposeTweetState>(
        create: (_) => ComposeTweetState(),
        child: const ComposeTweetBottomSheet(),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationBottomSheet(),
    );
  }

  void _onDockTap(BuildContext context, int index) {
    if (index == 2) {
      _openCompose(context);
      return;
    }
    if (index == 3) {
      _openNotifications(context);
      return;
    }
    if (index == 4) {
      final authState = Provider.of<AuthState>(context, listen: false);
      if (authState.userModel?.userId != null) {
        Navigator.push(
          context,
          ProfilePage.getRoute(profileId: authState.userModel!.userId!),
        );
      }
      return;
    }
    if (index == 1) {
      Navigator.pushNamed(context, '/SearchPage');
      return;
    }
    setState(() => _dockIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCardSurface,
      body: SafeArea(
        child: _CardStackBody(
          refreshIndicatorKey: widget.refreshIndicatorKey,
          scaffoldKey: widget.scaffoldKey,
        ),
      ),
      bottomNavigationBar: _BottomDock(
        currentIndex: _dockIndex,
        onTap: (i) => _onDockTap(context, i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card-stack body
// ---------------------------------------------------------------------------

class _CardStackBody extends StatelessWidget {
  const _CardStackBody({
    Key? key,
    this.refreshIndicatorKey,
    required this.scaffoldKey,
  }) : super(key: key);

  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;
  final GlobalKey<ScaffoldState> scaffoldKey;

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
            backgroundColor: _kCardSurface,
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
            return Future.value(true);
          },
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: list!.length,
            itemBuilder: (context, index) => _TweetCard(
              model: list[index],
              scaffoldKey: scaffoldKey,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Full-viewport tweet card
// ---------------------------------------------------------------------------

class _TweetCard extends StatelessWidget {
  const _TweetCard({
    Key? key,
    required this.model,
    required this.scaffoldKey,
  }) : super(key: key);

  final FeedModel model;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        final feedState = Provider.of<FeedState>(context, listen: false);
        feedState.getPostDetailFromDatabase(null, model: model);
        Navigator.push(context, FeedPostDetail.getRoute(model.key!));
      },
      child: Container(
        width: size.width,
        height: size.height,
        color: _kCardSurface,
        child: Stack(
          children: [
            // Background media image (if any)
            if (model.imagePath != null && model.imagePath!.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: model.imagePath!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // Dark gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _kCardSurface.withOpacity(0.55),
                      _kCardSurface.withOpacity(0.92),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Right-rail action column
            Positioned(
              right: 12,
              bottom: 120,
              child: _RightRail(model: model),
            ),

            // Author + tweet text at bottom
            Positioned(
              left: 16,
              right: 72,
              bottom: 24,
              child: _CardContent(model: model),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right-rail: like, retweet, bookmark
// ---------------------------------------------------------------------------

class _RightRail extends StatelessWidget {
  const _RightRail({Key? key, required this.model}) : super(key: key);
  final FeedModel model;

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: false);
    final feedState = Provider.of<FeedState>(context, listen: false);
    final userId = authState.userId;
    final isLiked =
        model.likeList != null && model.likeList!.contains(userId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _RailButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.pinkAccent : Colors.white,
          count: model.likeCount ?? 0,
          onTap: () => feedState.addLikeToTweet(model, userId),
        ),
        const SizedBox(height: 20),
        // Retweet
        _RailButton(
          icon: Icons.repeat,
          color: Colors.white,
          count: model.retweetCount ?? 0,
          onTap: () {
            feedState.setTweetToReply = model;
            Navigator.of(context).pushNamed('/ComposeTweetPage/retweet');
          },
        ),
        const SizedBox(height: 20),
        // Bookmark
        _RailButton(
          icon: Icons.bookmark_border,
          color: Colors.white,
          count: null,
          onTap: () {
            Navigator.push(context, BookmarkPage.getRoute());
          },
        ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          if (count != null && count! > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$count',
              style: GoogleFonts.mulish(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card content: avatar, name, handle, tweet text
// ---------------------------------------------------------------------------

class _CardContent extends StatelessWidget {
  const _CardContent({Key? key, required this.model}) : super(key: key);
  final FeedModel model;

  @override
  Widget build(BuildContext context) {
    final user = model.user;
    final displayName = user?.displayName ?? '';
    final userName = user?.userName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + name row
        Row(
          children: [
            CircularImage(
              path: user?.profilePic ?? Constants.dummyProfilePic,
              height: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.mulish(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@$userName',
                    style: GoogleFonts.mulish(
                      color: _kLightGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
          model.description ?? '',
          style: GoogleFonts.mulish(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom dock
// ---------------------------------------------------------------------------

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _DockItem(
            icon: currentIndex == 0 ? Icons.home : Icons.home_outlined,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _DockItem(
            icon: Icons.search,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          // Compose FAB in the centre
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          _DockItem(
            icon: currentIndex == 3
                ? Icons.notifications
                : Icons.notifications_outlined,
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _DockItem(
            icon: currentIndex == 4 ? Icons.person : Icons.person_outline,
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    Key? key,
    required this.icon,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Icon(
          icon,
          color: isActive ? _kPrimary : Colors.grey.shade600,
          size: 26,
        ),
      ),
    );
  }
}
