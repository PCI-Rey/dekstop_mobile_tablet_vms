import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  static const Duration _animationDuration = Duration(milliseconds: 1200);

  // Exact Brand Gradient Colors from mobile_vms
  static const Color _blue = Color(0xFF1976D2);
  static const Color _blueDark = Color(0xFF0E5DB5);

  @override
  void initState() {
    super.initState();
    _initializeAnimation();

    // Trigger splash authentication and configuration check flow logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().runSplashFlow();
      }
    });
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sw = size.width;
    // Responsive scaling based on shortestSide for optimal tablet & mobile layout
    final minDim = size.shortestSide;

    // Responsive element dimensions
    final logoSize = (minDim * 0.28).clamp(90.0, 160.0);
    final titleFontSize = (minDim * 0.048).clamp(18.0, 30.0);
    final taglineFontSize = (minDim * 0.030).clamp(12.0, 16.0);
    final messageFontSize = (minDim * 0.026).clamp(11.0, 15.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradient background — identical brand gradient to mobile_vms
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_blue, _blueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative circle top-right (depth effect) ──────────────
            Positioned(
              top: -minDim * 0.35,
              right: -minDim * 0.25,
              child: Container(
                width: minDim * 0.9,
                height: minDim * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // ── Decorative circle bottom-left (depth effect) ─────────────
            Positioned(
              bottom: -minDim * 0.3,
              left: -minDim * 0.2,
              child: Container(
                width: minDim * 0.8,
                height: minDim * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // ── Center content (Logo, App Name, Tagline, Loader) ─────────
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // VMS Brand Logo Circle / Image
                          SizedBox(
                            width: logoSize,
                            height: logoSize,
                            child: Image.asset(
                              'assets/images/VMS.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: logoSize * 0.55,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: minDim * 0.05),

                          // App Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'VISITOR MANAGEMENT SYSTEM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle / Tagline
                          Text(
                            'Smart Visitor Experience',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: taglineFontSize,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),

                          SizedBox(height: minDim * 0.08),

                          // Reactive Loading State Message from AuthController
                          if (Get.isRegistered<AuthController>())
                            Obx(() {
                              final authCtrl = Get.find<AuthController>();
                              return Text(
                                authCtrl.rxSplashMessage.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: messageFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }),

                          const SizedBox(height: 14),

                          // Modern subtle progress bar
                          SizedBox(
                            width: math.min(sw * 0.25, 200.0).clamp(120.0, 220.0),
                            height: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Version & Powered By Footer ───────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) => Opacity(
                  opacity: _opacityAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '© 2026 VMS. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: (minDim * 0.024).clamp(10.0, 13.0),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Powered by ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: (minDim * 0.024).clamp(10.0, 13.0),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-4, 0),
                            child: Image.asset(
                              'assets/images/BioExperienceWhite.png',
                              height: (minDim * 0.04).clamp(16.0, 24.0),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Text(
                                'Bio Experience',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: (minDim * 0.024).clamp(10.0, 13.0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
