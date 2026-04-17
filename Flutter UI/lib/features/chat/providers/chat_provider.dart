import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/features/chat/data/chat_repository.dart';
import 'package:Gym/features/chat/data/chat_signalr_service.dart'; // ✅
import 'package:Gym/features/chat/models/chat_message_model.dart';
import 'package:Gym/features/chat/models/chat_pagination_model.dart';
import 'package:Gym/features/chat/providers/unread_messages_provider.dart';
import 'package:Gym/features/auth/providers/auth_provider.dart';

// ── Chat State ────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessageModel> messages;
  final ChatPaginationModel pagination;
  final bool isLoadingHistory;
  final bool isLoadingMore;
  final bool isSending;
  final bool isConnected;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.pagination = const ChatPaginationModel.initial(),
    this.isLoadingHistory = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.isConnected = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    ChatPaginationModel? pagination,
    bool? isLoadingHistory,
    bool? isLoadingMore,
    bool? isSending,
    bool? isConnected,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      pagination: pagination ?? this.pagination,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      isConnected: isConnected ?? this.isConnected,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, otherUserId) {
    return ChatNotifier(
      otherUserId: otherUserId,
      repository: ref.read(chatRepositoryProvider),
      signalR: ref.read(chatSignalRServiceProvider), // ✅ singleton مشترك
      ref: ref,
    );
  },
);

// ── Notifier ──────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final String _otherUserId;
  final ChatRepository _repository;
  final ChatSignalRService _signalR;
  final Ref _ref;

  ChatNotifier({
    required String otherUserId,
    required ChatRepository repository,
    required ChatSignalRService signalR,
    required Ref ref,
  })  : _otherUserId = otherUserId,
        _repository = repository,
        _signalR = signalR,
        _ref = ref,
        super(const ChatState());

  Future<void> initialize() async {
    state = state.copyWith(isLoadingHistory: true, clearError: true);
    try {
      await Future.wait([_connectSignalR(), _loadPage(1)]);
      
      // Process initial messages to set unread counts
      final currentUserId = _ref.read(authStateProvider).userId ?? '';
      _ref.read(unreadMessagesProvider.notifier).processMessages(
        state.messages,
        currentUserId,
      );
      
      await _repository.markAsSeen(otherUserId: _otherUserId);
      _markLocalMessagesAsSeen();
      
      // Mark messages as read since we just opened the chat
      _ref.read(unreadMessagesProvider.notifier).markAsRead(_otherUserId);
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> _loadPage(int page) async {
    final newMessages = await _repository.getChatHistory(
      otherUserId: _otherUserId,
      pageNumber: page,
      pageSize: state.pagination.pageSize,
    );

    final hasMore = newMessages.length >= state.pagination.pageSize;

    if (page == 1) {
      state = state.copyWith(
        messages: newMessages,
        isLoadingHistory: false,
        pagination: state.pagination.copyWith(
          currentPage: 1,
          hasMore: hasMore,
        ),
      );
    } else {
      state = state.copyWith(
        messages: [...newMessages, ...state.messages],
        isLoadingMore: false,
        pagination: state.pagination.copyWith(
          currentPage: page,
          hasMore: hasMore,
        ),
      );
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.pagination.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      await _loadPage(state.pagination.currentPage + 1);
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> sendMessage({required String content}) async {
    if (content.trim().isEmpty) return;

    final currentUserId = _ref.read(authStateProvider).userId ?? '';

    // ✅ أضف الرسالة في الـ UI فوراً قبل ما السيرفر يرد
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessageModel(
      id: tempId,
      senderId: currentUserId,
      receiverId: _otherUserId,
      content: content.trim(),
      timestamp: DateTime.now(),
      isSeen: false,
    );

    state = state.copyWith(
      messages: [...state.messages, tempMessage],
      isSending: true,
      clearError: true,
    );

    try {
      if (!_signalR.isConnected) {
        await _connectSignalR();
      }

      await _signalR.sendMessage(
        receiverId: _otherUserId,
        content: content.trim(),
      );

      if (mounted) state = state.copyWith(isSending: false);
    } catch (e) {
      // ✅ لو فشل — شيل الرسالة المؤقتة
      if (mounted) {
        final withoutTemp =
            state.messages.where((m) => m.id != tempId).toList();
        state = state.copyWith(
          messages: withoutTemp,
          isSending: false,
          error: 'Failed to send message. Try again.',
        );
      }
    }
  }

  Future<void> sendTypingIndicator() async {
    await _signalR.sendTyping(receiverId: _otherUserId);
  }

  Future<void> _connectSignalR() async {
    _signalR.onMessageReceived = _handleIncomingMessage;
    _signalR.onMessageSent = _handleMessageSent;
    _signalR.onConnected = () => state = state.copyWith(isConnected: true);
    _signalR.onDisconnected = () => state = state.copyWith(isConnected: false);

    await _signalR.connect();
    state = state.copyWith(isConnected: _signalR.isConnected);
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    if (message.senderId != _otherUserId) return;
    if (state.messages.any((m) => m.id == message.id)) return;

    state = state.copyWith(
      messages: [...state.messages, message],
    );

    // Unread count is now handled in SignalR service to avoid double counting
    // _repository.markAsSeen(otherUserId: _otherUserId);
    // _markLocalMessagesAsSeen();
  }

  void _handleMessageSent(ChatMessageModel message) {
    // ✅ استبدل الـ temp message بالـ real message من السيرفر
    final hasTempMessage = state.messages.any((m) => m.id.startsWith('temp_'));

    if (hasTempMessage) {
      // استبدل أول temp message بالرسالة الحقيقية
      final updated = state.messages.map((m) {
        if (m.id.startsWith('temp_')) return message;
        return m;
      }).toList();
      state = state.copyWith(messages: updated);
      return;
    }

    // لو مفيش temp — تأكد مفيش duplicate
    if (state.messages.any((m) => m.id == message.id)) return;
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  void _markLocalMessagesAsSeen() {
    final currentUserId = _ref.read(authStateProvider).userId ?? '';
    final updated = state.messages.map((m) {
      if (m.senderId != currentUserId && !m.isSeen) {
        return m.copyWith(isSeen: true);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  @override
  void dispose() {
    // ✅ مسح الـ callbacks بس — مش قطع الـ connection
    // الـ connection بتتقطع في logout بس
    _signalR.onMessageReceived = null;
    _signalR.onMessageSent = null;
    _signalR.onConnected = null;
    _signalR.onDisconnected = null;
    super.dispose();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet connection.';
    }
    return msg.replaceAll('Exception: ', '');
  }
}
