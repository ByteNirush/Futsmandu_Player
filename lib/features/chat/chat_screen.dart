import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data
// ─────────────────────────────────────────────────────────────────────────────

class _Conversation {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final bool isGroup;

  const _Conversation({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unread,
    this.isOnline = false,
    this.isGroup = false,
  });
}

class _Message {
  final String text;
  final bool isMine;
  final String time;

  const _Message({
    required this.text,
    required this.isMine,
    required this.time,
  });
}

const _kConversations = [
  _Conversation(
    id: '1',
    name: 'Match Group - Tue',
    avatar: '',
    lastMessage: "Rohit: I'll be 5 min late",
    time: '08:41',
    unread: 3,
    isOnline: true,
    isGroup: true,
  ),
  _Conversation(
    id: '2',
    name: 'Aarav Shrestha',
    avatar: '',
    lastMessage: 'Good game yesterday!',
    time: '07:15',
    unread: 1,
    isOnline: true,
  ),
  _Conversation(
    id: '3',
    name: 'Futsal Crew',
    avatar: '',
    lastMessage: "Sagar: who's booking this week?",
    time: 'Mon',
    unread: 0,
    isGroup: true,
  ),
  _Conversation(
    id: '4',
    name: 'Priya Rai',
    avatar: '',
    lastMessage: 'See you at 6!',
    time: 'Sun',
    unread: 0,
    isOnline: false,
  ),
  _Conversation(
    id: '5',
    name: 'Bikash Tamang',
    avatar: '',
    lastMessage: 'Sent a match invite',
    time: 'Sat',
    unread: 0,
  ),
];

const _kMessages = [
  _Message(text: 'Hey! You playing tonight?', isMine: false, time: '07:00'),
  _Message(text: 'Yeah, booked a slot at 6 PM', isMine: true, time: '07:02'),
  _Message(text: "Nice! I'll join. Need 2 more players", isMine: false, time: '07:03'),
  _Message(text: 'Ask Rohit and Bikash', isMine: true, time: '07:04'),
  _Message(text: "Already did! They're in!", isMine: false, time: '07:05'),
  _Message(text: 'Perfect. See you all at 6', isMine: true, time: '07:06'),
  _Message(text: 'Good game yesterday!', isMine: false, time: '07:15'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Chat Screen (conversation list)
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chat',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _isSearching = !_isSearching);
                    },
                    icon: Icon(
                      _isSearching ? Icons.close : Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _NewChatButton(colorScheme: colorScheme),
                ],
              ),
            ),

            // ── Search bar (animated) ────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: textTheme.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'Search conversations…',
                          hintStyle: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          isDense: true,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Tabs ────────────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.md),
            _ChatTabBar(controller: _tabController),

            // ── Tab content ─────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All chats
                  _ConversationList(conversations: _kConversations),
                  // Groups only
                  _ConversationList(
                    conversations: _kConversations
                        .where((c) => c.isGroup)
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New chat button
// ─────────────────────────────────────────────────────────────────────────────

class _NewChatButton extends StatelessWidget {
  final ColorScheme colorScheme;
  const _NewChatButton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.edit_outlined,
          size: 18,
          color: colorScheme.primary,
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New conversation coming soon'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _ChatTabBar extends StatelessWidget {
  final TabController controller;
  const _ChatTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: AppFontWeights.semiBold,
              ),
          unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation list
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  final List<_Conversation> conversations;
  const _ConversationList({required this.conversations});

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: AppSpacing.lg + 52 + AppSpacing.md,
        endIndent: AppSpacing.lg,
        thickness: 0.5,
      ),
      itemBuilder: (context, i) => _ConversationTile(conversations[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation tile
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  const _ConversationTile(this.conversation);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = conversation.unread > 0;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ChatDetailScreen(conversation: conversation),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Avatar
            _ConversationAvatar(conversation: conversation),
            const SizedBox(width: AppSpacing.md),

            // Message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: hasUnread
                                ? AppFontWeights.semiBold
                                : AppFontWeights.regular,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.time,
                        style: textTheme.labelSmall?.copyWith(
                          color: hasUnread
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: hasUnread
                              ? AppFontWeights.semiBold
                              : AppFontWeights.regular,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: textTheme.bodySmall?.copyWith(
                            color: hasUnread
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontWeight: hasUnread
                                ? AppFontWeights.medium
                                : AppFontWeights.regular,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${conversation.unread}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: AppFontWeights.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation avatar
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationAvatar extends StatelessWidget {
  final _Conversation conversation;
  const _ConversationAvatar({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: conversation.isGroup
                ? colorScheme.secondaryContainer
                : colorScheme.primaryContainer,
          ),
          child: Center(
            child: Icon(
              conversation.isGroup
                  ? Icons.groups_rounded
                  : Icons.person_rounded,
              color: conversation.isGroup
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onPrimaryContainer,
              size: 26,
            ),
          ),
        ),
        if (conversation.isOnline && !conversation.isGroup)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat detail screen
// ─────────────────────────────────────────────────────────────────────────────

class _ChatDetailScreen extends StatefulWidget {
  final _Conversation conversation;
  const _ChatDetailScreen({required this.conversation});

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = List.from(_kMessages);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(
        text: text,
        isMine: true,
        time: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      ));
      _messageController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _ConversationAvatar(conversation: widget.conversation),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: AppFontWeights.semiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.conversation.isOnline ? 'Online' : 'Last seen recently',
                    style: textTheme.labelSmall?.copyWith(
                      color: widget.conversation.isOnline
                          ? const Color(0xFF22C55E)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.videocam_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () {},
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _MessageBubble(_messages[i]),
            ),
          ),

          // Input bar
          _MessageInputBar(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble(this.message);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isMine
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.lg),
                    topRight: const Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(isMine ? AppRadius.lg : 4),
                    bottomRight: Radius.circular(isMine ? 4 : AppRadius.lg),
                  ),
                ),
                child: Text(
                  message.text,
                  style: textTheme.bodySmall?.copyWith(
                    color: isMine
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message.time,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message input bar
// ─────────────────────────────────────────────────────────────────────────────

class _MessageInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInputBar({required this.controller, required this.onSend});

  @override
  State<_MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<_MessageInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + bottomInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emoji/attachment
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.xs),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: 5,
                minLines: 1,
                style: textTheme.bodySmall,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Send button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: _hasText
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: widget.onSend,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: colorScheme.onPrimary,
                        size: 18,
                      ),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('mic'),
                    icon: Icon(
                      Icons.mic_none_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {},
                  ),
          ),
        ],
      ),
    );
  }
}
