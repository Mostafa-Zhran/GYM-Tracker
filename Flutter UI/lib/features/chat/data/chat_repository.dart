import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/core/constants/app_constants.dart';
import 'package:Gym/core/network/dio_client.dart';
import 'package:Gym/features/chat/models/chat_message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(dio: ref.read(dioProvider));
});

class ChatRepository {
  final Dio _dio;

  ChatRepository({required Dio dio}) : _dio = dio;

  // ── Fetch paginated chat history ──────────────────────────────────────────

  /// Returns messages sorted oldest → newest (ascending by timestamp).
  /// API returns newest first, so we reverse locally.
  Future<List<ChatMessageModel>> getChatHistory({
    required String otherUserId,
    required int pageNumber,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      AppConstants.chatHistoryEndpoint,
      queryParameters: {
        'otherUserId': otherUserId,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );

    if (response.statusCode == 204 ||
        response.data == null ||
        response.data == '') {
      return [];
    }

    // ✅ Handle both raw array AND wrapped object
    List<dynamic> raw;
    if (response.data is List) {
      raw = response.data as List<dynamic>;
    } else if (response.data is Map) {
      // Try common wrapper keys: "data", "messages", "items"
      final map = response.data as Map<String, dynamic>;
      raw = (map['data'] ?? map['messages'] ?? map['items'] ?? [])
          as List<dynamic>;
    } else {
      return [];
    }

    final messages = raw
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return messages.reversed.toList();
  }

  // ── Mark messages as seen ─────────────────────────────────────────────────

  /// Tells the server all messages from [otherUserId] have been read.
  Future<void> markAsSeen({required String otherUserId}) async {
    await _dio.post(
      AppConstants.chatSeenEndpoint,
      queryParameters: {'otherUserId': otherUserId},
    );
  }
}
