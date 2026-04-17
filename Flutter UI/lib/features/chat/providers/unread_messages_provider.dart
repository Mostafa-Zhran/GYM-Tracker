import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/features/chat/models/chat_message_model.dart';

// ── Unread Messages State ─────────────────────────────────────────────────────

class UnreadMessagesState {
  final Map<String, int> unreadCounts; // userId -> count

  const UnreadMessagesState({this.unreadCounts = const {}});

  UnreadMessagesState copyWith({Map<String, int>? unreadCounts}) {
    return UnreadMessagesState(
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  int getCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  int get totalCount {
    return unreadCounts.values.fold(0, (sum, count) => sum + count);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final unreadMessagesProvider =
    StateNotifierProvider<UnreadMessagesNotifier, UnreadMessagesState>((ref) {
  return UnreadMessagesNotifier();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class UnreadMessagesNotifier extends StateNotifier<UnreadMessagesState> {
  UnreadMessagesNotifier() : super(const UnreadMessagesState());

  // Increment unread count for a user
  void incrementUnread(String userId) {
    final currentCounts = Map<String, int>.from(state.unreadCounts);
    currentCounts[userId] = (currentCounts[userId] ?? 0) + 1;
    state = state.copyWith(unreadCounts: currentCounts);
  }

  // Decrement unread count for a user
  void decrementUnread(String userId) {
    final currentCounts = Map<String, int>.from(state.unreadCounts);
    final currentCount = currentCounts[userId] ?? 0;
    if (currentCount > 0) {
      currentCounts[userId] = currentCount - 1;
      if (currentCounts[userId] == 0) {
        currentCounts.remove(userId);
      }
      state = state.copyWith(unreadCounts: currentCounts);
    }
  }

  // Set unread count for a user (when loading initial messages)
  void setUnreadCount(String userId, int count) {
    final currentCounts = Map<String, int>.from(state.unreadCounts);
    if (count > 0) {
      currentCounts[userId] = count;
    } else {
      currentCounts.remove(userId);
    }
    state = state.copyWith(unreadCounts: currentCounts);
  }

  // Mark all messages from a user as read
  void markAsRead(String userId) {
    final currentCounts = Map<String, int>.from(state.unreadCounts);
    currentCounts.remove(userId);
    state = state.copyWith(unreadCounts: currentCounts);
  }

  // Clear all unread counts
  void clearAll() {
    state = const UnreadMessagesState();
  }

  // Process a list of messages to update unread counts
  void processMessages(List<ChatMessageModel> messages, String currentUserId) {
    final currentCounts = Map<String, int>.from(state.unreadCounts);
    
    for (final message in messages) {
      // Only count messages from other users that are not seen
      if (message.senderId != currentUserId && !message.isSeen) {
        currentCounts[message.senderId] = (currentCounts[message.senderId] ?? 0) + 1;
      }
    }
    
    state = state.copyWith(unreadCounts: currentCounts);
  }
}
