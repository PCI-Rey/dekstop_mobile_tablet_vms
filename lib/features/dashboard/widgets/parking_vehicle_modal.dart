import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/shared/widgets/app_snackbar.dart';
import '../controller/dashboard_controller.dart';

class ParkingVehicleModal extends StatefulWidget {
  const ParkingVehicleModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ParkingVehicleModal(),
      ),
    );
  }

  @override
  State<ParkingVehicleModal> createState() => _ParkingVehicleModalState();
}

class _ParkingVehicleModalState extends State<ParkingVehicleModal> {
  final DashboardController controller = Get.find<DashboardController>();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedVehicleType = 'All';
  String _selectedVisitorType = 'All';

  final List<String> _vehicleTypeOptions = [
    'All',
    'Car',
    'Motorcycle',
    'Bus',
    'Mini Bus',
    'Truck 16 Feet',
    'Truck 20 Feet',
    'Truck 40 Feet',
  ];

  @override
  void initState() {
    super.initState();
    _startDate = controller.rxVehicleFilterStartDate.value;
    _endDate = controller.rxVehicleFilterEndDate.value;
    _selectedVehicleType = controller.rxVehicleFilterVehicleType.value;
    _selectedVisitorType = controller.rxVehicleFilterVisitorType.value;

    controller.fetchPraRegistrationDependencies(silent: true);
    controller.fetchVehicleCount(silent: false);
  }

  bool _isTodayActive() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    return _startDate!.year == now.year &&
        _startDate!.month == now.month &&
        _startDate!.day == now.day &&
        _endDate!.year == now.year &&
        _endDate!.month == now.month &&
        _endDate!.day == now.day;
  }

  bool _isThisMonthActive() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return _startDate!.year == firstDay.year &&
        _startDate!.month == firstDay.month &&
        _startDate!.day == firstDay.day &&
        _endDate!.year == lastDay.year &&
        _endDate!.month == lastDay.month &&
        _endDate!.day == lastDay.day;
  }

  void _setTodayPreset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _startDate = today;
      _endDate = today;
    });
    controller.rxVehicleFilterStartDate.value = today;
    controller.rxVehicleFilterEndDate.value = today;
    controller.fetchVehicleCount(
      startDate: today,
      endDate: today,
      vehicleType: _selectedVehicleType,
      visitorType: _selectedVisitorType,
    );
  }

  void _setThisMonthPreset() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    setState(() {
      _startDate = firstDay;
      _endDate = lastDay;
    });
    controller.rxVehicleFilterStartDate.value = firstDay;
    controller.rxVehicleFilterEndDate.value = lastDay;
    controller.fetchVehicleCount(
      startDate: firstDay,
      endDate: lastDay,
      vehicleType: _selectedVehicleType,
      visitorType: _selectedVisitorType,
    );
  }

  void _onGeneratePressed() {
    controller.rxVehicleFilterStartDate.value = _startDate;
    controller.rxVehicleFilterEndDate.value = _endDate;
    controller.rxVehicleFilterVehicleType.value = _selectedVehicleType;
    controller.rxVehicleFilterVisitorType.value = _selectedVisitorType;

    controller.fetchVehicleCount(
      startDate: _startDate,
      endDate: _endDate,
      vehicleType: _selectedVehicleType,
      visitorType: _selectedVisitorType,
    );
  }

  void _onResetPressed() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedVehicleType = 'All';
      _selectedVisitorType = 'All';
    });
    controller.resetVehicleFilters();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    DateTime tempDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setPickerState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with Title and Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isStart ? 'Select Start Date' : 'Select End Date',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(dialogCtx).pop(),
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Calendar
                    Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF005696),
                          onPrimary: Colors.white,
                          onSurface: Color(0xFF1E293B),
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: tempDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        currentDate: now,
                        onDateChanged: (val) {
                          setPickerState(() => tempDate = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action Buttons (Today, Cancel, Select Date in one row)
                    Row(
                      children: [
                        // Quick Today Button
                        OutlinedButton.icon(
                          onPressed: () {
                            final today = DateTime(now.year, now.month, now.day);
                            Navigator.of(dialogCtx).pop(today);
                          },
                          icon: const Icon(
                            Icons.today_rounded,
                            size: 15,
                            color: Color(0xFF1976D2),
                          ),
                          label: Text(
                            'Today',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1976D2),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(tempDate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005696),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Select Date',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'mm/dd/yyyy';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$m/$d/$y';
  }

  Future<void> _showVehicleTypePicker() async {
    final items = _vehicleTypeOptions.map((type) {
      final label = type == 'All' ? 'All Vehicle Types' : type;
      return {'value': type, 'label': label};
    }).toList();

    final result = await _showSelectionDialog(
      context: context,
      title: 'Select Vehicle Type',
      items: items,
      selectedValue: _selectedVehicleType,
    );

    if (result != null) {
      setState(() => _selectedVehicleType = result);
    }
  }

  Future<void> _showVisitorTypePicker() async {
    final visitorTypes = controller.rxPraRegVisitorTypes;
    final List<Map<String, String>> items = [
      {'value': 'All', 'label': 'All Visitor Types'},
    ];

    for (final vt in visitorTypes) {
      final id = vt['id']?.toString() ?? '';
      final name = vt['name']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) {
        items.add({'value': id, 'label': name});
      }
    }

    final result = await _showSelectionDialog(
      context: context,
      title: 'Select Visitor Type',
      items: items,
      selectedValue: _selectedVisitorType,
    );

    if (result != null) {
      setState(() => _selectedVisitorType = result);
    }
  }

  Future<String?> _showSelectionDialog({
    required BuildContext context,
    required String title,
    required List<Map<String, String>> items,
    required String selectedValue,
  }) {
    final searchCtrl = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = items.where((it) {
              if (query.isEmpty) return true;
              return it['label']!.toLowerCase().contains(query);
            }).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxHeight: 440),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(dialogCtx).pop(),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (items.length > 5) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (_) => setDialogState(() {}),
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1976D2)),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, idx) {
                          final item = filtered[idx];
                          final isSelected = item['value'] == selectedValue;
                          return InkWell(
                            onTap: () => Navigator.of(dialogCtx).pop(item['value']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['label']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF1976D2)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _exportReport(String format) {
    AppSnackbar.info(
      title: 'Export $format',
      message: 'Vehicle & Parking report exported in $format format.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 800;

    final modalWidth = isCompact
        ? (screenWidth * 0.96).clamp(320.0, 720.0)
        : (screenWidth * 0.92).clamp(780.0, 980.0);

    return Container(
      width: modalWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Flexible(
            child: isCompact ? _buildCompactBody() : _buildWideBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'List Parking & Vehicle',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Wide Screen Layout ---
  Widget _buildWideBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Vehicles
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vehicle',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildVehicleCardsGridWide(),
              ],
            ),
          ),
        ),
        // Subtle vertical divider line
        Container(
          width: 1.0,
          color: const Color(0xFFE2E8F0),
        ),
        // Right Column: Filter & Export
        SizedBox(
          width: 255,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 20, 20),
            child: _buildFilterSection(),
          ),
        ),
      ],
    );
  }

  // --- Compact Screen Layout ---
  Widget _buildCompactBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          _buildVehicleCardsGridCompact(),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
          const SizedBox(height: 16),
          _buildFilterSection(),
        ],
      ),
    );
  }

  Widget _buildVehicleCardsGridWide() {
    return Obx(() {
      final _ = controller.rxVehicleCounts.length;
      final counts = controller.rxVehicleCounts;
      final isLoading = controller.rxIsVehicleCountLoading.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: 4 cards (Car, Motorcycle, Bus, Mini Bus)
          Row(
            children: [
              Expanded(
                child: _buildVehicleCard(
                  name: 'Car',
                  icon: Icons.directions_car_rounded,
                  count: counts['Car'] ?? 0,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVehicleCard(
                  name: 'Motorcycle',
                  icon: Icons.two_wheeler_rounded,
                  count: counts['Motorcycle'] ?? 0,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVehicleCard(
                  name: 'Bus',
                  icon: Icons.directions_bus_rounded,
                  count: counts['Bus'] ?? 0,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVehicleCard(
                  name: 'Mini Bus',
                  icon: Icons.airport_shuttle_rounded,
                  count: counts['Mini Bus'] ?? 0,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row: 3 cards (Truck 16 Feet, Truck 20 Feet, Truck 40 Feet)
          Row(
            children: [
              Expanded(
                child: _buildVehicleCard(
                  name: 'Truck 16 Feet',
                  icon: Icons.local_shipping_rounded,
                  count: counts['Truck 16 Feet'] ?? 0,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVehicleCard(
                  name: 'Truck 20 Feet',
                  icon: Icons.local_shipping_rounded,
                  count: counts['Truck 20 Feet'] ?? 0,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVehicleCard(
                  name: 'Truck 40 Feet',
                  icon: Icons.local_shipping_rounded,
                  count: counts['Truck 40 Feet'] ?? 0,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildVehicleCardsGridCompact() {
    final List<Map<String, dynamic>> vehicleSpecs = [
      {'name': 'Car', 'icon': Icons.directions_car_rounded},
      {'name': 'Motorcycle', 'icon': Icons.two_wheeler_rounded},
      {'name': 'Bus', 'icon': Icons.directions_bus_rounded},
      {'name': 'Mini Bus', 'icon': Icons.airport_shuttle_rounded},
      {'name': 'Truck 16 Feet', 'icon': Icons.local_shipping_rounded},
      {'name': 'Truck 20 Feet', 'icon': Icons.local_shipping_rounded},
      {'name': 'Truck 40 Feet', 'icon': Icons.local_shipping_rounded},
    ];

    return Obx(() {
      final _ = controller.rxVehicleCounts.length;
      final counts = controller.rxVehicleCounts;
      final isLoading = controller.rxIsVehicleCountLoading.value;

      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: vehicleSpecs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) {
          final spec = vehicleSpecs[index];
          final name = spec['name'] as String;
          final icon = spec['icon'] as IconData;
          final count = counts[name] ?? 0;
          return _buildVehicleCard(
            name: name,
            icon: icon,
            count: count,
            isLoading: isLoading,
          );
        },
      );
    });
  }

  Widget _buildVehicleCard({
    required String name,
    required IconData icon,
    required int count,
    required bool isLoading,
  }) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF1976D2)),
                  ),
                )
              : Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter Header with Quick "Today" shortcut
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Today Fast Preset Pill
                InkWell(
                  onTap: _setTodayPreset,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isTodayActive() ? const Color(0xFF005696) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isTodayActive() ? const Color(0xFF005696) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.today_rounded,
                          size: 13,
                          color: _isTodayActive() ? Colors.white : const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Today',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _isTodayActive() ? Colors.white : const Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Month Preset Pill
                InkWell(
                  onTap: _setThisMonthPreset,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isThisMonthActive() ? const Color(0xFF005696) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isThisMonthActive() ? const Color(0xFF005696) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Month',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _isThisMonthActive() ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Start Date Notched Field
        _buildNotchedField(
          label: 'Start Date',
          valueText: _formatDate(_startDate),
          isPlaceholder: _startDate == null,
          trailingIcon: const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Color(0xFF475569),
          ),
          onTap: () => _pickDate(isStart: true),
        ),
        const SizedBox(height: 12),
        // End Date Notched Field
        _buildNotchedField(
          label: 'End Date',
          valueText: _formatDate(_endDate),
          isPlaceholder: _endDate == null,
          trailingIcon: const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Color(0xFF475569),
          ),
          onTap: () => _pickDate(isStart: false),
        ),
        const SizedBox(height: 12),
        // Vehicle Type Notched Dropdown
        _buildNotchedField(
          label: 'Vehicle Type',
          valueText: _selectedVehicleType == 'All' ? 'All Vehicle Types' : _selectedVehicleType,
          isPlaceholder: false,
          trailingIcon: const Icon(
            Icons.arrow_drop_down,
            size: 22,
            color: Color(0xFF64748B),
          ),
          onTap: _showVehicleTypePicker,
        ),
        const SizedBox(height: 12),
        // Visitor Type Notched Dropdown
        Builder(
          builder: (context) {
            final visitorTypes = controller.rxPraRegVisitorTypes;
            String displayVisitorType = 'All Visitor Types';
            if (_selectedVisitorType != 'All') {
              final match = visitorTypes.firstWhereOrNull(
                (vt) => vt['id']?.toString() == _selectedVisitorType,
              );
              if (match != null) {
                displayVisitorType = match['name']?.toString() ?? _selectedVisitorType;
              }
            }

            return _buildNotchedField(
              label: 'Visitor Type',
              valueText: displayVisitorType,
              isPlaceholder: false,
              trailingIcon: const Icon(
                Icons.arrow_drop_down,
                size: 22,
                color: Color(0xFF64748B),
              ),
              onTap: _showVisitorTypePicker,
            );
          },
        ),
        const SizedBox(height: 16),
        // Generate Button
        Obx(() {
          final isLoading = controller.rxIsVehicleCountLoading.value;
          return SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: isLoading ? null : _onGeneratePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005696),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.zero,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Generate',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        }),
        const SizedBox(height: 8),
        // Reset Button
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton(
            onPressed: _onResetPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              foregroundColor: const Color(0xFFEF4444),
              backgroundColor: Colors.white,
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Save as Template / Export row
        Text(
          'Save as Template',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildExportButton(
                label: 'CSV',
                color: const Color(0xFF00C9A7),
                icon: Icons.table_chart_outlined,
                onTap: () => _exportReport('CSV'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildExportButton(
                label: 'Excel',
                color: const Color(0xFF00B074),
                icon: Icons.description_outlined,
                onTap: () => _exportReport('Excel'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildExportButton(
                label: 'Export',
                color: const Color(0xFFEF4444),
                icon: Icons.picture_as_pdf_outlined,
                onTap: () => _exportReport('PDF'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotchedField({
    required String label,
    required String valueText,
    required bool isPlaceholder,
    required Widget trailingIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF005696), width: 1.2),
          ),
          suffixIcon: trailingIcon,
        ),
        child: Text(
          valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w500,
            color: isPlaceholder ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
