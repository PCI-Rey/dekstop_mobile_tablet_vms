import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CaptchaBoxWidget extends StatefulWidget {
  final String captchaCode;
  final String? captchaSvg;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final TextEditingController controller;
  final String? errorText;

  const CaptchaBoxWidget({
    super.key,
    required this.captchaCode,
    this.captchaSvg,
    required this.isRefreshing,
    required this.onRefresh,
    required this.controller,
    this.errorText,
  });

  @override
  State<CaptchaBoxWidget> createState() => _CaptchaBoxWidgetState();
}

class _CaptchaBoxWidgetState extends State<CaptchaBoxWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  static const Color _blue = Color(0xFF1976D2);
  static const Color _textColorDark = Color(0xFF1E293B);
  static const Color _textColorMuted = Color(0xFF64748B);
  static const Color _fieldFillColor = Color(0xFFF4F7FB);

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant CaptchaBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _spinController.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _spinController.stop();
      _spinController.reset();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _handleRefreshTap() {
    _spinController.forward(from: 0.0);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    const characterColors = [
      Color(0xFF0F2B48), // Deep Navy
      Color(0xFF1976D2), // BI Blue
      Color(0xFF0284C7), // Cerulean
      Color(0xFF1E293B), // Slate Dark
      Color(0xFF0369A1), // Ocean Blue
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Label
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'CAPTCHA',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _textColorDark,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // 2. Row: Captcha Image Container + Refresh Button
        Row(
          children: [
            // Captcha Box Display
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      if (widget.isRefreshing)
                        const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _blue,
                            ),
                          ),
                        )
                      else ...[
                        // 1. Background layer: SVG vector background from backend or noise painter
                        if (widget.captchaSvg != null &&
                            widget.captchaSvg!.isNotEmpty)
                          Positioned.fill(
                            child: SvgPicture.string(
                              widget.captchaSvg!,
                              fit: BoxFit.fill,
                            ),
                          )
                        else
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _CaptchaNoisePainter(
                                seed: widget.captchaCode.hashCode,
                              ),
                            ),
                          ),

                        // Overlay light noise distortion to match bank security standard
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CaptchaNoisePainter(
                              seed: widget.captchaCode.hashCode,
                            ),
                          ),
                        ),

                        // 2. Character layer: Native high-DPI text renderer with slight tilt & colors
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              widget.captchaCode.length,
                              (index) {
                                final char = widget.captchaCode[index];
                                final color = characterColors[
                                    index % characterColors.length];
                                final angle = math.sin(
                                        (widget.captchaCode.hashCode + index) *
                                            1.7) *
                                    0.16;

                                return Transform.rotate(
                                  angle: angle,
                                  child: Text(
                                    char,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                      letterSpacing: 2.0,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Animated Refresh Button
            Tooltip(
              message: 'Refresh Captcha',
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.isRefreshing ? null : _handleRefreshTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _spinController.value * 2 * math.pi,
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: _blue,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 3. Captcha Input Field
        TextField(
          controller: widget.controller,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: _textColorDark,
          ),
          decoration: InputDecoration(
            hintText: 'Enter the code above',
            hintStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.normal,
              color: _textColorMuted,
              letterSpacing: 0.0,
            ),
            prefixIcon: const Icon(
              Icons.shield_outlined,
              color: _blue,
              size: 20,
            ),
            filled: true,
            fillColor: _fieldFillColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            errorText: widget.errorText,
            errorStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _blue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter to generate realistic captcha background noise & scratch lines
class _CaptchaNoisePainter extends CustomPainter {
  final int seed;

  _CaptchaNoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);

    // 1. Draw subtle background wavy lines
    final linePaint = Paint()
      ..color = const Color(0xFF1976D2).withValues(alpha: 0.22)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    path1.moveTo(0, size.height * (0.35 + random.nextDouble() * 0.3));
    path1.quadraticBezierTo(
      size.width * 0.35,
      size.height * (0.1 + random.nextDouble() * 0.7),
      size.width * 0.7,
      size.height * (0.2 + random.nextDouble() * 0.6),
    );
    path1.quadraticBezierTo(
      size.width * 0.85,
      size.height * (0.3 + random.nextDouble() * 0.5),
      size.width,
      size.height * (0.25 + random.nextDouble() * 0.5),
    );
    canvas.drawPath(path1, linePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * (0.65 + random.nextDouble() * 0.2));
    path2.cubicTo(
      size.width * 0.25,
      size.height * (0.7 + random.nextDouble() * 0.25),
      size.width * 0.6,
      size.height * (0.15 + random.nextDouble() * 0.4),
      size.width,
      size.height * (0.45 + random.nextDouble() * 0.4),
    );
    linePaint.color = const Color(0xFF64748B).withValues(alpha: 0.18);
    canvas.drawPath(path2, linePaint);

    // 2. Draw subtle security dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 35; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 0.8 + random.nextDouble() * 1.5;
      final alpha = 0.12 + random.nextDouble() * 0.18;

      dotPaint.color = (i % 2 == 0)
          ? const Color(0xFF1976D2).withValues(alpha: alpha)
          : const Color(0xFF475569).withValues(alpha: alpha);

      canvas.drawCircle(Offset(dx, dy), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CaptchaNoisePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}

