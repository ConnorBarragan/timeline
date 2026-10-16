import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/customRoute.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/theme/theme.dart';
import 'package:flutter_twitter_clone/widgets/customWidgets.dart';
import 'package:flutter_twitter_clone/widgets/tweet/tweet.dart';
import 'package:flutter_twitter_clone/widgets/tweet/widgets/tweetBottomSheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FeedPostDetail extends StatefulWidget {
  const FeedPostDetail({Key? key, required this.postId}) : super(key: key);
  final String postId;

  static Route<void> getRoute(String postId) {
    return SlideLeftRoute<void>(
      builder: (BuildContext context) => FeedPostDetail(
        postId: postId,
      ),
    );
  }

  @override
  _FeedPostDetailState createState() => _FeedPostDetailState();
}

class _FeedPostDetailState extends State<FeedPostDetail> {
  late String postId;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    postId = widget.postId;
    super.initState();
  }

  /// FAB – rust fill #C0522B, off-white icon.
  Widget _floatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        var state = Provider.of<FeedState>(context, listen: false);
        state.setTweetToReply = state.tweetDetailModel!.last;
        Navigator.of(context).pushNamed('/ComposeTweetPage/' + postId);
      },
      backgroundColor: AppColor.primary,
      foregroundColor: AppColor.extraExtraLightGrey,
      child: const Icon(Icons.add),
    );
  }

  /// Reply row – card background #2A1F1A.
  Widget _commentRow(FeedModel model) {
    return Container(
      color: AppColor.darkGrey,
      child: Tweet(
        model: model,
        type: TweetType.Reply,
        trailing: TweetBottomSheet().tweetOptionIcon(context,
            scaffoldKey: scaffoldKey, model: model, type: TweetType.Reply),
        scaffoldKey: scaffoldKey,
      ),
    );
  }

  /// Tweet detail card – background #3A2E28, border-radius 12px.
  Widget _tweetDetail(FeedModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.extraLightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Tweet(
        model: model,
        type: TweetType.Detail,
        trailing: TweetBottomSheet().tweetOptionIcon(context,
            scaffoldKey: scaffoldKey, model: model, type: TweetType.Detail),
        scaffoldKey: scaffoldKey,
      ),
    );
  }

  void addLikeToComment(String commentId) {
    var state = Provider.of<FeedState>(context, listen: false);
    var authState = Provider.of<AuthState>(context, listen: false);
    state.addLikeToTweet(state.tweetDetailModel!.last, authState.userId);
  }

  void openImage() async {
    Navigator.pushNamed(context, '/ImageViewPge');
  }

  void deleteTweet(TweetType type, String tweetId,
      {required String parentkey}) {
    var state = Provider.of<FeedState>(context, listen: false);
    state.deleteTweet(tweetId, type, parentkey: parentkey);
    Navigator.of(context).pop();
    if (type == TweetType.Detail) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<FeedState>(context);
    return WillPopScope(
      onWillPop: () async {
        Provider.of<FeedState>(context, listen: false)
            .removeLastTweetDetail(postId);
        return Future.value(true);
      },
      child: Scaffold(
        key: scaffoldKey,
        floatingActionButton: _floatingActionButton(),
        // Darkest cinder background #2A1F1A
        backgroundColor: AppColor.darkGrey,
        body: CustomScrollView(
          slivers: <Widget>[
            // AppBar – background #1C1410, off-white title
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColor.secondary,
              iconTheme:
                  const IconThemeData(color: AppColor.extraExtraLightGrey),
              title: Text(
                'Thread',
                style: GoogleFonts.mulish(
                  color: AppColor.extraExtraLightGrey,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: AppColor.extraLightGrey,
                  height: 1.0,
                ),
              ),
            ),

            // Tweet Detail Card – #3A2E28 background, radius 12px
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  state.tweetDetailModel == null ||
                          state.tweetDetailModel!.isEmpty
                      ? const SizedBox.shrink()
                      : _tweetDetail(state.tweetDetailModel!.last),
                  // Separator between detail and replies – taupe #8C7B72
                  Container(
                    height: 6,
                    width: double.infinity,
                    color: AppColor.lightGrey,
                  ),
                ],
              ),
            ),

            // Reply SliverList – thread line #8C7B72, card bg #2A1F1A
            SliverList(
              delegate: SliverChildListDelegate(
                state.tweetReplyMap == null ||
                        state.tweetReplyMap!.isEmpty ||
                        state.tweetReplyMap![postId] == null
                    ? [const Center()]
                    : state.tweetReplyMap![postId]!
                        .map((x) => _commentRow(x))
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
