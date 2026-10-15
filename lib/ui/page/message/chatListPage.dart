import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/chatModel.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/chats/chatState.dart';
import 'package:flutter_twitter_clone/state/searchState.dart';
import 'package:flutter_twitter_clone/ui/page/message/chatScreenPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
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
const double _kWideBreakpoint = 800.0;

// ---------------------------------------------------------------------------
// ChatListPage – InboxOverview
// ---------------------------------------------------------------------------

class ChatListPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ChatListPage({Key? key, required this.scaffoldKey}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  /// The currently selected user for the right panel (wide screens only).
  UserModel? _selectedUser;

  @override
  void initState() {
    super.initState();
    final chatState = Provider.of<ChatState>(context, listen: false);
    final state = Provider.of<AuthState>(context, listen: false);
    chatState.setIsChatScreenOpen = true;
    chatState.getUserChatList(state.user!.uid);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) context.read<SearchState>().resetFilterList();
  }

  void _openChat(BuildContext context, UserModel user) {
    final chatState = Provider.of<ChatState>(context, listen: false);
    chatState.setChatUser = user;

    final isWide = MediaQuery.of(context).size.width >= _kWideBreakpoint;
    if (isWide) {
      setState(() => _selectedUser = user);
    } else {
      Navigator.pushNamed(context, '/ChatScreenPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Messages',
          style: GoogleFonts.mulish(
            color: _kSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _kSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: _kSecondary),
            tooltip: 'DM Settings',
            onPressed: () =>
                Navigator.pushNamed(context, '/DirectMessagesPage'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/NewMessagePage'),
        backgroundColor: _kPrimary,
        tooltip: 'New Message',
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _kWideBreakpoint;

          if (isWide) {
            // ── Wide: two-panel Row layout ─────────────────────────────
            return Row(
              children: [
                // Left panel: conversation list
                SizedBox(
                  width: 320,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: _kExtraLight),
                      ),
                    ),
                    child: _ConversationList(
                      selectedUserId: _selectedUser?.userId,
                      onUserTap: (user) => _openChat(context, user),
                    ),
                  ),
                ),
                // Right panel: active chat thread
                Expanded(
                  child: _selectedUser == null
                      ? _EmptyChatPanel()
                      : ChatScreenPage(
                          key: ValueKey(_selectedUser!.userId),
                        ),
                ),
              ],
            );
          } else {
            // ── Narrow: single-column list ─────────────────────────────
            return _ConversationList(
              selectedUserId: null,
              onUserTap: (user) => _openChat(context, user),
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ConversationList – left panel / narrow-screen list
// ---------------------------------------------------------------------------

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    Key? key,
    required this.onUserTap,
    this.selectedUserId,
  }) : super(key: key);

  final ValueChanged<UserModel> onUserTap;
  final String? selectedUserId;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatState, SearchState>(
      builder: (context, chatState, searchState, _) {
        final chatList = chatState.chatUserList;

        if (chatList == null || chatList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: EmptyList(
              'No messages yet',
              subTitle:
                  'When someone sends you a message, it will show up here.',
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: chatList.length,
          itemBuilder: (context, index) {
            final lastMessage = chatList[index];
            final userList = searchState.userlist;
            final user = userList?.firstWhere(
              (x) => x.userId == lastMessage.key,
              orElse: () => UserModel(userName: 'Unknown'),
            );

            if (user == null) return const SizedBox.shrink();

            // Derive unread count: if the last message is unseen and was
            // sent by the other user (not by us), treat it as 1 unread.
            final authState =
                Provider.of<AuthState>(context, listen: false);
            final isUnread = !lastMessage.seen &&
                lastMessage.senderId != authState.userId;
            final unreadCount = isUnread ? 1 : 0;

            return _ConversationCard(
              user: user,
              lastMessage: lastMessage,
              unreadCount: unreadCount,
              isSelected: selectedUserId == user.userId,
              onTap: () => onUserTap(user),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _ConversationCard – single conversation card with optional unread badge
// ---------------------------------------------------------------------------

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    Key? key,
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  final UserModel user;
  final ChatMessage lastMessage;
  final int unreadCount;
  final VoidCallback onTap;
  final bool isSelected;

  String? _truncateMessage(String? message) {
    if (message == null || message.isEmpty) return null;
    return message.length > 80 ? '${message.substring(0, 80)}...' : message;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? _kPrimary.withOpacity(0.08)
            : hasUnread
                ? _kPrimary.withOpacity(0.04)
                : Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(
          color: isSelected
              ? _kPrimary.withOpacity(0.3)
              : hasUnread
                  ? _kPrimary.withOpacity(0.2)
                  : _kExtraLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_kRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // ── Avatar ──────────────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    ProfilePage.getRoute(profileId: user.userId!),
                  ),
                  child: CircularImage(
                    path: user.profilePic ?? Constants.dummyProfilePic,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Name + last message ──────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display name row
                      Text(
                        user.displayName ?? 'Unknown',
                        style: GoogleFonts.mulish(
                          fontWeight: hasUnread
                              ? FontWeight.w900
                              : FontWeight.w700,
                          fontSize: 14,
                          color: _kSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Last message preview
                      Text(
                        _truncateMessage(lastMessage.message) ??
                            '@${user.userName ?? ''}',
                        style: GoogleFonts.mulish(
                          fontSize: 13,
                          color: hasUnread ? _kSecondary : _kLightGrey,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Right column: timestamp + unread badge ───────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timestamp
                    if (lastMessage.createdAt != null)
                      Text(
                        Utility.getChatTime(lastMessage.createdAt),
                        style: GoogleFonts.mulish(
                          fontSize: 11,
                          color: hasUnread ? _kPrimary : _kLightGrey,
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    // Unread badge
                    if (hasUnread) ...[
                      const SizedBox(height: 4),
                      _UnreadBadge(count: unreadCount),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _UnreadBadge – circular badge with #1DA1F2 background
// ---------------------------------------------------------------------------

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({Key? key, required this.count}) : super(key: key);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: _kPrimary,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.mulish(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyChatPanel – placeholder shown in the right panel when no chat is open
// ---------------------------------------------------------------------------

class _EmptyChatPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mail_outline, color: _kPrimary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a conversation',
            style: GoogleFonts.mulish(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: _kSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from your existing conversations\nor start a new one.',
            style: GoogleFonts.mulish(
              fontSize: 14,
              color: _kLightGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
