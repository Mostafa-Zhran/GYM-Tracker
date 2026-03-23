import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Gym/features/chat/models/chat_message_model.dart';

/// Renders a single chat message bubble.
/// [isMe] = true  → right-aligned orange gradient bubble
/// [isMe] = false → left-aligned dark bubble
class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
                )
              : null,
          color: isMe ? null : const Color(0xFF1C2333),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFF1F2937)),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ── Message text ─────────────────────────────────────────
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFFE5E7EB),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 5),

            // ── Timestamp + seen status ───────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withOpacity(0.55)
                        : const Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Show seen tick only on MY messages
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _SeenTick(isSeen: message.isSeen),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seen Tick ──────────────────────────────────────────────────────────────

// ── Seen Tick ──────────────────────────────────────────────────────────────

class _SeenTick extends StatelessWidget {
  final bool isSeen;
  const _SeenTick({required this.isSeen});

  @override
  Widget build(BuildContext context) {
    if (isSeen) {
      // ✅ Stack بدل SizedBox بعرض سالب
      return SizedBox(
        width: 18,
        height: 12,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Icon(Icons.done_rounded,
                  size: 11, color: Colors.white.withOpacity(0.9)),
            ),
            Positioned(
              left: 5, // ✅ overlap بالـ Stack
              child: Icon(Icons.done_rounded,
                  size: 11, color: Colors.white.withOpacity(0.9)),
            ),
          ],
        ),
      );
    }

    // ✔ single tick
    return Icon(
      Icons.done_rounded,
      size: 11,
      color: Colors.white.withOpacity(0.5),
    );
  }
}
