import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../../../core/shared/routes/app_pages.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  // Exact Brand Gradient & Accent Colors from mobile_vms
  static const Color _blue = Color(0xFF1976D2);
  static const Color _blueDark = Color(0xFF0E5DB5);
  static const Color _textColorDark = Color(0xFF1E293B);
  static const Color _textColorMuted = Color(0xFF64748B);
  static const Color _fieldFillColor = Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sw = size.width;
    final sh = size.height;
    final minDim = size.shortestSide;
    final isLandscapeTablet = sw >= 720;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _blue,
      body: Stack(
        children: [
          // 1. Blue Header Background Gradient (Identical to mobile_vms)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_blue, _blueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. Decorative Circles (Depth effect identical to mobile_vms)
          Positioned(
            top: -minDim * 0.25,
            right: -minDim * 0.15,
            child: Container(
              width: minDim * 0.65,
              height: minDim * 0.65,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: isLandscapeTablet ? -minDim * 0.2 : sh * 0.50,
            left: -minDim * 0.2,
            child: Container(
              width: minDim * 0.55,
              height: minDim * 0.55,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 3. Responsive Main Content Layout
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isLandscapeTablet) {
                  // Tablet / Desktop Dual-Pane Layout with mobile_vms Design Aesthetics
                  return Row(
                    children: [
                      // Left Pane: Hero Branding
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48.0,
                            vertical: 24.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo Circle
                              SizedBox(
                                width: (minDim * 0.25).clamp(80.0, 140.0),
                                height: (minDim * 0.25).clamp(80.0, 140.0),
                                child: Image.asset(
                                  'assets/images/VMS.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.admin_panel_settings_rounded,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'VISITOR MANAGEMENT SYSTEM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (minDim * 0.042).clamp(20.0, 32.0),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Smart Visitor Experience & Integrated Security Control.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: (minDim * 0.026).clamp(13.0, 17.0),
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Pane: White Content Card
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 460),
                            margin: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(36.0),
                              child: _buildLoginForm(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile Portrait Stack Layout (Exact Mobile VMS Structure)
                  final heroHeight = constraints.maxHeight * 0.35;
                  return Column(
                    children: [
                      // Hero Content Top
                      SizedBox(
                        height: heroHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: minDim * 0.28,
                              height: minDim * 0.28,
                              child: Image.asset(
                                'assets/images/VMS.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Text(
                                  'VISITOR MANAGEMENT SYSTEM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: (minDim * 0.05).clamp(18.0, 24.0),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Smart Visitor Experience',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // White Content Card Bottom
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 32,
                            ),
                            child: _buildLoginForm(context),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome Header
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _textColorDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Please login to continue',
          style: TextStyle(fontSize: 14, color: _textColorMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Username Field
        _buildInputFieldLabel('Username'),
        const SizedBox(height: 8),
        TextField(
          controller: controller.usernameController,
          style: const TextStyle(color: _textColorDark, fontSize: 15),
          decoration: _buildInputDecoration(
            hintText: 'Enter your username',
            prefixIcon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 20),

        // Password Field
        _buildInputFieldLabel('Password'),
        const SizedBox(height: 8),
        Obx(
          () => TextField(
            controller: controller.passwordController,
            obscureText: controller.rxIsObscurePassword.value,
            style: const TextStyle(color: _textColorDark, fontSize: 15),
            decoration: _buildInputDecoration(
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () => controller.rxIsObscurePassword.toggle(),
                icon: Icon(
                  controller.rxIsObscurePassword.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _textColorMuted,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Remember Me & Additional Options Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Obx(
                  () => Checkbox(
                    value: controller.rxRememberMe.value,
                    onChanged: (val) =>
                        controller.rxRememberMe.value = val ?? false,
                    activeColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text(
                  'Remember Me',
                  style: TextStyle(
                    color: _textColorDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Primary Login Button
        Obx(() {
          if (controller.rxIsLoadingLogin.value) {
            return const Center(child: CircularProgressIndicator(color: _blue));
          }
          return _buildPrimaryGradientButton(
            label: 'Login',
            onPressed: () => controller.login(),
          );
        }),

        const SizedBox(height: 20),

        // Separator Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),

        const SizedBox(height: 20),

        // Tapping Card Action Button (Operator Tablet Kiosk Aesthetic)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.cardTap),
            borderRadius: BorderRadius.circular(16),
            splashColor: _blue.withValues(alpha: 0.1),
            highlightColor: _blue.withValues(alpha: 0.05),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _blue.withValues(alpha: 0.22),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _blue.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Glowing Contactless Icon Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _blue.withValues(alpha: 0.14),
                          _blueDark.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _blue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.contactless_rounded,
                      color: _blue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title, Tech Chip, Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tapping Access Card',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textColorDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tap card on terminal reader',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Circular Action Arrow Button
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _blue,
                      size: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textColorDark,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _textColorMuted, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: _blue, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _fieldFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }

  Widget _buildPrimaryGradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_blue, _blueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
