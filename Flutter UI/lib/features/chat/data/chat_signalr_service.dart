import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Gym/core/constants/app_constants.dart';
import 'package:Gym/core/network/dio_client.dart';
import 'package:Gym/features/chat/models/chat_message_model.dart';
import 'package:Gym/features/chat/providers/unread_messages_provider.dart';
import 'package:signalr_netcore/signalr_client.dart';

final chatSignalRServiceProvider = Provider<ChatSignalRService>((ref) {
  final storage = ref.read(secureStorageProvider);
  final service = ChatSignalRService(storage: storage, ref: ref);

  // ✅ disconnect أوتوماتيك لما الـ provider يتمسح
  ref.onDispose(() {
    service.disconnect();
  });

  return service;
});

class ChatSignalRService {
  final FlutterSecureStorage _storage;
  final Ref _ref;
  HubConnection? _hubConnection;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  void Function(ChatMessageModel message)? onMessageReceived;
  void Function(ChatMessageModel message)? onMessageSent;
  void Function(String senderId)? onUserTyping;
  void Function()? onConnected;
  void Function()? onDisconnected;

  ChatSignalRService({required FlutterSecureStorage storage, required Ref ref})
      : _storage = storage,
        _ref = ref;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  // ── Connect ───────────────────────────────────────────────────────────────

  Future<void> connect() async {
    if (_hubConnection != null) {
      await disconnect();
    }

    final token = await _storage.read(key: AppConstants.tokenKey);

    _hubConnection = HubConnectionBuilder()
        .withUrl(
      AppConstants.signalRHubUrl,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token ?? '', // ✅ كفاية ده بس
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
        // ✅ شيل headers خالص
      ),
    )
        .withAutomaticReconnect(
      retryDelays: [0, 2000, 5000, 10000, 30000],
    ).build();

    // ... باقي الكود زي ما هو

    // ── ReceiveMessage ────────────────────────────────────────────────────

    _hubConnection!.on('ReceiveMessage', (arguments) {
      try {
        if (arguments == null || arguments.isEmpty) return;
        final raw = Map<String, dynamic>.from(arguments.first as Map);
        final message = ChatMessageModel.fromJson(raw);
        
        // Increment unread count for incoming unseen messages
        if (!message.isSeen) {
          _ref.read(unreadMessagesProvider.notifier).incrementUnread(message.senderId);
        }
        
        onMessageReceived?.call(message);
      } catch (e) {
        print('ReceiveMessage parse error: $e');
      }
    });

    // ── MessageSent ───────────────────────────────────────────────────────

    _hubConnection!.on('MessageSent', (arguments) {
      try {
        if (arguments == null || arguments.isEmpty) return;
        final raw = Map<String, dynamic>.from(arguments.first as Map);
        onMessageSent?.call(ChatMessageModel.fromJson(raw));
      } catch (e) {
        print('MessageSent parse error: $e');
      }
    });

    // ── UserTyping ────────────────────────────────────────────────────────

    _hubConnection!.on('UserTyping', (arguments) {
      try {
        if (arguments == null || arguments.isEmpty) return;
        onUserTyping?.call(arguments.first.toString());
      } catch (e) {
        print('Typing parse error: $e');
      }
    });

    // ── Connection events ─────────────────────────────────────────────────

    _hubConnection!.onclose(({Exception? error}) {
      print('SignalR disconnected');
      onDisconnected?.call();
    });

    _hubConnection!.onreconnected(({String? connectionId}) {
      print('SignalR reconnected');
      onConnected?.call();
    });

    try {
      await _hubConnection!.start();
      print('SignalR connected');
      onConnected?.call();
    } catch (e) {
      print('SignalR connection error: $e');
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
    } catch (_) {}

    _hubConnection = null;

    // ✅ امسح كل الـ callbacks عشان مفيش memory leak أو غلطة في السيشن الجديدة
    onMessageReceived = null;
    onMessageSent = null;
    onUserTyping = null;
    onConnected = null;
    onDisconnected = null;

    print('SignalR disconnected and callbacks cleared');
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    if (!isConnected) {
      throw Exception('SignalR not connected');
    }
    try {
      await _hubConnection!.invoke(
        'SendMessage',
        args: <Object>[receiverId, content],
      );
    } catch (e) {
      print('SendMessage error: $e');
      rethrow;
    }
  }

  // ── Typing ────────────────────────────────────────────────────────────────

  Future<void> sendTyping({required String receiverId}) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke(
        'Typing',
        args: <Object>[receiverId],
      );
    } catch (_) {}
  }
}
