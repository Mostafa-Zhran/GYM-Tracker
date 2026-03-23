import 'dart:async';
import 'package:flutter/material.dart';

/// Message input bar at the bottom of the chat screen.
/// Emits [onTyping] with debounce so we don't spam the SignalR hub.
class MessageInput extends StatefulWidget {
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onTyping;

  const MessageInput({
    super.key,
    required this.isSending,
    required this.onSend,
    required this.onTyping,
  });

  /// External access to the text value so [ChatScreen] can read it.
  static final controller = TextEditingController();

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = MessageInput.controller;
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isFocused = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Throttle typing events — fire at most once every 2 seconds
    if (hasText) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        widget.onTyping();
      });
      widget.onTyping(); // fire immediately on first keystroke
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border(
          top: BorderSide(color: const Color(0xFF1F2937), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Text Field ──────────────────────────────────────────────
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFocused
                        ? const Color(0xFFFF6B35).withOpacity(0.65)
                        : const Color(0xFF1F2937),
                    width: _isFocused ? 1.5 : 1,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.07),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  cursorColor: const Color(0xFFFF6B35),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF374151), fontSize: 14),
                    prefixIcon: Padding(
                      padding:
                          const EdgeInsets.only(left: 12, right: 8, bottom: 2),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: _isFocused
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFF4B5563),
                        size: 18,
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Send Button ──────────────────────────────────────────────
            widget.isSending
                ? Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.25)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  )
                : _SendButton(
                    enabled: _hasText,
                    onTap: _handleSend,
                  ),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    if (!_hasText || widget.isSending) return;
    widget.onSend();
  }
}

// ── Send Button ───────────────────────────────────────────────────────────

class _SendButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _SendButton({required this.enabled, required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => _ctrl.forward() : null,
        onTapUp: widget.enabled
            ? (_) {
                _ctrl.reverse();
                widget.onTap();
              }
            : null,
        onTapCancel: widget.enabled ? () => _ctrl.reverse() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
                  )
                : null,
            color: widget.enabled ? null : const Color(0xFF1C2333),
            borderRadius: BorderRadius.circular(13),
            border: widget.enabled
                ? null
                : Border.all(color: const Color(0xFF1F2937)),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            Icons.send_rounded,
            color: widget.enabled ? Colors.white : const Color(0xFF374151),
            size: 18,
          ),
        ),
      ),
    );
  }
}
