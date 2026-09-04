import 'package:flutter/material.dart';
import '../core/design_system.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance Official Logo
/// Stylized verification shield with document & checkmark motif
/// Compliant with government service visual guidelines (no unofficial Ashoka emblem)
/// ─────────────────────────────────────────────────────────────────────────────

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isLightOnDark;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 48.0,
    this.showText = false,
    this.isLightOnDark = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final emblem = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Shield Background
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isLightOnDark ? Colors.white : AppColors.primaryNavy,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isLightOnDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : AppColors.primaryNavy.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          // Shield & Document Vector
          CustomPaint(
            size: Size(size * 0.65, size * 0.65),
            painter: _ShieldCheckPainter(
              color: isLightOnDark ? AppColors.primaryNavy : Colors.white,
              accentColor: AppColors.saffron,
            ),
          ),
        ],
      ),
    );

    if (!showText) return emblem;

    final titleColor = isLightOnDark ? Colors.white : AppColors.primaryNavy;
    final subColor = isLightOnDark
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        SizedBox(width: size * 0.25),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GeM',
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w900,
                      color: AppColors.saffron,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Compliance',
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Text(
                subtitle ?? 'AI-Powered Tender Compliance Verification',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: (size * 0.22).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w500,
                  color: subColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShieldCheckPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  _ShieldCheckPainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer Shield contour
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, h * 0.08);
    shieldPath.lineTo(w * 0.88, h * 0.24);
    shieldPath.cubicTo(
      w * 0.88,
      h * 0.62,
      w * 0.58,
      h * 0.86,
      w * 0.5,
      h * 0.94,
    );
    shieldPath.cubicTo(
      w * 0.42,
      h * 0.86,
      w * 0.12,
      h * 0.62,
      w * 0.12,
      h * 0.24,
    );
    shieldPath.close();
    canvas.drawPath(shieldPath, paint);

    // Inner Checkmark
    final checkPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path();
    checkPath.moveTo(w * 0.32, h * 0.50);
    checkPath.lineTo(w * 0.46, h * 0.65);
    checkPath.lineTo(w * 0.70, h * 0.36);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldCheckPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}
