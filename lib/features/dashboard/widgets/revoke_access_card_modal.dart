import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/widgets/app_snackbar.dart';
import '../controller/dashboard_controller.dart';

/// Modal dialog for revoking granted access controls from a visitor's access card.
/// Strictly designed according to the VMS Operator Tablet Design System Standard
/// and matching the Web VMS Revoke Access specification.
class RevokeAccessCardModal extends StatefulWidget {
  final String cardNumber;
  final Map<String, dynamic> card;
  final Map<String, dynamic>? visitor;

  const RevokeAccessCardModal({
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
      builder: (dialogContext) => RevokeAccessCardModal(
        cardNumber: cardNumber,
        card: card,
        visitor: visitor,
      ),
    );
  }

  @override
  State<RevokeAccessCardModal> createState() => _RevokeAccessCardModalState();
}

class _RevokeAccessCardModalState extends State<RevokeAccessCardModal> {
  late final DashboardController controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridScrollController = ScrollController();
  final Set<String> _selectedAccessIds = <String>{};
  String _searchQuery = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DashboardController>();

    // Fetch granted access controls for this visitor and registered site
    final visitorTrxId = widget.visitor?['trx_id']?.toString() ??
        widget.visitor?['id']?.toString() ??
        widget.visitor?['transaction_visitor_id']?.toString();

    controller.fetchGrantedAccessControls(
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

  /// Clean, high-contrast custom checkbox matching the Web VMS design standard.
  Widget _buildCheckbox({
    required bool isSelected,
    double size = 18,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF005696) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? const Color(0xFF005696) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Center(
              child: Icon(
                Icons.check_rounded,
                size: size - 4,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedAccessIds.isEmpty) {
      AppSnackbar.warning(
        title: 'Validation Error',
        message: 'Please select at least one access control to revoke.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await controller.revokeAccessCardAction(
      cardNumber: widget.cardNumber,
      accessControls: _selectedAccessIds.toList(),
      targetCard: widget.card,
      targetTrxVisitorId: widget.visitor?['trx_id']?.toString() ??
          widget.visitor?['id']?.toString() ??
          widget.visitor?['transaction_visitor_id']?.toString(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
    }
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
        constraints: const BoxConstraints(maxHeight: 650),
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
                    'Revoke Access Card',
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

            // ── 2. Search & Controls Subheader ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
              child: Column(
                children: [
                  // Search TextField (Icon & hintText perfectly centered)
                  Container(
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

                  const SizedBox(height: 12),

                  // Select All & Counter Row (Selected : [0 / 5 selected])
                  Obx(() {
                    final rawList = controller.rxGrantedAccessControls;
                    final filtered = _getFilteredList(rawList);
                    final totalCount = filtered.length;
                    final selectedCount = filtered.where((item) {
                      final id = (item['access_control_id'] ??
                              item['id'] ??
                              item['Id'] ??
                              '')
                          .toString();
                      return _selectedAccessIds.contains(id);
                    }).length;

                    final isAllSelected =
                        totalCount > 0 && selectedCount == totalCount;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Select All Checkbox
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              setState(() {
                                if (isAllSelected) {
                                  for (final item in filtered) {
                                    final id = (item['access_control_id'] ??
                                            item['id'] ??
                                            item['Id'] ??
                                            '')
                                        .toString();
                                    _selectedAccessIds.remove(id);
                                  }
                                } else {
                                  for (final item in filtered) {
                                    final id = (item['access_control_id'] ??
                                            item['id'] ??
                                            item['Id'] ??
                                            '')
                                        .toString();
                                    if (id.isNotEmpty) {
                                      _selectedAccessIds.add(id);
                                    }
                                  }
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCheckbox(
                                    isSelected: isAllSelected,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Select All',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Selected Counter Pill Badge (Selected : [0 / 5 selected])
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Selected : ',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004385),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$selectedCount / $totalCount selected',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // ── 3. Access Controls Grid View ──────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.rxIsGrantedAccessLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF005696),
                    ),
                  );
                }

                final rawList = controller.rxGrantedAccessControls;
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
                          'No granted access controls found to revoke',
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
                        final id = (item['access_control_id'] ??
                                item['id'] ??
                                item['Id'] ??
                                '')
                            .toString();
                        final name = (item['access_control_name'] ??
                                item['Name'] ??
                                item['name'] ??
                                '-')
                            .toString();
                        final isSelected = _selectedAccessIds.contains(id);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedAccessIds.remove(id);
                                } else {
                                  _selectedAccessIds.add(id);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF005696)
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isSelected ? 0.05 : 0.02,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
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
                                          color: isSelected
                                              ? const Color(0xFF004385)
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCheckbox(
                                    isSelected: isSelected,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // ── 4. Footer Buttons (Cancel & Submit) ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Submit Button (Disabled / grayed out if no card is selected)
                  Builder(
                    builder: (context) {
                      final hasSelection = _selectedAccessIds.isNotEmpty;
                      final canSubmit = hasSelection && !_isSubmitting;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: canSubmit ? _handleSubmit : null,
                          mouseCursor: canSubmit
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: hasSelection
                                  ? const Color(0xFF005696)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Submit',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: hasSelection
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
