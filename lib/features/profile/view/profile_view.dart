import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../core/config/constants.dart';
import '../../../core/shared/routes/app_pages.dart';

class ProfileView extends GetView<AuthController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Simulated user details
    const userName = 'Operator Utama VMS';
    const userEmail = 'operator@vms.com';
    const userRole = 'Super Admin Operator';
    const userDept = 'Security & Facility Control';
    const deviceName = 'VMS Terminal Windows (Hybrid)';
    final appVersionStr = 'v${AppConstants.appVersion} (${AppConstants.buildNumber})';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 1. Avatar Name Card
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.primary, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/300?img=11'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userRole,
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Personal Information details
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.mail_outline, 'Email Address', userEmail, colorScheme),
                        const Divider(),
                        _buildInfoRow(Icons.domain, 'Department', userDept, colorScheme),
                        const Divider(),
                        _buildInfoRow(Icons.devices, 'Device Platform', deviceName, colorScheme),
                        const Divider(),
                        _buildInfoRow(Icons.info_outline, 'VMS App Version', appVersionStr, colorScheme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Settings Menus
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
                        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.settings_outlined, color: colorScheme.primary),
                        title: const Text('System Configurations', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(AppRoutes.configure),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.help_outline_rounded, color: colorScheme.primary),
                        title: const Text('About VMS System', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(AppRoutes.configure), // Goes to config about tab
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: Colors.red),
                        title: const Text('Logout Session', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => controller.logout(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  // --- Show password change form dialog ---
  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Old Password', prefixIcon: Icon(Icons.lock_open)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_outline)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                Get.snackbar('Error', 'Sandi baru tidak cocok.', backgroundColor: Colors.redAccent, colorText: Colors.white);
                return;
              }
              Get.back();
              Get.snackbar('Success', 'Kata sandi berhasil diubah.', backgroundColor: Colors.green, colorText: Colors.white);
            },
            child: const Text('Update'),
          ),
        ],
      )
    );
  }
}
