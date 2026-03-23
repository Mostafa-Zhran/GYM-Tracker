import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Gym/core/navigation/app_router.dart';
import 'package:Gym/features/auth/providers/auth_provider.dart';
import 'package:Gym/features/chat/providers/chat_provider.dart';
import 'package:Gym/features/chat/providers/chat_typing_provider.dart';
import 'package:Gym/features/chat/widgets/chat_list_view.dart';
import 'package:Gym/features/chat/widgets/message_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatArgs args;
  const ChatScreen({super.key, required this.args});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();

  // ── Entrance animations ───────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Entrance animations
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();

    // Initialize chat after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider(widget.args.otherUserId).notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    MessageInput.controller.clear();
    super.dispose();
  }

  // ── Auto-scroll to bottom ─────────────────────────────────────────────────

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final content = MessageInput.controller.text.trim();
    if (content.isEmpty) return;

    MessageInput.controller.clear();

    await ref
        .read(chatProvider(widget.args.otherUserId).notifier)
        .sendMessage(content: content);

    if (!mounted) return;

    _scrollToBottom();
  }

  // ── Emit typing ───────────────────────────────────────────────────────────

  void _onTyping() {
    ref
        .read(chatProvider(widget.args.otherUserId).notifier)
        .sendTypingIndicator();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.args.otherUserId));
    final typingState = ref.watch(chatTypingProvider(widget.args.otherUserId));
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.userId ?? '';
    final size = MediaQuery.of(context).size;

    // Auto-scroll when a new message arrives
    ref.listen(chatProvider(widget.args.otherUserId), (prev, next) {
      if (prev != null && next.messages.length > prev.messages.length) {
        // Only auto-scroll if we're near the bottom already
        if (_scrollController.hasClients) {
          final pos = _scrollController.position;
          final nearBottom = pos.maxScrollExtent - pos.pixels < 200;
          if (nearBottom || next.messages.last.senderId == currentUserId) {
            _scrollToBottom();
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Background (identical to all screens) ─────────────────
          _BackgroundDecoration(size: size),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // ── Top Bar ────────────────────────────────────
                    _ChatTopBar(
                      otherUserName: widget.args.otherUserName,
                      isConnected: chatState.isConnected,
                      onBack: () => context.pop(),
                    ),

                    // ── Error Banner ───────────────────────────────
                    if (chatState.error != null)
                      _ErrorBanner(message: chatState.error!),

                    // ── Messages ───────────────────────────────────
                    Expanded(
                      child: chatState.isLoadingHistory
                          ? const _LoadingState()
                          : chatState.messages.isEmpty
                              ? const _EmptyState()
                              : ChatListView(
                                  messages: chatState.messages,
                                  currentUserId: currentUserId,
                                  isLoadingMore: chatState.isLoadingMore,
                                  isTyping: typingState.isOtherUserTyping,
                                  otherUserName: widget.args.otherUserName,
                                  scrollController: _scrollController,
                                  onLoadMore: () => ref
                                      .read(
                                          chatProvider(widget.args.otherUserId)
                                              .notifier)
                                      .loadMoreMessages(),
                                ),
                    ),

                    // ── Input Bar ──────────────────────────────────
                    MessageInput(
                      isSending: chatState.isSending,
                      onSend: _sendMessage,
                      onTyping: _onTyping,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background (identical to all screens) ─────────────────────────────────

class _BackgroundDecoration extends StatelessWidget {
  final Size size;
  const _BackgroundDecoration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFFF6B35).withOpacity(0.13),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF3B82F6).withOpacity(0.09),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        CustomPaint(size: size, painter: _GridPainter()),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Chat Top Bar ──────────────────────────────────────────────────────────

class _ChatTopBar extends StatelessWidget {
  final String otherUserName;
  final bool isConnected;
  final VoidCallback onBack;

  const _ChatTopBar({
    required this.otherUserName,
    required this.isConnected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF1F2937)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF9CA3AF), size: 14),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar with initial
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + connection status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFFF6B35),
                        boxShadow: isConnected
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isConnected ? 'Online' : 'Connecting...',
                      style: TextStyle(
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFFF6B35),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Gym logo badge
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Loading State ─────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading messages...',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF374151), size: 32),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Color(0xFFAAAAAA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(b),
            child: const Text(
              'NO MESSAGES YET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Say hello and start the conversation! 👋',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
