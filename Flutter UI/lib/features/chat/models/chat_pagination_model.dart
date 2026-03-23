/// Tracks pagination state for the chat history API.
class ChatPaginationModel {
  final int currentPage;
  final int pageSize;
  final bool hasMore;

  const ChatPaginationModel({
    required this.currentPage,
    required this.pageSize,
    required this.hasMore,
  });

  const ChatPaginationModel.initial()
      : currentPage = 0,
        pageSize = 20,
        hasMore = true;

  ChatPaginationModel copyWith({
    int? currentPage,
    int? pageSize,
    bool? hasMore,
  }) {
    return ChatPaginationModel(
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
