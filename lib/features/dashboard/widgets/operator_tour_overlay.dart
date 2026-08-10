import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines a single step in the Guided Tour Walkthrough
class TourStep {
  final String description;
  final GlobalKey targetKey;
  final bool arrowOnTop; // true: bubble below target (arrow points UP), false: bubble above target (arrow points DOWN)
  final double bubbleWidth;
  final double extraHorizontalOffset;
  final double extraVerticalOffset;

  const TourStep({
    required this.description,
    required this.targetKey,
    this.arrowOnTop = true,
    this.bubbleWidth = 320,
    this.extraHorizontalOffset = 0,
    this.extraVerticalOffset = 0,
  });
}

class OperatorTourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final int initialStep;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const OperatorTourOverlay({
    super.key,
    required this.steps,
    this.initialStep = 0,
    required this.onFinish,
    required this.onSkip,
  });

  @override
  State<OperatorTourOverlay> createState() => _OperatorTourOverlayState();
}

class _OperatorTourOverlayState extends State<OperatorTourOverlay>
    with SingleTickerProviderStateMixin {
  late int _currentStepIndex;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _currentStepIndex = widget.initialStep;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTargetRect(animate: false);
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateTargetRect({bool animate = true}) {
    if (_currentStepIndex >= widget.steps.length) return;

    final step = widget.steps[_currentStepIndex];
    final context = step.targetKey.currentContext;

    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final rect = position & renderBox.size;

        setState(() {
          _targetRect = rect;
        });
      }
    }
  }

  void _goToNext() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTargetRect(animate: true);
      });
    } else {
      widget.onFinish();
    }
  }

  void _goToBack() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTargetRect(animate: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStepIndex >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStepIndex];
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── 1. Dimmed Backdrop with Spotlight Cutout ──────────────────────
        CustomPaint(
          size: screenSize,
          painter: _SpotlightPainter(
            targetRect: _targetRect,
            backdropColor: const Color(0x99000000), // ~60% black
            spotlightPadding: 4.0,
            borderRadius: 12.0,
          ),
        ),

        // ── 2. Tap Blocker ───────────────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Blocks underlying taps during tour
          ),
        ),

        // ── 3. Animated Speech Bubble Popover ─────────────────────────────
        if (_targetRect != null) _buildSpeechBubble(step, screenSize),
      ],
    );
  }

  Widget _buildSpeechBubble(TourStep step, Size screenSize) {
    final rect = _targetRect!;
    final double bubbleWidth = step.bubbleWidth;
    final bool arrowOnTop = step.arrowOnTop;

    // Calculate horizontal bubble position
    double bubbleLeft = rect.center.dx - (bubbleWidth / 2) + step.extraHorizontalOffset;
    // Keep bubble securely inside screen margins
    if (bubbleLeft < 16) bubbleLeft = 16;
    if (bubbleLeft + bubbleWidth > screenSize.width - 16) {
      bubbleLeft = screenSize.width - bubbleWidth - 16;
    }

    // Arrow X position relative to bubble
    final double arrowX = (rect.center.dx - bubbleLeft).clamp(24.0, bubbleWidth - 24.0);

    // Calculate vertical bubble position
    double? bubbleTop;
    double? bubbleBottom;

    if (arrowOnTop) {
      // Bubble is placed BELOW target (Arrow at top of bubble)
      bubbleTop = rect.bottom + 8 + step.extraVerticalOffset;
    } else {
      // Bubble is placed ABOVE target (Arrow at bottom of bubble)
      bubbleBottom = (screenSize.height - rect.top) + 8 + step.extraVerticalOffset;
    }

    final bool isLast = _currentStepIndex == widget.steps.length - 1;
    final int stepNumber = _currentStepIndex + 1;
    final int totalSteps = widget.steps.length;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      left: bubbleLeft,
      top: bubbleTop,
      bottom: bubbleBottom,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox(
          width: bubbleWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Arrow (if bubble is below target)
              if (arrowOnTop)
                Padding(
                  padding: EdgeInsets.only(left: arrowX - 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: _TrianglePainter(isPointingUp: true),
                    ),
                  ),
                ),

              // Bubble Card Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Close Button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: widget.onSkip,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    // Description text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        step.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action Buttons Row: Skip | Back | Next (X of 10) / Done
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Skip Button (left - always accessible)
                        GestureDetector(
                          onTap: widget.onSkip,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),

                        // Back & Next / Done Buttons (right)
                        Row(
                          children: [
                            if (_currentStepIndex > 0) ...[
                              GestureDetector(
                                onTap: _goToBack,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Text(
                                    'Back',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],

                            // Next / Done Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _goToNext,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isLast ? 'Done' : 'Next ($stepNumber of $totalSteps)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Arrow (if bubble is above target)
              if (!arrowOnTop)
                Padding(
                  padding: EdgeInsets.only(left: arrowX - 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: _TrianglePainter(isPointingUp: false),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter that creates the Spotlight Cutout hole over the target widget
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color backdropColor;
  final double spotlightPadding;
  final double borderRadius;

  _SpotlightPainter({
    required this.targetRect,
    required this.backdropColor,
    required this.spotlightPadding,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullScreenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final backgroundPaint = Paint()..color = backdropColor;

    if (targetRect == null) {
      canvas.drawRect(fullScreenRect, backgroundPaint);
      return;
    }

    final inflatedRect = targetRect!.inflate(spotlightPadding);
    final roundedRect = RRect.fromRectAndRadius(
      inflatedRect,
      Radius.circular(borderRadius),
    );

    // Cutout Path
    final backgroundPath = Path()..addRect(fullScreenRect);
    final cutoutPath = Path()..addRRect(roundedRect);
    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, backgroundPaint);

    // Glowing subtle border around cutout
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(roundedRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.backdropColor != backdropColor;
  }
}

/// Draws the triangle pointer for the speech bubble
class _TrianglePainter extends CustomPainter {
  final bool isPointingUp;

  _TrianglePainter({required this.isPointingUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isPointingUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => false;
}
