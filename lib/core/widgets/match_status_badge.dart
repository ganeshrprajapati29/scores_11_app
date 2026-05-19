import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MatchStatusBadge extends StatelessWidget {
  final String status;
  final bool isLive;
  final EdgeInsets padding;

  const MatchStatusBadge({
    super.key,
    required this.status,
    this.isLive = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData? icon;
    
    switch (status.toUpperCase()) {
      case 'LIVE':
        bgColor = AppColors.live;
        textColor = Colors.white;
        icon = Icons.circle;
        break;
      case 'COMPLETED':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'SCHEDULED':
      case 'UPCOMING':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.schedule;
        break;
      default:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.schedule;
        break;
    }
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          if (isLive) ...[
            SizedBox(
              width: 6,
              height: 6,
              child: CustomPaint(
                painter: _LiveDotPainter(),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _getDisplayText(status),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDisplayText(String status) {
    switch (status.toUpperCase()) {
      case 'LIVE':
        return 'LIVE';
      case 'COMPLETED':
        return 'Completed';
      case 'SCHEDULED':
      case 'UPCOMING':
        return 'Upcoming';
      default:
        return status;
    }
  }
}

class _LiveDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

