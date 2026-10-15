import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/notificationModel.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/notificationState.dart';
import 'package:flutter_twitter_clone/ui/page/notification/widget/follow_notification_tile.dart';
import 'package:flutter_twitter_clone/ui/page/notification/widget/post_like_tile.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/emptyList.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const Color _kPrimary = Color(0xFF1DA1F2);
const Color _kCardSurface = Color(0xFF14171A);
const Color _kLightGrey = Color(0xFFAAB8C2);
const Color _kExtraLight = Color(0xFFE1E8ED);

// ---------------------------------------------------------------------------
// NotificationPage – kept as a named route target (home page uses it)
// ---------------------------------------------------------------------------

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<NotificationState>(context, listen: false);
      final authState = Provider.of<AuthState>(context, listen: false);
      state.getDataFromDatabase(authState.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.mulish(
            color: _kCardSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _kCardSurface),
      ),
      body: const _NotificationListBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// NotificationBottomSheet – slide-up DraggableScrollableSheet
// ---------------------------------------------------------------------------

class NotificationBottomSheet extends StatefulWidget {
  const NotificationBottomSheet({Key? key}) : super(key: key);

  @override
  State<NotificationBottomSheet> createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<NotificationState>(context, listen: false);
      final authState = Provider.of<AuthState>(context, listen: false);
      state.getDataFromDatabase(authState.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _kExtraLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.mulish(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kCardSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Mark all read',
                        style: GoogleFonts.mulish(
                          color: _kPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _kExtraLight),
              // Filter chips + list
              Expanded(
                child: _FilterableNotificationList(
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Filterable notification list with chips
// ---------------------------------------------------------------------------

enum _NotifFilter { all, likes, retweets, follows }

class _FilterableNotificationList extends StatefulWidget {
  const _FilterableNotificationList({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  State<_FilterableNotificationList> createState() =>
      _FilterableNotificationListState();
}

class _FilterableNotificationListState
    extends State<_FilterableNotificationList> {
  _NotifFilter _filter = _NotifFilter.all;

  List<NotificationModel> _applyFilter(List<NotificationModel> list) {
    switch (_filter) {
      case _NotifFilter.all:
        return list;
      case _NotifFilter.likes:
        return list
            .where((n) => n.type == NotificationType.Like.toString())
            .toList();
      case _NotifFilter.retweets:
        return list
            .where((n) => n.type == NotificationType.Retweet.toString())
            .toList();
      case _NotifFilter.follows:
        return list
            .where((n) => n.type == NotificationType.Follow.toString())
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips row
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _FilterChip(
                label: 'All',
                isActive: _filter == _NotifFilter.all,
                onTap: () => setState(() => _filter = _NotifFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Likes',
                isActive: _filter == _NotifFilter.likes,
                onTap: () => setState(() => _filter = _NotifFilter.likes),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Retweets',
                isActive: _filter == _NotifFilter.retweets,
                onTap: () => setState(() => _filter = _NotifFilter.retweets),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Follows',
                isActive: _filter == _NotifFilter.follows,
                onTap: () => setState(() => _filter = _NotifFilter.follows),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _kExtraLight),
        // Notification list
        Expanded(
          child: Consumer<NotificationState>(
            builder: (context, state, _) {
              if (state.isbusy) {
                return const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                );
              }

              final raw = state.notificationList;
              if (raw == null || raw.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: EmptyList(
                    'No notifications yet',
                    subTitle:
                        'When someone likes or retweets your tweet, it will show up here.',
                  ),
                );
              }

              final filtered = _applyFilter(raw);
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No ${_filter.toString().split(".").last} notifications',
                    style: GoogleFonts.mulish(
                      color: _kLightGrey,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final model = filtered[index];
                  return _DismissibleNotifItem(
                    key: ValueKey(model.id ?? index.toString()),
                    model: model,
                    onDismissed: () {
                      final authState =
                          Provider.of<AuthState>(context, listen: false);
                      if (model.tweetKey != null) {
                        state.removeNotification(
                            authState.userId, model.tweetKey!);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip widget
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    Key? key,
    required this.label,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _kPrimary : _kExtraLight,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.mulish(
            color: isActive ? Colors.white : _kLightGrey,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dismissible notification item
// ---------------------------------------------------------------------------

class _DismissibleNotifItem extends StatelessWidget {
  const _DismissibleNotifItem({
    Key? key,
    required this.model,
    required this.onDismissed,
  }) : super(key: key);

  final NotificationModel model;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(model.id ?? model.tweetKey ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDismissed(),
      child: _NotificationRow(model: model),
    );
  }
}

// ---------------------------------------------------------------------------
// Single notification row
// ---------------------------------------------------------------------------

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({Key? key, required this.model}) : super(key: key);
  final NotificationModel model;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<NotificationState>(context, listen: false);

    if (model.type == NotificationType.Follow.toString()) {
      return FollowNotificationTile(model: model);
    }

    // Guard against null tweetKey for non-follow notifications
    if (model.tweetKey == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<FeedModel?>(
      future: state.getTweetDetail(model.tweetKey!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 4,
            child: LinearProgressIndicator(color: _kPrimary),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return PostLikeTile(model: snapshot.data!);
        }
        // Tweet deleted – remove notification
        final authState = Provider.of<AuthState>(context, listen: false);
        state.removeNotification(authState.userId, model.tweetKey!);
        return const SizedBox.shrink();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Standalone body (used by the route-based NotificationPage)
// ---------------------------------------------------------------------------

class _NotificationListBody extends StatelessWidget {
  const _NotificationListBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationState>(
      builder: (context, state, _) {
        if (state.isbusy) {
          return const SizedBox(
            height: 3,
            child: LinearProgressIndicator(color: _kPrimary),
          );
        }
        final list = state.notificationList;
        if (list == null || list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: EmptyList(
              'No Notification available yet',
              subTitle: 'When new notification found, they\'ll show up here.',
            ),
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) =>
              _NotificationRow(model: list[index]),
        );
      },
    );
  }
}
