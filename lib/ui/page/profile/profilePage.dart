import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/state/profile_state.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/profile/EditProfilePage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/follow/followerListPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/follow/followingListPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/customLoader.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/emptyList.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Design tokens (shared with other redesigned tabs)
// ---------------------------------------------------------------------------
const Color _kPrimary = Color(0xFF1DA1F2);
const Color _kSecondary = Color(0xFF14171A);
const Color _kLightGrey = Color(0xFFAAB8C2);
const Color _kExtraLight = Color(0xFFE1E8ED);
const Color _kBackground = Color(0xFFF5F8FA);
const double _kRadius = 12.0;

// ---------------------------------------------------------------------------
// ProfilePage
// ---------------------------------------------------------------------------

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, required this.profileId}) : super(key: key);

  final String profileId;

  static MaterialPageRoute getRoute({required String profileId}) {
    return MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ProfileState(profileId),
        child: ProfilePage(profileId: profileId),
      ),
    );
  }

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.mulish(
            color: _kSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _kSecondary),
      ),
      body: _ProfileBody(profileId: widget.profileId),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProfileBody – CustomScrollView with a SliverList
// ---------------------------------------------------------------------------

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({Key? key, required this.profileId}) : super(key: key);

  final String profileId;

  @override
  Widget build(BuildContext context) {
    final profileState = Provider.of<ProfileState>(context);
    final feedState = Provider.of<FeedState>(context);

    if (profileState.isbusy) {
      return CustomScreenLoader(
        height: double.infinity,
        width: double.infinity,
        backgroundColor: _kBackground,
      );
    }

    final user = profileState.profileUserModel;
    final isMyProfile = profileState.isMyProfile;

    // Filter tweets belonging to this user (top-level, non-retweet)
    final allTweets = feedState.feedList;
    final userTweets = allTweets
            ?.where((t) =>
                t.userId == user.userId &&
                t.parentkey == null &&
                t.childRetwetkey == null)
            .toList() ??
        [];

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async {
        feedState.getDataFromDatabase();
      },
      child: CustomScrollView(
        slivers: [
          // ── Profile header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(
              user: user,
              isMyProfile: isMyProfile,
              profileState: profileState,
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Divider(height: 1, color: _kExtraLight),
          ),

          // ── Section label ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Tweets',
                style: GoogleFonts.mulish(
                  color: _kSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // ── Tweet list ──────────────────────────────────────────────────
          userTweets.isEmpty
              ? const SliverFillRemaining(
                  child: EmptyList(
                    'No Tweets yet',
                    subTitle: 'Tweets posted by this user will appear here.',
                  ),
                )
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _TweetCard(model: userTweets[index]),
                      childCount: userTweets.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProfileHeader – cover photo, avatar, name, handle, bio, stats, action btn
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    Key? key,
    required this.user,
    required this.isMyProfile,
    required this.profileState,
  }) : super(key: key);

  final UserModel user;
  final bool isMyProfile;
  final ProfileState profileState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover photo + avatar overlay ───────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner image
            Container(
              height: 140,
              width: double.infinity,
              color: _kPrimary.withOpacity(0.15),
              child: user.bannerImage != null && user.bannerImage!.isNotEmpty
                  ? Image.network(
                      user.bannerImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _kPrimary.withOpacity(0.6),
                            _kPrimary.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
            ),

            // Circular avatar overlapping the banner
            Positioned(
              bottom: -40,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: CircularImage(
                  path: user.profilePic ?? Constants.dummyProfilePic,
                  height: 80,
                ),
              ),
            ),

            // Edit / Follow button
            Positioned(
              bottom: -36,
              right: 16,
              child: isMyProfile
                  ? const _EditButton()
                  : _FollowButton(profileState: profileState),
            ),
          ],
        ),

        // Space for the overlapping avatar
        const SizedBox(height: 48),

        // ── Display name + handle ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? '',
                style: GoogleFonts.mulish(
                  color: _kSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.userName ?? '',
                style: GoogleFonts.mulish(
                  color: _kLightGrey,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // ── Bio ────────────────────────────────────────────────────────
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              user.bio!,
              style: GoogleFonts.mulish(
                color: _kSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],

        // ── Location ──────────────────────────────────────────────────
        if (user.location != null && user.location!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: _kLightGrey),
                const SizedBox(width: 4),
                Text(
                  user.location!,
                  style: GoogleFonts.mulish(
                    color: _kLightGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Joined date ────────────────────────────────────────────────
        if (user.createdAt != null && user.createdAt!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: _kLightGrey),
                const SizedBox(width: 4),
                Text(
                  Utility.getJoiningDate(user.createdAt),
                  style: GoogleFonts.mulish(
                    color: _kLightGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Stats row: Followers / Following ──────────────────────────
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatButton(
                count: user.getFollower,
                label: 'Followers',
                onTap: () {
                  if (user.followersList != null) {
                    Navigator.push(
                      context,
                      FollowerListPage.getRoute(
                        profile: user,
                        userList: user.followersList!,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 24),
              _StatButton(
                count: user.getFollowing,
                label: 'Following',
                onTap: () {
                  if (user.followingList != null) {
                    Navigator.push(
                      context,
                      FollowingListPage.getRoute(
                        profile: user,
                        userList: user.followingList!,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _StatButton – tappable Followers / Following count
// ---------------------------------------------------------------------------

class _StatButton extends StatelessWidget {
  const _StatButton({
    Key? key,
    required this.count,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  final String count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: GoogleFonts.mulish(
              color: _kSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.mulish(
              color: _kLightGrey,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EditButton – navigates to EditProfilePage
// ---------------------------------------------------------------------------

class _EditButton extends StatelessWidget {
  const _EditButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Navigator.push(context, EditProfilePage.getRoute()),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      child: Text(
        'Edit Profile',
        style: GoogleFonts.mulish(
          color: _kPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FollowButton – follow / unfollow another user
// ---------------------------------------------------------------------------

class _FollowButton extends StatelessWidget {
  const _FollowButton({Key? key, required this.profileState}) : super(key: key);

  final ProfileState profileState;

  @override
  Widget build(BuildContext context) {
    // Guard: logged-in user model is late and may not be initialised yet
    UserModel? loggedInUser;
    try {
      loggedInUser = profileState.userModel;
    } catch (_) {
      // Not yet loaded – treat as not following
    }

    final isFollowing = loggedInUser != null &&
        (profileState.profileUserModel.followersList
                ?.contains(loggedInUser.userId) ??
            false);

    return ElevatedButton(
      onPressed: () => profileState.followUser(removeFollower: isFollowing),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.white : _kPrimary,
        foregroundColor: isFollowing ? _kPrimary : Colors.white,
        side: isFollowing ? const BorderSide(color: _kPrimary) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: GoogleFonts.mulish(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TweetCard – matches the Feed tab card style exactly
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
