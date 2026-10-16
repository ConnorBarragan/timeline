import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/theme/app_theme.dart';
import 'package:flutter_twitter_clone/widgets/cache_image.dart';
import 'package:flutter_twitter_clone/widgets/tweet/widgets/tweetIconsRow.dart';
import 'package:provider/provider.dart';

class ImageViewPge extends StatefulWidget {
  const ImageViewPge({Key? key}) : super(key: key);

  @override
  _ImageViewPgeState createState() => _ImageViewPgeState();
}

class _ImageViewPgeState extends State<ImageViewPge> {
  bool isToolAvailable = true;

  late FocusNode _focusNode;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    _focusNode = FocusNode();
    _textEditingController = TextEditingController();
    super.initState();
  }

  Widget _body() {
    var state = Provider.of<FeedState>(context);
    return Stack(
      children: <Widget>[
        // ── Full-screen image on deep charcoal background ──────────────────
        Container(
          color: kSecondaryColor, // #1C1410
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: double.infinity,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isToolAvailable = !isToolAvailable;
                  });
                },
                child: _imageFeed(state.tweetDetailModel!.last.imagePath),
              ),
            ),
          ),
        ),

        // ── Black scrim overlay ────────────────────────────────────────────
        IgnorePointer(
          child: Container(
            color: Colors.black.withAlpha(100),
          ),
        ),

        // ── Back button – top-left circle ──────────────────────────────────
        if (isToolAvailable)
          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kExtraLightColor, // #3A2E28
                ),
                child: const BackButton(
                  color: kOffWhiteColor, // #F2EDE8
                ),
              ),
            ),
          ),

        // ── Bottom overlay: icon row + comment field ───────────────────────
        if (isToolAvailable)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                // Tweet icon row – icons off-white, active like rust
                Container(
                  color: kSecondaryColor.withAlpha(210), // #1C1410 scrim
                  child: TweetIconsRow(
                    model: state.tweetDetailModel!.last,
                    iconColor: kOffWhiteColor,       // #F2EDE8
                    iconEnableColor: kPrimaryColor,  // #C0522B (active like)
                    scaffoldKey: GlobalKey<ScaffoldState>(),
                  ),
                ),

                // Inline comment TextField
                Container(
                  color: kSecondaryColor.withAlpha(210),
                  padding: const EdgeInsets.only(
                      right: 10, left: 10, bottom: 10),
                  child: TextField(
                    controller: _textEditingController,
                    maxLines: null,
                    cursorColor: kPrimaryColor, // #C0522B
                    style: mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kOffWhiteColor, // #F2EDE8
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kExtraLightColor, // #3A2E28
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color: kLightGreyColor, // #8C7B72
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color: kLightGreyColor, // #8C7B72
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color: kPrimaryColor, // #C0522B when focused
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: _submitButton,
                        icon: const Icon(
                          Icons.send,
                          color: kPrimaryColor, // #C0522B
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      hintText: 'Comment here..',
                      hintStyle: mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kLightGreyColor, // #8C7B72
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _imageFeed(String? _image) {
    return _image == null
        ? Container()
        : Container(
            alignment: Alignment.center,
            child: InteractiveViewer(
              child: CacheImage(
                path: _image,
                fit: BoxFit.fitWidth,
              ),
            ),
          );
  }

  void _submitButton() {
    if (_textEditingController.text.isEmpty) {
      return;
    }
    if (_textEditingController.text.length > 280) {
      return;
    }
    var state = Provider.of<FeedState>(context, listen: false);
    var authState = Provider.of<AuthState>(context, listen: false);
    var user = authState.userModel;
    var profilePic = user!.profilePic;
    profilePic ??= Constants.dummyProfilePic;
    var name = authState.userModel!.displayName ??
        authState.userModel!.email!.split('@')[0];
    var pic = authState.userModel!.profilePic ?? Constants.dummyProfilePic;
    var tags = Utility.getHashTags(_textEditingController.text);

    UserModel commentedUser = UserModel(
        displayName: name,
        userName: authState.userModel!.userName,
        isVerified: authState.userModel!.isVerified,
        profilePic: pic,
        userId: authState.userId);

    var postId = state.tweetDetailModel!.last.key;

    FeedModel reply = FeedModel(
      description: _textEditingController.text,
      user: commentedUser,
      createdAt: DateTime.now().toUtc().toString(),
      tags: tags,
      userId: commentedUser.userId!,
      parentkey: postId,
    );
    state.addCommentToPost(reply);
    FocusScope.of(context).requestFocus(_focusNode);
    setState(() {
      _textEditingController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSecondaryColor, // #1C1410
      body: _body(),
    );
  }
}
