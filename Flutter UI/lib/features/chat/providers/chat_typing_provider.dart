import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/features/chat/data/chat_signalr_service.dart';

// ── Typing State ──────────────────────────────────────────────────────────

class TypingState {
  final bool isOtherUserTyping;
  final String otherUserId;

  const TypingState({
    this.isOtherUserTyping = false,
    this.otherUserId = '',
  });

  TypingState copyWith({bool? isOtherUserTyping, String? otherUserId}) {
    return TypingState(
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      otherUserId: otherUserId ?? this.otherUserId,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

/// Family provider keyed by [otherUserId] — one typing state per conversation.
final chatTypingProvider =
    StateNotifierProvider.family<ChatTypingNotifier, TypingState, String>(
  (ref, otherUserId) {
    final signalR = ref.read(chatSignalRServiceProvider);
    return ChatTypingNotifier(
      otherUserId: otherUserId,
      signalR: signalR,
    );
  },
);

// ── Notifier ──────────────────────────────────────────────────────────────

class ChatTypingNotifier extends StateNotifier<TypingState> {
  final String _otherUserId;
  final ChatSignalRService _signalR;

  Timer? _hideTimer;

  ChatTypingNotifier({
    required String otherUserId,
    required ChatSignalRService signalR,
  })  : _otherUserId = otherUserId,
        _signalR = signalR,
        super(const TypingState()) {
    _listenForTyping();
  }

  // ── Listen to SignalR typing events ───────────────────────────────────────

  void _listenForTyping() {
    _signalR.onUserTyping = (senderId) {
      // Only show typing indicator for the current conversation partner
      if (senderId != _otherUserId) return;

      // Show typing indicator
      state = state.copyWith(
        isOtherUserTyping: true,
        otherUserId: senderId,
      );

      // Auto-hide after 3 seconds of no new typing event
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(isOtherUserTyping: false);
        }
      });
    };
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _hideTimer?.cancel();
    _signalR.onUserTyping = null;
    super.dispose();
  }
}
