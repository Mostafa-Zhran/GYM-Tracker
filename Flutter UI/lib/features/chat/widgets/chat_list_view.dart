import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Gym/features/chat/models/chat_message_model.dart';
import 'package:Gym/features/chat/widgets/message_bubble.dart';
import 'package:Gym/features/chat/widgets/typing_indicator.dart';

/// Scrollable message list with:
/// - Infinite scroll (loads older messages on scroll to top)
/// - Date separators between days
/// - Typing indicator at bottom
/// - Auto-scroll to latest message
class ChatListView extends StatefulWidget {
  final List<ChatMessageModel> messages;
  final String currentUserId;
  final bool isLoadingMore;
  final bool isTyping;
  final String otherUserName;
  final VoidCallback onLoadMore;
  final ScrollController scrollController;

  const ChatListView({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.isLoadingMore,
    required this.isTyping,
    required this.otherUserName,
    required this.onLoadMore,
    required this.scrollController,
  });

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  /// Trigger load more when user scrolls near the top (threshold: 150px)
  void _onScroll() {
    final position = widget.scrollController.position;
    if (position.pixels <= 150 && position.maxScrollExtent > 0) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        // ── Loading more indicator at top ─────────────────────────────
        if (widget.isLoadingMore)
          const SliverToBoxAdapter(
            child: _LoadingMoreIndicator(),
          ),

        // ── Message list ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final message = widget.messages[index];
                final isMe = message.senderId == widget.currentUserId;

                // Show date separator when day changes
                final showDate = index == 0 ||
                    !_isSameDay(
                      widget.messages[index - 1].timestamp,
                      message.timestamp,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDate) _DateSeparator(date: message.timestamp),
                    MessageBubble(message: message, isMe: isMe),
                  ],
                );
              },
              childCount: widget.messages.length,
            ),
          ),
        ),

        // ── Typing indicator ──────────────────────────────────────────
        if (widget.isTyping)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverToBoxAdapter(
              child: TypingIndicator(userName: widget.otherUserName),
            ),
          ),

        // ── Bottom padding ────────────────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ── Date Separator ────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Color(0xFF1F2937),
                ]),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Text(
              _label(date),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0xFF1F2937),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading More Indicator ────────────────────────────────────────────────

class _LoadingMoreIndicator extends StatelessWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading older messages...',
            style: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
