import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/state/searchState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/composeTweet/state/composeTweetState.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/ui/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';

// ---------------------------------------------------------------------------
// Cinder Rust palette tokens (local aliases for readability)
// ---------------------------------------------------------------------------
const Color _kPrimary = kPrimaryColor;          // #C0522B – rust
const Color _kBackground = kBackgroundColor;    // #2A1F1A – compose body bg
const Color _kAppBar = kSecondaryColor;         // #1C1410 – AppBar bg
const Color _kCard = kExtraLightColor;          // #3A2E28 – image preview border / mention list
const Color _kOffWhite = kOffWhiteColor;        // #F2EDE8 – primary text / icons
const Color _kTaupe = kLightGreyColor;          // #8C7B72 – counter / hint / secondary text

// ---------------------------------------------------------------------------
// ComposeTweetPage – kept as a full-page route for back-compat (retweet/reply)
// ---------------------------------------------------------------------------

class ComposeTweetPage extends StatefulWidget {
  const ComposeTweetPage({
    Key? key,
    required this.isRetweet,
    this.isTweet = true,
  }) : super(key: key);

  final bool isRetweet;
  final bool isTweet;

  @override
  State<ComposeTweetPage> createState() => _ComposeTweetPageState();
}

class _ComposeTweetPageState extends State<ComposeTweetPage> {
  final TextEditingController _controller = TextEditingController();
  File? _image;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _remaining => 280 - _controller.text.length;
  bool get _canSubmit =>
      _controller.text.isNotEmpty &&
      _controller.text.length <= 280 &&
      !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final feedState = Provider.of<FeedState>(context, listen: false);
    final authState = Provider.of<AuthState>(context, listen: false);
    final composeState =
        Provider.of<ComposeTweetState>(context, listen: false);
    final searchState = Provider.of<SearchState>(context, listen: false);

    kScreenLoader.showLoader(context);

    final tweetModel = await _buildTweetModel(authState, feedState);
    String? tweetId;

    if (_image != null) {
      final imagePath = await feedState.uploadFile(_image!);
      if (imagePath != null) {
        tweetModel.imagePath = imagePath;
        tweetId = await _postTweet(feedState, tweetModel);
      }
    } else {
      tweetId = await _postTweet(feedState, tweetModel);
    }

    tweetModel.key = tweetId;

    await composeState.sendNotification(tweetModel, searchState).then((_) {
      kScreenLoader.hideLoader();
      if (mounted) Navigator.pop(context);
    });
  }

  Future<String?> _postTweet(FeedState state, FeedModel model) async {
    if (widget.isTweet) return state.createTweet(model);
    if (widget.isRetweet) return state.createReTweet(model);
    return state.addCommentToPost(model);
  }

  Future<FeedModel> _buildTweetModel(
      AuthState authState, FeedState feedState) async {
    final myUser = authState.userModel!;
    final profilePic = myUser.profilePic ?? Constants.dummyProfilePic;
    final commentedUser = UserModel(
      displayName: myUser.displayName ?? myUser.email!.split('@')[0],
      profilePic: profilePic,
      userId: myUser.userId,
      isVerified: myUser.isVerified,
      userName: myUser.userName,
    );
    final tags = Utility.getHashTags(_controller.text);
    return FeedModel(
      description: _controller.text,
      lanCode: (await GoogleTranslator().translate(_controller.text))
          .sourceLanguage
          .code,
      user: commentedUser,
      createdAt: DateTime.now().toUtc().toString(),
      tags: tags,
      parentkey: widget.isTweet
          ? null
          : widget.isRetweet
              ? null
              : feedState.tweetToReplyModel?.key,
      childRetwetkey: widget.isTweet
          ? null
          : widget.isRetweet
              ? feedState.tweetToReplyModel?.key
              : null,
      userId: myUser.userId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: false);
    return Scaffold(
      // Compose body background: #2A1F1A
      backgroundColor: _kBackground,
      appBar: AppBar(
        // AppBar background: #1C1410
        backgroundColor: _kAppBar,
        elevation: 0,
        leading: IconButton(
          // Close icon: #F2EDE8
          icon: const Icon(Icons.close, color: _kOffWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                // Tweet button fill: rust #C0522B
                backgroundColor: _kPrimary,
                // Tweet button text: #F2EDE8
                foregroundColor: _kOffWhite,
                disabledBackgroundColor: _kPrimary.withOpacity(0.45),
                disabledForegroundColor: _kOffWhite.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kOffWhite),
                    )
                  : Text(
                      'Tweet',
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w800,
                        color: _kOffWhite,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _ComposeTweetBody(
        controller: _controller,
        image: _image,
        remaining: _remaining,
        onImageSelected: (f) => setState(() => _image = f),
        onImageRemoved: () => setState(() => _image = null),
        onChanged: (_) => setState(() {}),
        profilePic: authState.userModel?.profilePic,
        isTweet: widget.isTweet,
        isRetweet: widget.isRetweet,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared compose body (used by both full-page and bottom-sheet variants)
// ---------------------------------------------------------------------------

class _ComposeTweetBody extends StatelessWidget {
  const _ComposeTweetBody({
    Key? key,
    required this.controller,
    required this.image,
    required this.remaining,
    required this.onImageSelected,
    required this.onImageRemoved,
    required this.onChanged,
    this.profilePic,
    this.isTweet = true,
    this.isRetweet = false,
  }) : super(key: key);

  final TextEditingController controller;
  final File? image;
  final int remaining;
  final ValueChanged<File> onImageSelected;
  final VoidCallback onImageRemoved;
  final ValueChanged<String> onChanged;
  final String? profilePic;
  final bool isTweet;
  final bool isRetweet;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircularImage(path: profilePic, height: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Character counter: taupe #8C7B72 (red/orange when near limit)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$remaining',
                          style: GoogleFonts.mulish(
                            color: remaining < 0
                                ? Colors.red
                                : remaining < 20
                                    ? Colors.orange
                                    : _kTaupe,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // Text field – caret rust #C0522B
                    Consumer<ComposeTweetState>(
                      builder: (context, composeState, _) {
                        return TextField(
                          controller: controller,
                          maxLines: null,
                          autofocus: true,
                          cursorColor: _kPrimary,
                          onChanged: (text) {
                            onChanged(text);
                            try {
                              final searchState = Provider.of<SearchState>(
                                  context,
                                  listen: false);
                              composeState.onDescriptionChanged(
                                  text, searchState);
                            } catch (_) {}
                          },
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            color: _kOffWhite,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: isTweet
                                ? "What's happening?"
                                : isRetweet
                                    ? 'Add a comment'
                                    : 'Tweet your reply',
                            hintStyle: GoogleFonts.mulish(
                              color: _kTaupe,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                    // Mention suggestion list
                    Consumer<ComposeTweetState>(
                      builder: (context, composeState, _) {
                        if (!composeState.displayUserList) {
                          return const SizedBox.shrink();
                        }
                        final searchState =
                            Provider.of<SearchState>(context, listen: false);
                        final users = searchState.userlist;
                        if (users == null || users.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        // Mention dropdown: card surface #3A2E28, border taupe #8C7B72
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: _kCard,
                            border: Border.all(color: _kTaupe),
                            borderRadius: BorderRadius.circular(kCardRadius),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, i) {
                              final user = users[i];
                              return ListTile(
                                leading: CircularImage(
                                    path: user.profilePic, height: 32),
                                title: Text(
                                  user.displayName ?? '',
                                  style: GoogleFonts.mulish(
                                    fontWeight: FontWeight.w700,
                                    color: _kOffWhite,
                                  ),
                                ),
                                subtitle: Text(
                                  '@${user.userName ?? ''}',
                                  style: GoogleFonts.mulish(
                                    color: _kTaupe,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () {
                                  controller.text = composeState
                                          .getDescription(user.userName!) +
                                      ' ';
                                  controller.selection =
                                      TextSelection.collapsed(
                                          offset: controller.text.length);
                                  composeState.onUserSelected();
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Image preview – border #3A2E28
          if (image != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: Border.all(color: _kCard, width: 2),
                    image: DecorationImage(
                      image: FileImage(image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onImageRemoved,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          color: _kOffWhite, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Bottom toolbar
          Row(
            children: [
              // Image picker icon: rust #C0522B
              IconButton(
                icon: const Icon(Icons.image_outlined, color: _kPrimary),
                onPressed: () async {
                  final file = await _pickImage(ImageSource.gallery);
                  if (file != null) onImageSelected(file);
                },
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: _kPrimary),
                onPressed: () async {
                  final file = await _pickImage(ImageSource.camera);
                  if (file != null) onImageSelected(file);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<File?> _pickImage(ImageSource source) async {
    try {
      final xfile =
          await ImagePicker().pickImage(source: source, imageQuality: 20);
      if (xfile == null) return null;
      return File(xfile.path);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// ComposeTweetBottomSheet – inline bottom-sheet compose (used from FeedPage FAB)
// ---------------------------------------------------------------------------

class ComposeTweetBottomSheet extends StatefulWidget {
  const ComposeTweetBottomSheet({Key? key}) : super(key: key);

  @override
  State<ComposeTweetBottomSheet> createState() =>
      _ComposeTweetBottomSheetState();
}

class _ComposeTweetBottomSheetState extends State<ComposeTweetBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  File? _image;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _remaining => 280 - _controller.text.length;
  bool get _canSubmit =>
      _controller.text.isNotEmpty &&
      _controller.text.length <= 280 &&
      !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final feedState = Provider.of<FeedState>(context, listen: false);
    final authState = Provider.of<AuthState>(context, listen: false);
    final composeState =
        Provider.of<ComposeTweetState>(context, listen: false);
    final searchState = Provider.of<SearchState>(context, listen: false);

    final myUser = authState.userModel!;
    final tweetModel = FeedModel(
      description: _controller.text,
      userId: myUser.userId!,
      createdAt: DateTime.now().toUtc().toString(),
      user: myUser,
      tags: Utility.getHashTags(_controller.text),
    );

    if (_image != null) {
      final imagePath = await feedState.uploadFile(_image!);
      if (imagePath != null) tweetModel.imagePath = imagePath;
    }

    final tweetId = await feedState.createTweet(tweetModel);
    tweetModel.key = tweetId;

    await composeState.sendNotification(tweetModel, searchState);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: false);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        // Bottom sheet background: compose body #2A1F1A
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: bottomInset + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _kTaupe,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Header row
          Row(
            children: [
              CircularImage(
                path: authState.userModel?.profilePic,
                height: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "What's happening?",
                  style: GoogleFonts.mulish(color: _kTaupe, fontSize: 15),
                ),
              ),
              // Character counter: taupe #8C7B72
              Text(
                '$_remaining',
                style: GoogleFonts.mulish(
                  color: _remaining < 0
                      ? Colors.red
                      : _remaining < 20
                          ? Colors.orange
                          : _kTaupe,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Text field + mention suggestions
          Consumer<ComposeTweetState>(
            builder: (context, composeState, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: null,
                    autofocus: true,
                    // Caret rust #C0522B
                    cursorColor: _kPrimary,
                    onChanged: (text) {
                      setState(() {});
                      try {
                        final searchState =
                            Provider.of<SearchState>(context, listen: false);
                        composeState.onDescriptionChanged(text, searchState);
                      } catch (_) {}
                    },
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      color: _kOffWhite,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "What's happening?",
                      hintStyle: GoogleFonts.mulish(color: _kTaupe),
                    ),
                  ),
                  // Mention suggestion list
                  if (composeState.displayUserList)
                    Consumer<SearchState>(
                      builder: (context, searchState, _) {
                        final users = searchState.userlist;
                        if (users == null || users.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        // Mention dropdown: card surface #3A2E28, border taupe #8C7B72
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 160),
                          decoration: BoxDecoration(
                            color: _kCard,
                            border: Border.all(color: _kTaupe),
                            borderRadius: BorderRadius.circular(kCardRadius),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, i) {
                              final user = users[i];
                              return ListTile(
                                dense: true,
                                leading: CircularImage(
                                    path: user.profilePic, height: 28),
                                title: Text(
                                  user.displayName ?? '',
                                  style: GoogleFonts.mulish(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _kOffWhite,
                                  ),
                                ),
                                subtitle: Text(
                                  '@${user.userName ?? ''}',
                                  style: GoogleFonts.mulish(
                                    color: _kTaupe,
                                    fontSize: 11,
                                  ),
                                ),
                                onTap: () {
                                  _controller.text = composeState
                                          .getDescription(user.userName!) +
                                      ' ';
                                  _controller.selection =
                                      TextSelection.collapsed(
                                          offset: _controller.text.length);
                                  composeState.onUserSelected();
                                  setState(() {});
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
          // Image preview – border #3A2E28
          if (_image != null) ...[
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: Border.all(color: _kCard, width: 2),
                    image: DecorationImage(
                      image: FileImage(_image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _image = null),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(Icons.close,
                          color: _kOffWhite, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Toolbar
          Row(
            children: [
              // Image picker icon: rust #C0522B
              IconButton(
                icon: const Icon(Icons.image_outlined, color: _kPrimary),
                onPressed: () async {
                  try {
                    final xfile = await ImagePicker().pickImage(
                        source: ImageSource.gallery, imageQuality: 20);
                    if (xfile != null) {
                      setState(() => _image = File(xfile.path));
                    }
                  } catch (_) {}
                },
              ),
              const Spacer(),
              // Tweet submit button: rust fill #C0522B, text #F2EDE8
              ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: _kOffWhite,
                  disabledBackgroundColor: _kPrimary.withOpacity(0.45),
                  disabledForegroundColor: _kOffWhite.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kOffWhite),
                      )
                    : Text(
                        'Tweet',
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _kOffWhite,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
