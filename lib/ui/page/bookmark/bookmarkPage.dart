import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/bookmarkState.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/theme/theme.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/emptyList.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const Color _kPrimary = Color(0xFF1DA1F2);
const Color _kCardSurface = Color(0xFF14171A);
const Color _kLightGrey = Color(0xFFAAB8C2);

// ---------------------------------------------------------------------------
// BookmarkPage – standalone route (back-compat) + embeddable reel widget
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Bookmarks',
          style: GoogleFonts.mulish(
            color: _kCardSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _kCardSurface),
      ),
      body: const BookmarkReelWidget(),
    );
  }
}

// ---------------------------------------------------------------------------
// BookmarkReelWidget – horizontally scrollable mini-card reel
// Can be embedded in ProfilePage or used standalone.
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
                  color: _kCardSurface,
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

// ---------------------------------------------------------------------------
// Mini-card
// ---------------------------------------------------------------------------

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
          color: _kCardSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Optional thumbnail background
              if (model.imagePath != null && model.imagePath!.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: model.imagePath!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
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
                        _kCardSurface.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Author handle
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
                    // Tweet text (2-line overflow)
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

              // Bookmark icon badge
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
