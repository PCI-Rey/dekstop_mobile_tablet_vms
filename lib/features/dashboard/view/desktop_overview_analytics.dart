import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/shared/widgets/app_snackbar.dart';

class DesktopOverviewAnalytics extends StatefulWidget {
  final VoidCallback onAddVisitor;

  const DesktopOverviewAnalytics({
    super.key,
    required this.onAddVisitor,
  });

  @override
  State<DesktopOverviewAnalytics> createState() =>
      _DesktopOverviewAnalyticsState();
}

class _DesktopOverviewAnalyticsState extends State<DesktopOverviewAnalytics> {
  String _selectedStatisticFilter = 'Week';

  // Design Tokens
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _brandBlue = Color(0xFF003082);
  static const Color _accentBlue = Color(0xFF2563EB);
  static const Color _cardBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Top Metric Cards Row + Add Visitor Button ──────────────────
          _buildTopMetricRow(),

          const SizedBox(height: 12),

          // ── 2. Middle 3 Feeds Row (Just Checked-in, Expected, Pending) ────
          _buildMiddleFeedsRow(),

          const SizedBox(height: 12),

          // ── 3. Analytics Row (Visitor Statistic Bar Chart + Visitor Donut) ─
          _buildAnalyticsRow(),

          const SizedBox(height: 12),

          // ── 4. Bottom Last Visits Table ──────────────────────────────────
          _buildLastVisitsTable(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Top Metric Cards Row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopMetricRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Card 1: Visitors Expected (20)
        Expanded(
          flex: 2,
          child: _buildMetricCard(
            count: '20',
            subtitle: 'Today',
            title: 'Visitors Expected',
            icon: Icons.person_search_rounded,
          ),
        ),
        const SizedBox(width: 10),

        // Card 2: Completed Meetings (10)
        Expanded(
          flex: 2,
          child: _buildMetricCard(
            count: '10',
            subtitle: 'Today',
            title: 'Completed Meetings',
            icon: Icons.how_to_reg_rounded,
          ),
        ),
        const SizedBox(width: 10),

        // Card 3: Defaulted Visitors (5)
        Expanded(
          flex: 2,
          child: _buildMetricCard(
            count: '5',
            subtitle: 'Today',
            title: 'Defaulted Visitors',
            icon: Icons.person_off_rounded,
          ),
        ),
        const SizedBox(width: 10),

        // Card 4: Pending Visits (21)
        Expanded(
          flex: 2,
          child: _buildMetricCard(
            count: '21',
            subtitle: 'Today',
            title: 'Pending Visits',
            icon: Icons.pending_actions_rounded,
          ),
        ),
        const SizedBox(width: 12),

        // [+ Add Visitor] Action Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onAddVisitor,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _brandBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _brandBlue.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_box_outlined,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Add Visitor',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildMetricCard({
    required String count,
    required String subtitle,
    required String title,
    required IconData icon,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Number, Today, and Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    count,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ],
          ),

          // Right: Blue Circular Icon Badge
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _accentBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Middle 3 Feeds Row (Just Checked-in, Expected, Pending)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMiddleFeedsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Feed 1: Just Checked-in
        Expanded(
          child: _buildFeedContainer(
            title: 'Just Checked-in',
            children: [
              _buildCheckedInItem(
                name: 'Adela Parkson',
                role: 'Manager',
                host: 'Kevin Hart',
                tag: 'Business',
                tagColor: const Color(0xFFF97316),
                time: '09:25 PM',
                duration: '2h 25m',
                avatarAsset: 'assets/images/ava_person1.png',
              ),
              _buildCheckedInItem(
                name: 'Christian Mad',
                role: 'Service Vendor',
                host: 'Jack Cooper',
                tag: 'Meeting',
                tagColor: const Color(0xFFF59E0B),
                time: '10:00 PM',
                duration: '1h 40m',
                avatarAsset: 'assets/images/ava_person2.png',
              ),
              _buildCheckedInItem(
                name: 'Jason Statham',
                role: 'Delivery',
                host: 'Kevin Hart',
                tag: 'Business',
                tagColor: const Color(0xFFF97316),
                time: '11:10 PM',
                duration: '3h 10m',
                avatarAsset: 'assets/images/ava_person3.png',
              ),
              _buildCheckedInItem(
                name: 'Adela Parkson',
                role: 'Creative Director',
                host: 'Nick Parker',
                tag: 'Business',
                tagColor: const Color(0xFFF97316),
                time: '03:20 PM',
                duration: '2h 00m',
                avatarAsset: 'assets/images/ava_person4.png',
              ),
              _buildCheckedInItem(
                name: 'Adela Parkson',
                role: 'Creative Director',
                host: 'Nick Parker',
                tag: 'Business',
                tagColor: const Color(0xFFF97316),
                time: '03:20 PM',
                duration: '2h 00m',
                avatarAsset: 'assets/images/ava_person1.png',
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Feed 2: Expected Visitors
        Expanded(
          child: _buildFeedContainer(
            title: 'Expected Visitors',
            children: [
              _buildExpectedItem(
                name: 'Adela Parkson',
                role: 'Creative Director',
                host: 'Nick Parker',
                tag: 'Business',
                tagColor: const Color(0xFFF97316),
                time: '03:20 PM',
                avatarAsset: 'assets/images/ava_person3.png',
              ),
              _buildExpectedItem(
                name: 'Christian Mad',
                role: 'Service Vendor',
                host: 'Jack Cooper',
                tag: 'Meeting',
                tagColor: const Color(0xFF3B82F6),
                time: '10:00 PM',
                avatarAsset: 'assets/images/ava_person2.png',
              ),
              _buildExpectedItem(
                name: 'Jason Statham',
                role: 'Delivery Boy',
                host: 'Kevin Hart',
                tag: 'VIP',
                tagColor: const Color(0xFF10B981),
                time: '02:20 PM',
                avatarAsset: 'assets/images/ava_person1.png',
              ),
              _buildExpectedItem(
                name: 'Adela Parkson',
                role: 'Creative Director',
                host: 'Nick Parker',
                tag: 'Business',
                tagColor: const Color(0xFFF97316),
                time: '03:20 PM',
                avatarAsset: 'assets/images/ava_person4.png',
              ),
              _buildExpectedItem(
                name: 'Christian Mad',
                role: 'Service Vendor',
                host: 'Jack Cooper',
                tag: 'Meeting',
                tagColor: const Color(0xFF3B82F6),
                time: '10:00 PM',
                avatarAsset: 'assets/images/ava_person2.png',
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Feed 3: Pending Visits
        Expanded(
          child: _buildFeedContainer(
            title: 'Pending Visits',
            children: [
              _buildPendingItem(
                name: 'Adela Parkson',
                role: 'Creative Director',
                host: 'Vipul Gupta',
                time: '01:20 PM',
                avatarAsset: 'assets/images/ava_person4.png',
              ),
              _buildPendingItem(
                name: 'Christian Mad',
                role: 'Service Vendor',
                host: 'Amit Kumar',
                time: '01:20 PM',
                avatarAsset: 'assets/images/ava_person2.png',
              ),
              _buildPendingItem(
                name: 'Jason Statham',
                role: 'Delivery Boy',
                host: 'Kevin Hart',
                time: '01:20 PM',
                avatarAsset: 'assets/images/ava_person1.png',
              ),
              _buildPendingItem(
                name: 'Adela Parkson',
                role: 'Creative Director',
                host: 'Nitin Pathak',
                time: '01:20 PM',
                avatarAsset: 'assets/images/ava_person4.png',
              ),
              _buildPendingItem(
                name: 'Christian Mad',
                role: 'Service Vendor',
                host: 'Vipul Gupta',
                time: '01:20 PM',
                avatarAsset: 'assets/images/ava_person3.png',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Circular Blue Arrow (↗)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: _accentBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items
          ...children,
        ],
      ),
    );
  }

  Widget _buildCheckedInItem({
    required String name,
    required String role,
    required String host,
    required String tag,
    required Color tagColor,
    required String time,
    required String duration,
    required String avatarAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: AssetImage(avatarAsset),
          ),
          const SizedBox(width: 7),

          // Name & Role
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Person to Meet + Tag
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Person to Meet',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),

          // Duration Blue Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              duration,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedItem({
    required String name,
    required String role,
    required String host,
    required String tag,
    required Color tagColor,
    required String time,
    required String avatarAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: AssetImage(avatarAsset),
          ),
          const SizedBox(width: 7),

          // Name & Role
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Person to Meet + Tag
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Person to Meet',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
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

  Widget _buildPendingItem({
    required String name,
    required String role,
    required String host,
    required String time,
    required String avatarAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: AssetImage(avatarAsset),
          ),
          const SizedBox(width: 7),

          // Name & Role
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Person to Meet
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Person to Meet',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),

          // Time
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),

          // Green Check & Red Cross Action Buttons
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  AppSnackbar.success(
                    title: 'Visit Approved',
                    message: 'Visit request for $name has been approved.',
                  );
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  AppSnackbar.error(
                    title: 'Visit Rejected',
                    message: 'Visit request for $name has been declined.',
                  );
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Analytics Row (Visitor Statistic Bar Chart + Visitor Donut)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAnalyticsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Visitor Statistic Bar Chart (~65% width)
        Expanded(
          flex: 65,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + Week/Month/Year filter pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visitor Statistic',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: ['Week', 'Month', 'Year'].map((f) {
                          final isSelected = _selectedStatisticFilter == f;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedStatisticFilter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                f,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? _textDark : _textMuted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bar Chart Widget
                _buildBarChart(),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Right: Visitor Donut Chart (~35% width)
        Expanded(
          flex: 35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visitor',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 10),

                // Donut Visual
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: _DonutChartPainter(),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '75',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'Visits',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Legend Row: Visitor (Green), Employee (Blue), Staff (Red)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                        label: 'Visitor', color: const Color(0xFF22C55E)),
                    const SizedBox(width: 12),
                    _buildLegendItem(
                        label: 'Employee', color: const Color(0xFF0EA5E9)),
                    const SizedBox(width: 12),
                    _buildLegendItem(
                        label: 'Staff', color: const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    const data = [
      {'day': 'Monday', 'val': 58},
      {'day': 'Tuesday', 'val': 76},
      {'day': 'Wednesday', 'val': 24},
      {'day': 'Thursday', 'val': 69},
      {'day': 'Friday', 'val': 48},
      {'day': 'Saturday', 'val': 74},
      {'day': 'Sunday', 'val': 90},
    ];

    return SizedBox(
      height: 145,
      child: Row(
        children: [
          // Y-Axis Labels
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ['100', '80', '60', '40', '20', '0']
                .map(
                  (y) => Text(
                    y,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 8),

          // Grid Lines + Vertical Bars
          Expanded(
            child: Stack(
              children: [
                // Horizontal Guidelines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (_) => const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: Color(0xFFF1F5F9),
                    ),
                  ),
                ),

                // Bars with Day Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    final val = item['val'] as int;
                    final day = item['day'] as String;
                    final barHeight = (val / 100) * 115;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 34,
                          height: barHeight,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4C6FFF),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(5)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Bottom Last Visits Table
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLastVisitsTable() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Visits',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: _accentBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildTableHeaderText("Visitor's Name")),
                Expanded(flex: 2, child: _buildTableHeaderText('Person to Meet')),
                Expanded(flex: 2, child: _buildTableHeaderText('Department')),
                Expanded(flex: 2, child: _buildTableHeaderText('Check-in')),
                Expanded(flex: 2, child: _buildTableHeaderText('Check-out')),
                Expanded(flex: 2, child: _buildTableHeaderText('Date')),
                Expanded(flex: 2, child: _buildTableHeaderText('Visitor Type')),
                Expanded(flex: 2, child: _buildTableHeaderText('Granted by')),
                Expanded(flex: 2, child: _buildTableHeaderText('Status')),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Table Rows
          _buildLastVisitRow(
            name: 'Adela Parkson',
            role: 'Creative Director',
            host: 'Vipul Gupta',
            department: '—',
            checkIn: '01:20 PM',
            checkOut: '03:05 PM',
            date: '24/04/2024',
            visitorType: 'Client',
            grantedBy: 'Christian Mad',
            status: 'VIP',
            statusBgColor: const Color(0xFFDCFCE7),
            statusTextColor: const Color(0xFF15803D),
            avatarAsset: 'assets/images/ava_person4.png',
          ),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),
          _buildLastVisitRow(
            name: 'Jason Statham',
            role: 'Creative Director',
            host: 'Vipul Gupta',
            department: '—',
            checkIn: '01:20 PM',
            checkOut: '03:05 PM',
            date: '24/04/2024',
            visitorType: 'Client',
            grantedBy: 'Christian Mad',
            status: 'Interview',
            statusBgColor: const Color(0xFFFEF3C7),
            statusTextColor: const Color(0xFFD97706),
            avatarAsset: 'assets/images/ava_person1.png',
          ),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),
          _buildLastVisitRow(
            name: 'Christian Mad',
            role: 'Service Vendor',
            host: 'Jack Cooper',
            department: 'IT Support',
            checkIn: '10:00 AM',
            checkOut: '11:45 AM',
            date: '24/04/2024',
            visitorType: 'Vendor',
            grantedBy: 'Kevin Hart',
            status: 'Business',
            statusBgColor: const Color(0xFFE0F2FE),
            statusTextColor: const Color(0xFF0369A1),
            avatarAsset: 'assets/images/ava_person2.png',
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderText(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildLastVisitRow({
    required String name,
    required String role,
    required String host,
    required String department,
    required String checkIn,
    required String checkOut,
    required String date,
    required String visitorType,
    required String grantedBy,
    required String status,
    required Color statusBgColor,
    required Color statusTextColor,
    required String avatarAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Visitor Name & Avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: AssetImage(avatarAsset),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Person to Meet
          Expanded(
            flex: 2,
            child: Text(
              host,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),

          // Department
          Expanded(
            flex: 2,
            child: Text(
              department,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: _textMuted,
              ),
            ),
          ),

          // Check-in
          Expanded(
            flex: 2,
            child: Text(
              checkIn,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),

          // Check-out
          Expanded(
            flex: 2,
            child: Text(
              checkOut,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: _textMuted,
              ),
            ),
          ),

          // Visitor Type
          Expanded(
            flex: 2,
            child: Text(
              visitorType,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),

          // Granted by
          Expanded(
            flex: 2,
            child: Text(
              grantedBy,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: statusTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut Chart Custom Painter (Green, Blue, Red Segments)
// ─────────────────────────────────────────────────────────────────────────────
class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const strokeWidth = 18.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Segment 1: Green (Visitor) ~ 40% (144 deg)
    paint.color = const Color(0xFF22C55E);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * 0.40, false, paint);

    // Segment 2: Blue (Employee) ~ 35% (126 deg)
    paint.color = const Color(0xFF0EA5E9);
    canvas.drawArc(
        rect, -math.pi / 2 + 2 * math.pi * 0.40, 2 * math.pi * 0.35, false, paint);

    // Segment 3: Red (Staff) ~ 25% (90 deg)
    paint.color = const Color(0xFFEF4444);
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * 0.75, 2 * math.pi * 0.25,
        false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
