import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? badgeColor;
  final double? badgeSize;
  final Offset offset;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor,
    this.badgeSize,
    this.offset = const Offset(0, -4),
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShow = showZero || count > 0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (shouldShow)
          Positioned(
            right: offset.dx,
            top: offset.dy,
            child: _Badge(
              count: count,
              color: badgeColor ?? const Color(0xFFFF6B35),
              size: badgeSize,
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  final double? size;

  const _Badge({
    required this.count,
    required this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99 ? '99+' : count.toString();
    final badgeSize = size ?? (count > 9 ? 20.0 : 18.0);
    final fontSize = count > 9 ? 10.0 : 11.0;

    return Container(
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: count > 9 ? 6.0 : 5.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0A0A0F),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayCount,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
