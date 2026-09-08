import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/profile_controller.dart';
import '../../../core/config/constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/shared/widgets/app_snackbar.dart';
import '../../../core/shared/dialogs/server_config_dialog.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _darkBlue = Color(0xFF0E5DB5);
  static const Color _bgSlate = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderSoft = Color(0xFFE2E8F0);
  static const Color _dangerRed = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: _borderSoft)),
              ),
              child: Row(
                children: [
                  // Back Button
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Get.back(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderSoft),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: _textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Operator Profile',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),

            // Main Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Obx(() {
                      final name = controller.fullname;
                      final email = controller.email;
                      final groupName = controller.groupName;
                      final organization = controller.organization;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Hero Profile Header Card (Standard Profile Icon, No External Picture)
                          _buildHeroProfileCard(
                            name: name,
                            groupName: groupName,
                          ),
                          const SizedBox(height: 20),

                          // 2. Operator Details Card (Real API data from /api/profile/me)
                          _buildOperatorDetailsCard(
                            email: email,
                            organization: organization,
                          ),
                          const SizedBox(height: 20),

                          // 3. Preferences & Actions Card
                          _buildActionsCard(context),
                          const SizedBox(height: 32),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Hero Profile Card with Brand Blue Gradient & Standard Profile Icon ---
  Widget _buildHeroProfileCard({
    required String name,
    required String groupName,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, _darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Translucent Depth Circles
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 80,
            bottom: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Row(
              children: [
                // Standard Profile Icon (Clean white ring & person icon)
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(width: 20),

                // Name & Group Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        groupName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDBEAFE),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Operator Details Card ---
  Widget _buildOperatorDetailsCard({
    required String email,
    required String organization,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 15,
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'OPERATOR DETAILS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderSoft),

          // Detail Rows
          _buildDetailItem(
            icon: Icons.mail_outline_rounded,
            label: 'Email Address',
            value: email,
            iconColor: _primaryBlue,
          ),
          const Divider(height: 1, indent: 64, color: _borderSoft),
          _buildDetailItem(
            icon: Icons.business_rounded,
            label: 'Organization',
            value: organization,
            iconColor: const Color(0xFF0F62FE),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Preferences & Action Buttons Card ---
  Widget _buildActionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 15,
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'PREFERENCES & SECURITY',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderSoft),

          // Change Password Tile
          _buildActionTile(
            icon: Icons.lock_reset_rounded,
            iconColor: _primaryBlue,
            title: 'Change Password',
            subtitle: 'Set password required to modify server base URL',
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1, indent: 64, color: _borderSoft),

          // Server Configuration Tile
          _buildActionTile(
            icon: Icons.dns_rounded,
            iconColor: const Color(0xFF0F62FE),
            title: 'Server Configuration',
            subtitle: 'Configure backend server base URL',
            onTap: () => _showServerConfigAuthDialog(context),
          ),
          const Divider(height: 1, indent: 64, color: _borderSoft),

          // About Application Tile
          _buildActionTile(
            icon: Icons.info_outline_rounded,
            iconColor: _primaryBlue,
            title: 'About Application',
            subtitle: 'Application version & system specifications',
            onTap: () => _showAboutAppDialog(context),
          ),
          const Divider(height: 1, indent: 64, color: _borderSoft),

          // // System Configurations Tile
          // _buildActionTile(
          //   icon: Icons.tune_rounded,
          //   iconColor: const Color(0xFF0F62FE),
          //   title: 'System Configurations',
          //   subtitle: 'Manage scanner hardware, printers, and site parameters',
          //   onTap: () => Get.toNamed(AppRoutes.configure),
          // ),
          // const Divider(height: 1, indent: 64, color: _borderSoft),

          // Logout Tile
          _buildActionTile(
            icon: Icons.logout_rounded,
            iconColor: _dangerRed,
            title: 'Logout Session',
            subtitle: 'End your current operator work shift securely',
            isDanger: true,
            onTap: () => _showLogoutConfirmDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDanger ? _dangerRed : _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDanger
                  ? _dangerRed.withValues(alpha: 0.6)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // --- Modern Logout Confirmation Modal ---
  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _dangerRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  size: 28,
                  color: _dangerRed,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout Session',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to end your operator session? You will be redirected to the login screen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _borderSoft),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dangerRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        controller.logout();
                      },
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
    );
  }

  // --- Show password change form dialog ---
  void _showChangePasswordDialog(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => MediaQuery(
        data: MediaQuery.of(dialogContext).copyWith(viewInsets: EdgeInsets.zero),
        child: Dialog(
          backgroundColor: Colors.transparent,
          alignment: const Alignment(0, -0.2),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            width: 440,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height - 32,
            ),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 20,
                          color: _primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Change Password',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: _textMuted,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildPasswordInput(
                    controller: oldPasswordCtrl,
                    label: 'Current Password',
                    hint: 'Enter current password',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordInput(
                    controller: newPasswordCtrl,
                    label: 'New Password',
                    hint: 'Enter new password',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordInput(
                    controller: confirmPasswordCtrl,
                    label: 'Confirm New Password',
                    hint: 'Re-enter your new password',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) async {
                      final oldPwd = oldPasswordCtrl.text.trim();
                      final newPwd = newPasswordCtrl.text.trim();
                      final confirmPwd = confirmPasswordCtrl.text.trim();

                      if (oldPwd.isEmpty ||
                          newPwd.isEmpty ||
                          confirmPwd.isEmpty) {
                        AppSnackbar.warning(
                          title: 'Incomplete Form',
                          message: 'Please fill in all password fields.',
                        );
                        return;
                      }
                      final currentSaved = await storageService
                          .getConfigPassword();
                      if (oldPwd != currentSaved) {
                        AppSnackbar.error(
                          title: 'Incorrect Password',
                          message: 'Current password does not match.',
                        );
                        return;
                      }
                      if (newPwd.length < 4) {
                        AppSnackbar.warning(
                          title: 'Password Too Short',
                          message:
                              'New password must be at least 4 characters.',
                        );
                        return;
                      }
                      if (newPwd != confirmPwd) {
                        AppSnackbar.error(
                          title: 'Password Mismatch',
                          message:
                              'New password and confirmation do not match.',
                        );
                        return;
                      }
                      await storageService.saveConfigPassword(newPwd);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      AppSnackbar.success(
                        title: 'Password Updated',
                        message:
                            'Configuration access password has been updated successfully.',
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _borderSoft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final oldPwd = oldPasswordCtrl.text.trim();
                            final newPwd = newPasswordCtrl.text.trim();
                            final confirmPwd = confirmPasswordCtrl.text.trim();

                            if (oldPwd.isEmpty ||
                                newPwd.isEmpty ||
                                confirmPwd.isEmpty) {
                              AppSnackbar.warning(
                                title: 'Incomplete Form',
                                message: 'Please fill in all password fields.',
                              );
                              return;
                            }
                            final currentSaved = await storageService
                                .getConfigPassword();
                            if (oldPwd != currentSaved) {
                              AppSnackbar.error(
                                title: 'Incorrect Password',
                                message: 'Current password does not match.',
                              );
                              return;
                            }
                            if (newPwd.length < 4) {
                              AppSnackbar.warning(
                                title: 'Password Too Short',
                                message:
                                    'New password must be at least 4 characters.',
                              );
                              return;
                            }
                            if (newPwd != confirmPwd) {
                              AppSnackbar.error(
                                title: 'Password Mismatch',
                                message:
                                    'New password and confirmation do not match.',
                              );
                              return;
                            }
                            await storageService.saveConfigPassword(newPwd);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            AppSnackbar.success(
                              title: 'Password Updated',
                              message:
                                  'Configuration access password has been updated successfully.',
                            );
                          },
                          child: Text(
                            'Update Password',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // --- Password Prompt before opening Server Configuration ---
  void _showServerConfigAuthDialog(BuildContext context) {
    ServerConfigDialog.showAuth(context);
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    bool obscure = true;
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              obscureText: obscure,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: GoogleFonts.inter(fontSize: 13, color: _textDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    setState(() {
                      obscure = !obscure;
                    });
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Show About Application Dialog Popup ---
  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'About Application',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: _textMuted,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Brand Hero Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderSoft),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryBlue, _darkBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.tablet_mac_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Text(
                                  AppConstants.appVersion,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryBlue,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _borderSoft),
                                ),
                                child: Text(
                                  'Android Tablet',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
