import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/dashboard_controller.dart';

/// Modal dialog for displaying assigned access controls and their Grant/Revoke status
/// for a visitor's access card.
/// Strictly designed according to the VMS Operator Tablet Design System Standard
/// and matching the Web VMS Detail Access specification.
class DetailAccessCardModal extends StatefulWidget {
  final String cardNumber;
  final Map<String, dynamic> card;
  final Map<String, dynamic>? visitor;

  const DetailAccessCardModal({
    super.key,
    required this.cardNumber,
    required this.card,
    this.visitor,
  });

  static Future<void> show(
    BuildContext context, {
    required String cardNumber,
    required Map<String, dynamic> card,
    Map<String, dynamic>? visitor,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => DetailAccessCardModal(
        cardNumber: cardNumber,
        card: card,
        visitor: visitor,
      ),
    );
  }

  @override
  State<DetailAccessCardModal> createState() => _DetailAccessCardModalState();
}

class _DetailAccessCardModalState extends State<DetailAccessCardModal> {
  late final DashboardController controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridScrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    controller = Get.find<DashboardController>();

    final visitorTrxId = widget.visitor?['trx_id']?.toString() ??
        widget.visitor?['id']?.toString() ??
        widget.visitor?['transaction_visitor_id']?.toString();

    // Fetch detail access controls from /api/operator-invitation/extend/access-card
    controller.fetchDetailAccessControls(
      targetVisitorId: visitorTrxId,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredList(List<Map<String, dynamic>> raw) {
    if (_searchQuery.trim().isEmpty) return raw;
    final q = _searchQuery.trim().toLowerCase();
    return raw.where((item) {
      final name = (item['access_control_name'] ??
              item['Name'] ??
              item['name'] ??
              '')
          .toString()
          .toLowerCase();
      final brand = (item['brand_name'] ??
              item['BrandName'] ??
              item['brand'] ??
              '')
          .toString()
          .toLowerCase();
      final type = (item['card_type'] ??
              item['type'] ??
              item['Type'] ??
              '')
          .toString()
          .toLowerCase();
      return name.contains(q) || brand.contains(q) || type.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Header (Title + Close Button) ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Detail Access Card',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Color(0xFF64748B),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // ── 2. Search Subheader ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search access control',
                      hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 38,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(right: 12),
                    ),
                  ),
                ),
              ),
            ),

            // ── 3. Access Controls Grid View with Status Badges ─────────────
            Expanded(
              child: Obx(() {
                if (controller.rxIsDetailAccessLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF005696),
                    ),
                  );
                }

                final rawList = controller.rxDetailAccessControls;
                final filtered = _getFilteredList(rawList);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.vpn_key_off_outlined,
                          size: 38,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No access controls found',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Scrollbar(
                  controller: _gridScrollController,
                  thumbVisibility: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: GridView.builder(
                      controller: _gridScrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.12,
                      ),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final name = (item['access_control_name'] ??
                                item['Name'] ??
                                item['name'] ??
                                '-')
                            .toString();
                        final status = (item['visitor_give_access'] ??
                                item['status'] ??
                                'Grant')
                            .toString();

                        final isGrant =
                            status.trim().toLowerCase() == 'grant';
                        final badgeColor = isGrant
                            ? const Color(0xFF10B981) // Emerald green
                            : const Color(0xFFEF4444); // Red
                        final badgeText = isGrant ? 'Grant' : 'Revoke';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Outlined Door Icon
                              const Icon(
                                Icons.sensor_door_outlined,
                                size: 30,
                                color: Color(0xFF005696),
                              ),
                              const SizedBox(height: 8),

                              // Door Name
                              Expanded(
                                child: Center(
                                  child: Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Status Badge (Grant / Revoke)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badgeText,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef DetailAccessModal = DetailAccessCardModal;
