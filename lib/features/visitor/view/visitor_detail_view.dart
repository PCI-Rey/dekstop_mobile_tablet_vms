import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class VisitorDetailView extends StatelessWidget {
  const VisitorDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Obx(() {
        final visitor = controller.rxSelectedVisitor.value;
        if (visitor == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Visitor tidak ditemukan')));
        }

        final isCheckedIn = visitor['status'] == 'Checked In';

        return CustomScrollView(
          slivers: [
            // 1. Sliver AppBar displaying photo
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(visitor['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      visitor['avatar'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.black45),
                    ),
                    // Dark overlay for text readability
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Details Column
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Indicators
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCheckedIn ? Colors.green : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              visitor['status'],
                              style: TextStyle(color: isCheckedIn ? Colors.white : Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (visitor['vip'] == true)
                            _buildBadge('VIP VISITOR', Colors.purple, Colors.purple[50]!),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Basic Information Card
                      _buildHeaderSection('Basic Information'),
                      _buildInfoTile('Full Name', visitor['name'], Icons.person),
                      _buildInfoTile('Company', visitor['company'], Icons.business),
                      _buildInfoTile('Phone Number', visitor['phone'], Icons.phone),
                      _buildInfoTile('Email Address', visitor['email'], Icons.mail),
                      _buildInfoTile('Nationality', visitor['nationality'], Icons.flag),
                      const SizedBox(height: 24),

                      // Quick Action Sheet Triggers
                      _buildHeaderSection('Quick Actions'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionBtn('Check In', Icons.login, Colors.green, () => controller.executeAction('check_in')),
                          _buildActionBtn('Check Out', Icons.logout, Colors.red, () => controller.executeAction('check_out')),
                          _buildActionBtn('Badge', Icons.badge, Colors.blue, () {
                            Get.snackbar('Printer', 'Mencetak badge pengunjung...');
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Visit Details Information
                      _buildHeaderSection('Visit Information'),
                      _buildInfoTile('Host Person', visitor['host'], Icons.person_pin),
                      _buildInfoTile('Department', visitor['department'], Icons.domain),
                      _buildInfoTile('Visit Purpose', visitor['visit_purpose'], Icons.info_outline),
                      _buildInfoTile('Schedule Period', visitor['visit_period'], Icons.calendar_month),
                      const SizedBox(height: 24),

                      // QR Code Card Details
                      _buildHeaderSection('Visitor Pass / Ticket'),
                      Center(
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: visitor['qr_code_data'] ?? 'VMS-TICKET',
                                  size: 140,
                                ),
                                const SizedBox(height: 8),
                                Text(visitor['qr_code_data'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Invitation Code', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Documents Attached
                      _buildHeaderSection('Documents'),
                      _buildDocTile('Signed NDA Agreement.pdf', 'Signed 09:35', Colors.green),
                      _buildDocTile('Health Declaration Form.pdf', 'Signed 09:36', Colors.green),
                      const SizedBox(height: 24),

                      // Visit Timeline
                      _buildHeaderSection('Timeline Events'),
                      _buildTimelineSection(controller),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBadge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeaderSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInfoTile(String label, String val, IconData icon) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey[400], size: 20),
      title: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      subtitle: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDocTile(String name, String status, Color color) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.description, color: color, size: 22),
      title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text(status, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      trailing: const Icon(Icons.download, size: 18),
    );
  }

  Widget _buildTimelineSection(DashboardController controller) {
    return Column(
      children: controller.rxTimeline.map((item) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.circle, size: 6, color: Colors.white),
                ),
                Container(width: 2, height: 32, color: Colors.grey[200]),
              ],
            ),
            const SizedBox(width: 12),
            Text(item['time'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(item['desc'], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
