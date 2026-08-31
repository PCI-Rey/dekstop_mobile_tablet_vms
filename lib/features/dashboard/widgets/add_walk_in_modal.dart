import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vms_operator_tablet/core/shared/widgets/app_snackbar.dart';
import 'package:vms_operator_tablet/features/dashboard/controller/dashboard_controller.dart';

class DropdownMenuItemData<T> {
  final T value;
  final String label;

  DropdownMenuItemData({required this.value, required this.label});
}

/// Uploaded file model for Selfie and KTP
class UploadedFileData {
  final String name;
  final int sizeBytes;
  final String extension;
  final String? localPath;
  final Uint8List? bytes;

  UploadedFileData({
    required this.name,
    required this.sizeBytes,
    required this.extension,
    this.localPath,
    this.bytes,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Group mode visitor entry model
class GroupWalkInVisitorEntry {
  final String id = UniqueKey().toString();
  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController orgCtrl = TextEditingController();
  final TextEditingController identityCtrl = TextEditingController();
  final Map<String, TextEditingController> extraControllers = {};

  bool isSearchOpen = false;
  Map<String, dynamic>? selectedData;
  String? role;
  bool? isEmployee = false;

  // Vehicle data
  bool isDriving = false;
  String? vehicleType;
  final TextEditingController vehiclePlateCtrl = TextEditingController();

  // Documents (Selfie & KTP)
  UploadedFileData? selfieImage;
  UploadedFileData? ktpImage;

  void dispose() {
    searchCtrl.dispose();
    fullNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    orgCtrl.dispose();
    identityCtrl.dispose();
    vehiclePlateCtrl.dispose();
    for (final c in extraControllers.values) {
      c.dispose();
    }
  }
}

class AddWalkInModal extends StatefulWidget {
  const AddWalkInModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: AddWalkInModal(),
      ),
    );
  }

  @override
  State<AddWalkInModal> createState() => _AddWalkInModalState();
}

class _AddWalkInModalState extends State<AddWalkInModal> {
  final DashboardController controller = Get.find<DashboardController>();

  // 0: Self vs Others selection screen
  // 1: User Type (Visitor Type & Status Single/Group)
  // 2: Visitor Information
  // 3: Purpose Visit
  // 4: Vehicle/Parking Information
  // 5: Selfie Image
  // 6: Upload Identity (KTP)
  int _currentStep = 0;

  // --- Step 0 State: Self vs Others ---
  String? _invitationTarget; // 'self' or 'others'

  // --- Step 1 State: User Type ---
  Map<String, dynamic>? _selectedVisitorType;
  Map<String, dynamic>? _visitorTypeDetail;
  bool? _isGroup; // false = Single, true = Group
  String _groupCode = '';
  final TextEditingController _groupNameController = TextEditingController();

  // --- Step 2 State: Single Mode ---
  final TextEditingController _singleSearchCtrl = TextEditingController();
  final TextEditingController _singleFullNameCtrl = TextEditingController();
  final TextEditingController _singleEmailCtrl = TextEditingController();
  final TextEditingController _singlePhoneCtrl = TextEditingController();
  final TextEditingController _singleOrgCtrl = TextEditingController();
  final TextEditingController _singleIdentityCtrl = TextEditingController();
  final Map<String, TextEditingController> _singleExtraControllers = {};
  bool _singleIsSearchOpen = false;
  Map<String, dynamic>? _singleSelectedData;
  String? _singleRole;
  bool? _singleIsEmployee = false;

  // --- Step 2 State: Group Mode ---
  final List<GroupWalkInVisitorEntry> _groupVisitors = [];
  int _selectedGroupMemberIndex = 0;

  // --- Step 3 State: Purpose Visit ---
  Map<String, dynamic>? _selectedDestination;
  Map<String, dynamic>? _selectedPicHost;
  String? _selectedAgenda;
  final TextEditingController _otherAgendaController = TextEditingController();
  final Map<String, TextEditingController> _purposeExtraControllers = {};
  DateTime? _visitStart;
  DateTime? _visitEnd;

  final List<String> _agendaOptions = [
    'Meeting',
    'Presentation',
    'Visit',
    'Training',
    'Report',
    'Others',
  ];

  // --- Step 4 State: Vehicle Information ---
  bool _singleIsDriving = false;
  String? _singleVehicleType;
  final TextEditingController _singleVehiclePlateCtrl = TextEditingController();



  // --- Step 5 & 6 State: Documents ---
  UploadedFileData? _singleSelfieImage;
  UploadedFileData? _singleKtpImage;

  int _maxStepReached = 1;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _groupCode = _generateGroupCode();
    final entry = GroupWalkInVisitorEntry();
    entry.isEmployee = false;
    _groupVisitors.add(entry);
    controller.fetchPraRegistrationDependencies(silent: true);
  }

  String _generateGroupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _singleSearchCtrl.dispose();
    _singleFullNameCtrl.dispose();
    _singleEmailCtrl.dispose();
    _singlePhoneCtrl.dispose();
    _singleOrgCtrl.dispose();
    _singleIdentityCtrl.dispose();
    for (final c in _singleExtraControllers.values) {
      c.dispose();
    }
    for (final v in _groupVisitors) {
      v.dispose();
    }
    _otherAgendaController.dispose();
    for (final c in _purposeExtraControllers.values) {
      c.dispose();
    }
    _singleVehiclePlateCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dynamic Step List Generation
  // ─────────────────────────────────────────────────────────────────────────
  List<String> _getDynamicStepTitles() {
    final titles = ['User Type', 'Visitor Information', 'Purpose Visit'];
    final sections = _visitorTypeDetail?['section_page_visitor_types'] as List<dynamic>?;

    if (sections != null && sections.isNotEmpty) {
      bool hasVehicle = false;
      bool hasSelfie = false;
      bool hasKtp = false;

      for (var s in sections) {
        final sec = Map<String, dynamic>.from(s as Map);
        final name = (sec['name'] ?? '').toString().toLowerCase();
        final isDoc = sec['is_document'] == true;

        if (name.contains('vehicle') || name.contains('parking') || sec['sort'] == 2) {
          hasVehicle = true;
        } else if (isDoc && (name.contains('selfie') || sec['sort'] == 3)) {
          hasSelfie = true;
        } else if (isDoc && (name.contains('ktp') || name.contains('identity') || sec['sort'] == 4)) {
          hasKtp = true;
        }
      }

      if (hasVehicle) titles.add('Vehicle/Parking Information');
      if (hasSelfie) titles.add('Selfie Image');
      if (hasKtp) titles.add('Upload Identity (KTP)');
    } else {
      titles.addAll([
        'Vehicle/Parking Information',
        'Selfie Image',
        'Upload Identity (KTP)',
      ]);
    }

    return titles;
  }

  int get _maxSteps => _getDynamicStepTitles().length;

  // ─────────────────────────────────────────────────────────────────────────
  // Form Field Readers (Matching Pra-Register logic from /visitor-type/{id})
  // ─────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _getVisitorInfoPraFormFields() {
    final sectionsRaw = _visitorTypeDetail?['section_page_visitor_types'] as List<dynamic>?;
    if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
      for (var s in sectionsRaw) {
        final sec = Map<String, dynamic>.from(s as Map);
        final isDoc = sec['is_document'] == true;
        if (isDoc) continue;
        final secName = (sec['name'] ?? '').toString().toLowerCase();
        if (secName.contains('visitor info') || sec['sort'] == 0) {
          final form = (sec['visit_form'] as List<dynamic>?) ?? (sec['pra_form'] as List<dynamic>?) ?? [];
          return form
              .where((f) => f['is_enable'] == true)
              .map((f) => Map<String, dynamic>.from(f as Map))
              .toList();
        }
      }
    }
    return [
      {'remarks': 'is_employee', 'long_display_text': 'Are you Employee?', 'mandatory': true, 'field_type': 5},
      {'remarks': 'name', 'long_display_text': 'Full Name', 'mandatory': true, 'field_type': 0},
      {'remarks': 'email', 'long_display_text': 'Email', 'mandatory': true, 'field_type': 2},
      {'remarks': 'organization', 'long_display_text': 'Department / Organization / Company', 'mandatory': true, 'field_type': 0},
      {'remarks': 'phone', 'long_display_text': 'Phone', 'mandatory': true, 'field_type': 0},
      {'remarks': 'indentity_id', 'long_display_text': 'Identity (KTP)', 'mandatory': true, 'field_type': 0},
    ];
  }

  List<Map<String, dynamic>> _getPurposeVisitPraFormFields() {
    final sectionsRaw = _visitorTypeDetail?['section_page_visitor_types'] as List<dynamic>?;
    if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
      for (var s in sectionsRaw) {
        final sec = Map<String, dynamic>.from(s as Map);
        final isDoc = sec['is_document'] == true;
        if (isDoc) continue;
        final secName = (sec['name'] ?? '').toString().toLowerCase();
        if (secName.contains('purpose') || sec['sort'] == 1) {
          final form = (sec['visit_form'] as List<dynamic>?) ?? (sec['pra_form'] as List<dynamic>?) ?? [];
          return form
              .where((f) => f['is_enable'] == true)
              .map((f) => Map<String, dynamic>.from(f as Map))
              .toList();
        }
      }
    }
    return [
      {'remarks': 'site_place', 'long_display_text': 'Destination', 'mandatory': true, 'field_type': 3},
      {'remarks': 'host', 'long_display_text': 'PIC Host', 'mandatory': true, 'field_type': 3},
      {'remarks': 'agenda', 'long_display_text': 'Agenda', 'mandatory': true, 'field_type': 0},
      {'remarks': 'visitor_period_start', 'long_display_text': 'Visit Start', 'mandatory': true, 'field_type': 9},
      {'remarks': 'visitor_period_end', 'long_display_text': 'Visit End', 'mandatory': true, 'field_type': 9},
    ];
  }

  List<String> _getRolesForSelectedType() {
    final rolesRaw = (_visitorTypeDetail?['visitor_roles'] ??
        _selectedVisitorType?['visitor_roles']) as List<dynamic>?;
    if (rolesRaw != null && rolesRaw.isNotEmpty) {
      final roles = rolesRaw
          .map((r) => (r['role'] ?? '').toString())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();
      if (roles.isNotEmpty) return roles;
    }
    return [];
  }

  List<DropdownMenuItemData<String>> _getVehicleTypeOptions() {
    final sectionsRaw = (_visitorTypeDetail?['section_page_visitor_types'] ??
            _selectedVisitorType?['section_page_visitor_types']) as List<dynamic>?;
    if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
      for (final s in sectionsRaw) {
        if (s is! Map) continue;
        final sec = Map<String, dynamic>.from(s);
        final forms = [
          ...((sec['visit_form'] as List<dynamic>?) ?? []),
          ...((sec['pra_form'] as List<dynamic>?) ?? []),
        ];
        for (final f in forms) {
          if (f is! Map) continue;
          final field = Map<String, dynamic>.from(f);
          final remarks = (field['remarks'] ?? '').toString().toLowerCase().trim();
          final shortName = (field['short_name'] ?? '').toString().toLowerCase().trim();
          if (remarks == 'vehicle_type' || shortName.contains('vehicle type')) {
            final multipleOptions = field['multiple_option_fields'] as List<dynamic>?;
            if (multipleOptions != null && multipleOptions.isNotEmpty) {
              return multipleOptions.map((opt) {
                final optMap = Map<String, dynamic>.from(opt as Map);
                final val = (optMap['value'] ?? optMap['name'] ?? '').toString();
                final name = (optMap['name'] ?? optMap['value'] ?? '').toString();
                final displayLabel = name.isNotEmpty
                    ? (name.length > 1
                        ? '${name[0].toUpperCase()}${name.substring(1)}'
                        : name.toUpperCase())
                    : val;
                return DropdownMenuItemData<String>(
                  value: val,
                  label: displayLabel,
                );
              }).toList();
            }
          }
        }
      }
    }

    return [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Autofill helpers for Search Visitor / Employee
  // ─────────────────────────────────────────────────────────────────────────
  String _extractOrganizationName(dynamic rawOrg, [dynamic rawCompany]) {
    if (rawOrg is Map) {
      final name = rawOrg['name'] ?? rawOrg['code'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    } else if (rawOrg is String && rawOrg.trim().isNotEmpty) {
      if (rawOrg.startsWith('{') && rawOrg.contains('name:')) {
        final match = RegExp(r'name:\s*([^,}]+)').firstMatch(rawOrg);
        if (match != null) return match.group(1)?.trim() ?? rawOrg.trim();
      }
      return rawOrg.trim();
    }

    if (rawCompany is Map) {
      final name = rawCompany['name'] ?? rawCompany['code'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    } else if (rawCompany is String && rawCompany.trim().isNotEmpty) {
      return rawCompany.trim();
    }

    return '';
  }

  void _onSingleSelect(Map<String, dynamic> item) {
    setState(() {
      _singleSelectedData = item;
      _singleIsSearchOpen = false;
      _singleSearchCtrl.text = (item['name'] ?? item['visitor_name'] ?? '').toString();
      _singleFullNameCtrl.text = (item['name'] ?? item['visitor_name'] ?? '').toString();
      _singleEmailCtrl.text = (item['email'] ?? '').toString();
      _singlePhoneCtrl.text = (item['phone'] ?? '').toString();
      _singleOrgCtrl.text = _extractOrganizationName(item['Organization'] ?? item['organization'], item['company']);
      _singleIdentityCtrl.text = (item['identity_id'] ?? item['indentity_id'] ?? '').toString();
    });
  }

  void _clearSingle() {
    setState(() {
      _singleSelectedData = null;
      _singleSearchCtrl.clear();
      _singleFullNameCtrl.clear();
      _singleEmailCtrl.clear();
      _singlePhoneCtrl.clear();
      _singleOrgCtrl.clear();
      _singleIdentityCtrl.clear();
      for (final c in _singleExtraControllers.values) {
        c.clear();
      }
    });
  }

  void _onGroupSelect(int index, Map<String, dynamic> item) {
    if (index >= _groupVisitors.length) return;
    setState(() {
      final v = _groupVisitors[index];
      v.selectedData = item;
      v.isSearchOpen = false;
      v.searchCtrl.text = (item['name'] ?? item['visitor_name'] ?? '').toString();
      v.fullNameCtrl.text = (item['name'] ?? item['visitor_name'] ?? '').toString();
      v.emailCtrl.text = (item['email'] ?? '').toString();
      v.phoneCtrl.text = (item['phone'] ?? '').toString();
      v.orgCtrl.text = _extractOrganizationName(item['Organization'] ?? item['organization'], item['company']);
      v.identityCtrl.text = (item['identity_id'] ?? item['indentity_id'] ?? '').toString();
    });
  }

  void _clearGroup(int index) {
    if (index >= _groupVisitors.length) return;
    setState(() {
      final v = _groupVisitors[index];
      v.selectedData = null;
      v.searchCtrl.clear();
      v.fullNameCtrl.clear();
      v.emailCtrl.clear();
      v.phoneCtrl.clear();
      v.orgCtrl.clear();
      v.identityCtrl.clear();
      for (final c in v.extraControllers.values) {
        c.clear();
      }
    });
  }

  void _addGroupVisitor() {
    setState(() {
      final entry = GroupWalkInVisitorEntry();
      entry.isEmployee = false;
      _groupVisitors.add(entry);
    });
  }

  void _removeGroupVisitor(int index) {
    if (_groupVisitors.length > 1) {
      setState(() {
        _groupVisitors[index].dispose();
        _groupVisitors.removeAt(index);
        if (_selectedGroupMemberIndex >= _groupVisitors.length) {
          _selectedGroupMemberIndex = _groupVisitors.length - 1;
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step Validation Checkers
  // ─────────────────────────────────────────────────────────────────────────
  bool get _isStep0Valid => _invitationTarget != null;

  bool get _isStep1Valid {
    if (_selectedVisitorType == null || _isGroup == null) return false;
    return true;
  }

  bool get _isStep2Valid {
    final fields = _getVisitorInfoPraFormFields();
    if (_isGroup == true) {
      if (_groupNameController.text.trim().isEmpty) return false;
      if (_groupVisitors.isEmpty) return false;
      for (final v in _groupVisitors) {
        for (final f in fields) {
          final isMandatory = f['mandatory'] == true;
          if (!isMandatory) continue;
          final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
          if (remarks == 'is_employee' && v.isEmployee == null) return false;
          if (remarks == 'name' && v.fullNameCtrl.text.trim().isEmpty) return false;
          if (remarks == 'email' && v.emailCtrl.text.trim().isEmpty) return false;
          if (remarks == 'phone' && v.phoneCtrl.text.trim().isEmpty) return false;
          if ((remarks == 'organization' || remarks == 'company') && v.orgCtrl.text.trim().isEmpty) return false;
          if ((remarks == 'identity_id' || remarks == 'indentity_id') && v.identityCtrl.text.trim().isEmpty) return false;
          if ((remarks == 'visitor_role' || remarks == 'role') && (v.role == null || v.role!.isEmpty)) return false;
          if (remarks != 'name' &&
              remarks != 'email' &&
              remarks != 'phone' &&
              remarks != 'organization' &&
              remarks != 'company' &&
              remarks != 'identity_id' &&
              remarks != 'indentity_id' &&
              remarks != 'visitor_role' &&
              remarks != 'role' &&
              remarks != 'is_employee' &&
              remarks != 'employee') {
            if (v.extraControllers[remarks]?.text.trim().isEmpty ?? true) return false;
          }
        }
      }
      return true;
    } else {
      for (final f in fields) {
        final isMandatory = f['mandatory'] == true;
        if (!isMandatory) continue;
        final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
        if (remarks == 'is_employee' && _singleIsEmployee == null) return false;
        if (remarks == 'name' && _singleFullNameCtrl.text.trim().isEmpty) return false;
        if (remarks == 'email' && _singleEmailCtrl.text.trim().isEmpty) return false;
        if (remarks == 'phone' && _singlePhoneCtrl.text.trim().isEmpty) return false;
        if ((remarks == 'organization' || remarks == 'company') && _singleOrgCtrl.text.trim().isEmpty) return false;
        if ((remarks == 'identity_id' || remarks == 'indentity_id') && _singleIdentityCtrl.text.trim().isEmpty) return false;
        if ((remarks == 'visitor_role' || remarks == 'role') && (_singleRole == null || _singleRole!.isEmpty)) return false;
        if (remarks != 'name' &&
            remarks != 'email' &&
            remarks != 'phone' &&
            remarks != 'organization' &&
            remarks != 'company' &&
            remarks != 'identity_id' &&
            remarks != 'indentity_id' &&
            remarks != 'visitor_role' &&
            remarks != 'role' &&
            remarks != 'is_employee' &&
            remarks != 'employee') {
          if (_singleExtraControllers[remarks]?.text.trim().isEmpty ?? true) return false;
        }
      }
      return true;
    }
  }

  bool get _isStep3Valid {
    final fields = _getPurposeVisitPraFormFields();
    if (fields.isEmpty) {
      if (_selectedDestination == null) return false;
      if (_selectedPicHost == null) return false;
      if (_selectedAgenda == null || _selectedAgenda!.isEmpty) return false;
      if (_selectedAgenda == 'Others' && _otherAgendaController.text.trim().isEmpty) return false;
      if (_visitStart == null) return false;
      if (_visitEnd == null) return false;
      if (_visitEnd!.isBefore(_visitStart!) || _visitEnd!.isAtSameMomentAs(_visitStart!)) return false;
      return true;
    }

    for (final f in fields) {
      final isMandatory = f['mandatory'] == true;
      if (!isMandatory) continue;
      final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
      if ((remarks == 'site_place' || remarks == 'destination') && _selectedDestination == null) return false;
      if ((remarks == 'host' || remarks == 'pic_host') && _selectedPicHost == null) return false;
      if (remarks == 'agenda') {
        if (_selectedAgenda == null || _selectedAgenda!.isEmpty) return false;
        if (_selectedAgenda == 'Others' && _otherAgendaController.text.trim().isEmpty) return false;
      }
      if (remarks == 'visitor_period_start' && _visitStart == null) return false;
      if (remarks == 'visitor_period_end' && _visitEnd == null) return false;
      if (remarks != 'site_place' &&
          remarks != 'destination' &&
          remarks != 'host' &&
          remarks != 'pic_host' &&
          remarks != 'agenda' &&
          remarks != 'visitor_period_start' &&
          remarks != 'visitor_period_end') {
        if (_purposeExtraControllers[remarks]?.text.trim().isEmpty ?? true) return false;
      }
    }
    if (_visitStart != null && _visitEnd != null) {
      if (_visitEnd!.isBefore(_visitStart!) || _visitEnd!.isAtSameMomentAs(_visitStart!)) return false;
    }
    return true;
  }

  bool _isBicycle(String? vehicleType) {
    if (vehicleType == null) return false;
    final t = vehicleType.toLowerCase().trim();
    return t == 'bicycle' || t == 'sepeda' || t.contains('bicycle') || t.contains('sepeda') || t == 'bike';
  }

  bool get _isStep4Valid {
    if (_isGroup == true) {
      for (final v in _groupVisitors) {
        if (v.isDriving == true) {
          if (v.vehicleType == null || v.vehicleType!.isEmpty) return false;
          if (!_isBicycle(v.vehicleType) && v.vehiclePlateCtrl.text.trim().isEmpty) return false;
        }
      }
      return true;
    } else {
      if (_singleIsDriving == true) {
        if (_singleVehicleType == null || _singleVehicleType!.isEmpty) return false;
        if (!_isBicycle(_singleVehicleType) && _singleVehiclePlateCtrl.text.trim().isEmpty) return false;
      }
      return true;
    }
  }

  bool get _isStep5Valid => true;

  bool get _isStep6Valid => true;

  bool get _isCurrentStepValid {
    if (_currentStep == 0) return _isStep0Valid;
    if (_currentStep == 1) return _isStep1Valid;
    if (_currentStep == 2) return _isStep2Valid;
    if (_currentStep == 3) return _isStep3Valid;
    if (_currentStep == 4) return _isStep4Valid;
    if (_currentStep == 5) return _isStep5Valid;
    if (_currentStep == 6) return _isStep6Valid;
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // File & Camera Image Picking with 5MB & Format Validation
  // ─────────────────────────────────────────────────────────────────────────
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png'];

  Future<void> _pickImageFile({
    required bool isKtp,
    required bool isGroupMember,
    int groupIndex = 0,
  }) async {
    try {
      Uint8List? fileBytes;
      String? fileName;
      String? filePath;

      // 1. Try FilePicker first (Highly reliable on Desktop Windows & Mobile)
      try {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: _allowedExtensions,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          fileBytes = file.bytes;
          fileName = file.name;
          filePath = file.path;
          if (fileBytes == null && filePath != null && !kIsWeb) {
            fileBytes = await File(filePath).readAsBytes();
          }
        }
      } catch (filePickerErr) {
        debugPrint('FilePicker error, attempting ImagePicker fallback: $filePickerErr');
      }

      // 2. Fallback to ImagePicker if FilePicker did not obtain a file
      if (fileBytes == null && fileName == null) {
        try {
          final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
          if (photo != null) {
            fileBytes = await photo.readAsBytes();
            fileName = photo.name;
            filePath = photo.path;
          }
        } catch (imagePickerErr) {
          debugPrint('ImagePicker error: $imagePickerErr');
        }
      }

      if (fileBytes == null || fileName == null) {
        return; // User cancelled
      }

      final size = fileBytes.length;
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase().replaceAll('.', '')
          : 'jpg';

      if (!_allowedExtensions.contains(ext)) {
        AppSnackbar.error(
          title: 'Invalid File Format',
          message: 'Only JPG, JPEG, and PNG images are supported.',
        );
        return;
      }

      if (size > _maxFileSizeBytes) {
        AppSnackbar.error(
          title: 'File Too Large',
          message: 'File size exceeds the 5 MB limit. Please choose a smaller image.',
        );
        return;
      }

      final uploaded = UploadedFileData(
        name: fileName,
        sizeBytes: size,
        extension: ext,
        localPath: filePath,
        bytes: fileBytes,
      );

      setState(() {
        if (isGroupMember && groupIndex < _groupVisitors.length) {
          if (isKtp) {
            _groupVisitors[groupIndex].ktpImage = uploaded;
          } else {
            _groupVisitors[groupIndex].selfieImage = uploaded;
          }
        } else {
          if (isKtp) {
            _singleKtpImage = uploaded;
          } else {
            _singleSelfieImage = uploaded;
          }
        }
      });

      AppSnackbar.success(
        title: 'Image Uploaded',
        message: '${isKtp ? 'KTP' : 'Selfie'} image uploaded successfully (${uploaded.sizeFormatted}).',
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      AppSnackbar.error(
        title: 'Upload Error',
        message: 'Could not select image file. Please try again.',
      );
    }
  }

  Future<void> _captureImageFromCamera({
    required bool isKtp,
    required bool isGroupMember,
    int groupIndex = 0,
  }) async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: isKtp ? CameraDevice.rear : CameraDevice.front,
      );
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      final size = bytes.length;
      final ext = photo.name.split('.').last.toLowerCase();

      if (!_allowedExtensions.contains(ext) && ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
        AppSnackbar.error(
          title: 'Invalid Image Format',
          message: 'Camera image format is not supported (JPG/PNG only).',
        );
        return;
      }

      if (size > _maxFileSizeBytes) {
        AppSnackbar.error(
          title: 'Image Too Large',
          message: 'Captured image exceeds the 5 MB limit. Please try again.',
        );
        return;
      }

      final uploaded = UploadedFileData(
        name: photo.name,
        sizeBytes: size,
        extension: ext.isNotEmpty ? ext : 'jpg',
        localPath: photo.path,
        bytes: bytes,
      );

      setState(() {
        if (isGroupMember && groupIndex < _groupVisitors.length) {
          if (isKtp) {
            _groupVisitors[groupIndex].ktpImage = uploaded;
          } else {
            _groupVisitors[groupIndex].selfieImage = uploaded;
          }
        } else {
          if (isKtp) {
            _singleKtpImage = uploaded;
          } else {
            _singleSelfieImage = uploaded;
          }
        }
      });

      AppSnackbar.success(
        title: 'Photo Captured',
        message: '${isKtp ? 'KTP' : 'Selfie'} photo captured successfully (${uploaded.sizeFormatted}).',
      );
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      // If camera plugin is not available on Windows, open file dialog as graceful fallback
      _pickImageFile(isKtp: isKtp, isGroupMember: isGroupMember, groupIndex: groupIndex);
    }
  }

  void _removeUploadedImage({
    required bool isKtp,
    required bool isGroupMember,
    int groupIndex = 0,
  }) {
    setState(() {
      if (isGroupMember && groupIndex < _groupVisitors.length) {
        if (isKtp) {
          _groupVisitors[groupIndex].ktpImage = null;
        } else {
          _groupVisitors[groupIndex].selfieImage = null;
        }
      } else {
        if (isKtp) {
          _singleKtpImage = null;
        } else {
          _singleSelfieImage = null;
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Visitor Type Selection Handler
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onVisitorTypeSelected(Map<String, dynamic> type) async {
    setState(() {
      _selectedVisitorType = type;
      _visitorTypeDetail = null;
    });

    final typeId = (type['id'] ?? '').toString();
    final detail = await controller.fetchVisitorTypeDetail(typeId);

    if (mounted) {
      setState(() {
        _visitorTypeDetail = detail;
        _singleIsEmployee = false;
        _singleRole = null;
        _singleVehicleType = null;
        _singleIsDriving = false;
        _singleKtpImage = null;
        _singleSelfieImage = null;
        _maxStepReached = 1;
        for (final v in _groupVisitors) {
          v.isEmployee = false;
          v.role = null;
          v.vehicleType = null;
          v.isDriving = false;
          v.selectedData = null;
          v.searchCtrl.clear();
          v.fullNameCtrl.clear();
          v.emailCtrl.clear();
          v.phoneCtrl.clear();
          v.orgCtrl.clear();
          v.identityCtrl.clear();
          v.vehiclePlateCtrl.clear();
          v.ktpImage = null;
          v.selfieImage = null;
          for (final c in v.extraControllers.values) {
            c.clear();
          }
        }
        _clearSingle();
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 680,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          if (_currentStep > 0) ...[
            _buildStepper(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ],
          Expanded(
            child: _buildCurrentStepContent(),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      child: Row(
        children: [
          Text(
            'Add Invitation Visitor',
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  bool _isStepCompleted(int stepNum) {
    if (stepNum == _currentStep) return false;
    if (stepNum > _maxStepReached) return false;
    if (stepNum == 1) return _isStep1Valid && (_currentStep > 1 || _maxStepReached > 1);
    if (stepNum == 2) return _isStep1Valid && _isStep2Valid && (_currentStep > 2 || _maxStepReached > 2);
    if (stepNum == 3) return _isStep1Valid && _isStep2Valid && _isStep3Valid && (_currentStep > 3 || _maxStepReached > 3);
    if (stepNum == 4) return _isStep1Valid && _isStep2Valid && _isStep3Valid && _isStep4Valid && (_currentStep > 4 || _maxStepReached > 4);
    if (stepNum == 5) return _isStep1Valid && _isStep2Valid && _isStep3Valid && _isStep4Valid && _isStep5Valid && (_currentStep > 5 || _maxStepReached > 5);
    if (stepNum == 6) return _isStep1Valid && _isStep2Valid && _isStep3Valid && _isStep4Valid && _isStep5Valid && _isStep6Valid && (_currentStep > 6 || _maxStepReached > 6);
    return false;
  }

  bool _canJumpToStep(int stepNum) {
    if (_currentStep == stepNum) return false;
    if (stepNum == 1) return true;
    if (stepNum == 2) return _isStep1Valid;
    if (stepNum == 3) return _isStep1Valid && _isStep2Valid;
    if (stepNum == 4) return _isStep1Valid && _isStep2Valid && _isStep3Valid;
    if (stepNum == 5) return _isStep1Valid && _isStep2Valid && _isStep3Valid && _isStep4Valid;
    if (stepNum == 6) return _isStep1Valid && _isStep2Valid && _isStep3Valid && _isStep4Valid && _isStep5Valid;
    return false;
  }

  Widget _buildStepper() {
    final titles = _getDynamicStepTitles();
    final showAllSteps = _selectedVisitorType != null || _currentStep >= 2;
    final visibleCount = showAllSteps ? titles.length : 1;
    final visibleTitles = titles.take(visibleCount).toList();

    return Container(
      color: const Color(0xFFFAFCFF),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(visibleTitles.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = (index ~/ 2) + 1;
            bool isConnectorCompleted = false;
            if (stepBefore == 1) {
              isConnectorCompleted = _isStep1Valid && (_currentStep >= 2 || _maxStepReached >= 2);
            } else if (stepBefore == 2) {
              isConnectorCompleted = _isStep1Valid && _isStep2Valid && (_currentStep >= 3 || _maxStepReached >= 3);
            } else if (stepBefore == 3) {
              isConnectorCompleted = _isStep1Valid && _isStep2Valid && _isStep3Valid && (_currentStep >= 4 || _maxStepReached >= 4);
            } else if (stepBefore == 4) {
              isConnectorCompleted = _isStep1Valid && _isStep2Valid && _isStep3Valid && _isStep4Valid && (_currentStep >= 5 || _maxStepReached >= 5);
            } else if (stepBefore == 5) {
              isConnectorCompleted = _isStep1Valid && _isStep2Valid && _isStep3Valid && _isStep4Valid && _isStep5Valid && (_currentStep >= 6 || _maxStepReached >= 6);
            }

            return Container(
              width: 50,
              height: 2,
              margin: const EdgeInsets.only(top: 12, left: 10, right: 10),
              color: isConnectorCompleted ? const Color(0xFF004385) : const Color(0xFFE2E8F0),
            );
          }

          final stepNum = (index ~/ 2) + 1;
          final isActive = _currentStep == stepNum;
          final isCompleted = _isStepCompleted(stepNum);
          final canJump = _canJumpToStep(stepNum);
          final showCheckmark = isCompleted && !isActive;

          return MouseRegion(
            cursor: canJump ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: InkWell(
              onTap: canJump
                  ? () => setState(() {
                      if (stepNum > _maxStepReached) {
                        _maxStepReached = stepNum;
                      }
                      _currentStep = stepNum;
                    })
                  : null,
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 105,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isCompleted
                            ? const Color(0xFF004385)
                            : (canJump ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1)),
                      ),
                      child: Center(
                        child: showCheckmark
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                '$stepNum',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      visibleTitles[stepNum - 1],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF004385)
                            : (isCompleted || canJump
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    if (_currentStep == 0) return _buildStep0SelfOrOthers();
    if (_currentStep == 1) return _buildStep1UserType();
    if (_currentStep == 2) return (_isGroup == true) ? _buildStep2GroupVisitorInfo() : _buildStep2SingleVisitorInfo();
    if (_currentStep == 3) return _buildStep3PurposeVisit();
    if (_currentStep == 4) return _buildStep4VehicleInfo();
    if (_currentStep == 5) return _buildStep5SelfieImage();
    if (_currentStep == 6) return _buildStep6KtpImage();
    return const SizedBox();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 0: Self vs Others Screen
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep0SelfOrOthers() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFCBD5E1),
            ),
            child: Center(
              child: Text(
                '1',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'User Type',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 28),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you filling this invitation for yourself or someone else?',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F2B48),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select whether you are creating the invitation for yourself or for someone else.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildSelfOthersCard(
                        keyName: 'self',
                        title: 'Self',
                        subtitle: 'Use this option if you are registering yourself.',
                        isSelected: _invitationTarget == 'self',
                        onTap: () => setState(() => _invitationTarget = 'self'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSelfOthersCard(
                        keyName: 'others',
                        title: 'Others',
                        subtitle: 'Use this option if you are creating an invitation for someone else.',
                        isSelected: _invitationTarget == 'others',
                        onTap: () => setState(() => _invitationTarget = 'others'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfOthersCard({
    required String keyName,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF004385) : const Color(0xFFCBD5E1),
              width: isSelected ? 1.8 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF004385).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF004385) : const Color(0xFF94A3B8),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF004385),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F2B48),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: User Type
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1UserType() {
    final List<Map<String, dynamic>> visitorTypes = controller.rxPraRegVisitorTypes.isNotEmpty
        ? controller.rxPraRegVisitorTypes
        : [
            {'name': 'All Access (VIP)', 'id': '29b12a27-cff3-44dc-be0f-4a743510b836'},
            {'name': 'CIT', 'id': '0eac503e-d0c9-4ba5-afac-99a0b94e44f3'},
            {'name': 'General Visitor', 'id': '1e7ab7a0-1fdd-4546-b65f-6a8dcc345148'},
            {'name': 'Non Remise', 'id': '3e903b97-bb4a-42bb-a840-b2316202ea7d'},
            {'name': 'Remise', 'id': 'f0bd33a4-427a-4110-ab19-6e423dafa3e5'},
            {'name': 'Staff', 'id': '2e8a7639-84f9-42ab-8096-304c259245db'},
            {'name': 'Umum', 'id': 'e0533de1-52a7-4b47-8e80-79239d8f723d'},
            {'name': 'Utility Maintenance', 'id': 'b3618bd5-b6f0-4329-9cf5-6c853970217d'},
            {'name': 'Visitor Resident', 'id': '4bd22555-12fc-4aea-84a3-2163fe7dadc7'},
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Visitor Type', isRequired: true),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: visitorTypes.map((type) {
              final isSelected = _selectedVisitorType != null &&
                  _selectedVisitorType!['id'] == type['id'];
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _onVisitorTypeSelected(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF004385) : const Color(0xFFCBD5E1),
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isSelected ? const Color(0xFF004385) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type['name']?.toString() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF004385) : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          _buildSectionHeader('Select Status Visitor', isRequired: true),
          const SizedBox(height: 4),
          Text(
            'Is this visit for one or more than one visitor?',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildStatusVisitorCard(
                  title: 'Single',
                  subtitle: 'Only one visitor.',
                  icon: Icons.person_outline_rounded,
                  isSelected: _isGroup == false,
                  onTap: () => setState(() => _isGroup = false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusVisitorCard(
                  title: 'Group',
                  subtitle: 'More than one visitor.',
                  icon: Icons.group_outlined,
                  isSelected: _isGroup == true,
                  onTap: () => setState(() => _isGroup = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusVisitorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF004385) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF004385) : const Color(0xFFF1F5F9),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected ? const Color(0xFF004385) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Single Visitor Mode (Purely Dynamic from /visitor-type/{id})
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2SingleVisitorInfo() {
    final fields = _getVisitorInfoPraFormFields();
    final employees = controller.rxPraRegEmployees;
    final visitors = controller.rxPraRegVisitors;
    final searchList = _singleIsEmployee == true ? employees : visitors;
    final searchQuery = _singleSearchCtrl.text.trim().toLowerCase();

    final filtered = searchList.where((it) {
      if (searchQuery.isEmpty) return true;
      final name = (it['name'] ?? it['visitor_name'] ?? '').toString().toLowerCase();
      final email = (it['email'] ?? '').toString().toLowerCase();
      final phone = (it['phone'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) ||
          email.contains(searchQuery) ||
          phone.contains(searchQuery);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Search Bar (Search Employee / Search Visitor with instant autofill)
          _buildSearchInput(
            hint: _singleIsEmployee == true ? 'Search Employee' : 'Search Visitor',
            controller: _singleSearchCtrl,
            isSearchOpen: _singleIsSearchOpen,
            selectedData: _singleSelectedData,
            filteredItems: filtered,
            isEmployeeMode: _singleIsEmployee == true,
            onTap: () => setState(() => _singleIsSearchOpen = true),
            onToggleOpen: () => setState(() => _singleIsSearchOpen = !_singleIsSearchOpen),
            onChanged: (val) => setState(() => _singleIsSearchOpen = true),
            onClear: _clearSingle,
            onSelect: _onSingleSelect,
          ),

          const SizedBox(height: 18),

          // Dynamic fields according to /visitor-type/{id} configuration
          ...fields.map((f) {
            final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
            var label = (f['long_display_text'] ?? f['short_name'] ?? '').toString();
            final isMandatory = f['mandatory'] == true;

            if (remarks == 'is_employee') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormFieldLabel(label.isNotEmpty ? label : 'Are you Employee?', isRequired: isMandatory),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRadioOption(
                          label: 'Yes',
                          isSelected: _singleIsEmployee == true,
                          onTap: () {
                            setState(() {
                              if (_singleIsEmployee == true) {
                                _singleIsEmployee = false;
                              } else {
                                _singleIsEmployee = true;
                              }
                              _clearSingle();
                            });
                          },
                        ),
                        const SizedBox(width: 24),
                        _buildRadioOption(
                          label: 'No',
                          isSelected: _singleIsEmployee == false,
                          onTap: () {
                            setState(() {
                              if (_singleIsEmployee == false) {
                                _singleIsEmployee = false;
                              } else {
                                _singleIsEmployee = false;
                              }
                              _clearSingle();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            if (remarks == 'employee') {
              return const SizedBox.shrink(); // Handled by top search bar
            }

            if (remarks == 'visitor_role' || remarks == 'role') {
              final roles = _getRolesForSelectedType();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormFieldLabel(label.isNotEmpty ? label : 'Role', isRequired: isMandatory),
                    const SizedBox(height: 6),
                    _buildCleanDropdownField<String>(
                      hint: 'Select ${label.isNotEmpty ? label : 'Role'}',
                      selectedValue: _singleRole,
                      items: roles.map((r) {
                        return DropdownMenuItemData<String>(value: r, label: r);
                      }).toList(),
                      onSelected: (val) => setState(() => _singleRole = val),
                    ),
                  ],
                ),
              );
            }

            if (remarks == 'organization' || remarks == 'company' || label.toLowerCase().contains('inst')) {
              label = 'Department / Organization / Company';
            }

            TextEditingController targetCtrl;
            String hintText;

            if (remarks == 'name') {
              targetCtrl = _singleFullNameCtrl;
              hintText = 'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'full name'}';
            } else if (remarks == 'email') {
              targetCtrl = _singleEmailCtrl;
              hintText = 'Example: name@gmail.com';
            } else if (remarks == 'organization' || remarks == 'company') {
              targetCtrl = _singleOrgCtrl;
              hintText = 'Enter your department / organization / company';
            } else if (remarks == 'phone') {
              targetCtrl = _singlePhoneCtrl;
              hintText = 'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'phone'}';
            } else if (remarks == 'indentity_id' || remarks == 'identity_id') {
              targetCtrl = _singleIdentityCtrl;
              hintText = 'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'identity (ktp)'}';
            } else {
              _singleExtraControllers.putIfAbsent(remarks, () => TextEditingController());
              targetCtrl = _singleExtraControllers[remarks]!;
              hintText = 'Enter your ${label.isNotEmpty ? label.toLowerCase() : remarks}';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(label, isRequired: isMandatory),
                  const SizedBox(height: 6),
                  _buildTextInputField(
                    controller: targetCtrl,
                    hint: hintText,
                    enabled: !(remarks == 'name' && _singleIsEmployee == true),
                    readOnly: (remarks == 'name' && _singleIsEmployee == true),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Group Visitor Mode (Purely Dynamic from /visitor-type/{id})
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2GroupVisitorInfo() {
    final fields = _getVisitorInfoPraFormFields();
    final employees = controller.rxPraRegEmployees;
    final visitors = controller.rxPraRegVisitors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormFieldLabel('Group Name', isRequired: true),
                      const SizedBox(height: 6),
                      _buildTextInputField(
                        controller: _groupNameController,
                        hint: 'Enter Group Name',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Code',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _groupCode,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF004385),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Visitor Members (${_groupVisitors.length})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004385),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _addGroupVisitor,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Add Visitor',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groupVisitors.length,
            separatorBuilder: (context, idx) => const SizedBox(height: 14),
            itemBuilder: (context, idx) {
              final visitor = _groupVisitors[idx];
              final searchList = visitor.isEmployee == true ? employees : visitors;
              final searchQuery = visitor.searchCtrl.text.trim().toLowerCase();
              final filtered = searchList.where((it) {
                if (searchQuery.isEmpty) return true;
                final name = (it['name'] ?? it['visitor_name'] ?? '').toString().toLowerCase();
                final email = (it['email'] ?? '').toString().toLowerCase();
                final phone = (it['phone'] ?? '').toString().toLowerCase();
                return name.contains(searchQuery) ||
                    email.contains(searchQuery) ||
                    phone.contains(searchQuery);
              }).toList();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF004385),
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Visitor ${idx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        if (_groupVisitors.length > 1)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                            onPressed: () => _removeGroupVisitor(idx),
                          ),
                      ],
                    ),

                    const Divider(height: 16, color: Color(0xFFF1F5F9)),

                    // Search Bar
                    _buildSearchInput(
                      hint: visitor.isEmployee == true ? 'Search Employee' : 'Search Visitor',
                      controller: visitor.searchCtrl,
                      isSearchOpen: visitor.isSearchOpen,
                      selectedData: visitor.selectedData,
                      filteredItems: filtered,
                      isEmployeeMode: visitor.isEmployee == true,
                      onTap: () => setState(() => visitor.isSearchOpen = true),
                      onToggleOpen: () => setState(() => visitor.isSearchOpen = !visitor.isSearchOpen),
                      onChanged: (val) => setState(() => visitor.isSearchOpen = true),
                      onClear: () => _clearGroup(idx),
                      onSelect: (item) => _onGroupSelect(idx, item),
                    ),

                    const SizedBox(height: 12),

                    ...fields.map((f) {
                      final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
                      var label = (f['long_display_text'] ?? f['short_name'] ?? '').toString();
                      final isMandatory = f['mandatory'] == true;

                      if (remarks == 'is_employee') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormFieldLabel(label.isNotEmpty ? label : 'Are you Employee?', isRequired: isMandatory),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildRadioOption(
                                    label: 'Yes',
                                    isSelected: visitor.isEmployee == true,
                                    onTap: () {
                                      setState(() {
                                        if (visitor.isEmployee == true) {
                                          visitor.isEmployee = null;
                                        } else {
                                          visitor.isEmployee = true;
                                        }
                                        _clearGroup(idx);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 24),
                                  _buildRadioOption(
                                    label: 'No',
                                    isSelected: visitor.isEmployee == false,
                                    onTap: () {
                                      setState(() {
                                        if (visitor.isEmployee == false) {
                                          visitor.isEmployee = null;
                                        } else {
                                          visitor.isEmployee = false;
                                        }
                                        _clearGroup(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      if (remarks == 'employee') {
                        return const SizedBox.shrink();
                      }

                      if (remarks == 'visitor_role' || remarks == 'role') {
                        final roles = _getRolesForSelectedType();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormFieldLabel(label.isNotEmpty ? label : 'Role', isRequired: isMandatory),
                              const SizedBox(height: 6),
                              _buildCleanDropdownField<String>(
                                hint: 'Select ${label.isNotEmpty ? label : 'Role'}',
                                selectedValue: visitor.role,
                                items: roles.map((r) {
                                  return DropdownMenuItemData<String>(value: r, label: r);
                                }).toList(),
                                onSelected: (val) => setState(() => visitor.role = val),
                              ),
                            ],
                          ),
                        );
                      }

                      if (remarks == 'organization' || remarks == 'company' || label.toLowerCase().contains('inst')) {
                        label = 'Department / Organization / Company';
                      }

                      TextEditingController targetCtrl;
                      String hintText;

                      if (remarks == 'name') {
                        targetCtrl = visitor.fullNameCtrl;
                        hintText = 'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'full name'}';
                      } else if (remarks == 'email') {
                        targetCtrl = visitor.emailCtrl;
                        hintText = 'Example: name@gmail.com';
                      } else if (remarks == 'organization' || remarks == 'company') {
                        targetCtrl = visitor.orgCtrl;
                        hintText = 'Enter your department / organization / company';
                      } else if (remarks == 'phone') {
                        targetCtrl = visitor.phoneCtrl;
                        hintText = 'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'phone'}';
                      } else if (remarks == 'indentity_id' || remarks == 'identity_id') {
                        targetCtrl = visitor.identityCtrl;
                        hintText = 'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'identity (ktp)'}';
                      } else {
                        visitor.extraControllers.putIfAbsent(remarks, () => TextEditingController());
                        targetCtrl = visitor.extraControllers[remarks]!;
                        hintText = 'Enter your ${label.isNotEmpty ? label.toLowerCase() : remarks}';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormFieldLabel(label, isRequired: isMandatory),
                            const SizedBox(height: 6),
                            _buildTextInputField(
                              controller: targetCtrl,
                              hint: hintText,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3: Purpose Visit (Purely Dynamic from /visitor-type/{id})
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep3PurposeVisit() {
    final purposeFields = _getPurposeVisitPraFormFields();
    final sites = controller.rxPraRegSites;
    final hosts = controller.rxPraRegHosts.isNotEmpty
        ? controller.rxPraRegHosts
        : controller.rxPraRegEmployees;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: purposeFields.map((f) {
          final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
          final label = (f['long_display_text'] ?? f['short_name'] ?? '').toString();
          final isMandatory = f['mandatory'] == true;

          if (remarks == 'site_place' || remarks == 'destination') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(label.isNotEmpty ? label : 'Destination', isRequired: isMandatory, showInfo: true),
                  const SizedBox(height: 6),
                  _buildCleanDropdownField<Map<String, dynamic>>(
                    hint: 'Select Site or type at least 3 characters to search',
                    selectedValue: _selectedDestination,
                    items: sites.map((s) {
                      return DropdownMenuItemData<Map<String, dynamic>>(
                        value: s,
                        label: s['name']?.toString() ?? 'Site',
                      );
                    }).toList(),
                    onSelected: (val) => setState(() => _selectedDestination = val),
                  ),
                ],
              ),
            );
          }

          if (remarks == 'host') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(label.isNotEmpty ? label : 'PIC Host', isRequired: isMandatory, showInfo: true),
                  const SizedBox(height: 6),
                  _buildCleanDropdownField<Map<String, dynamic>>(
                    hint: 'Select PIC Host or type at least 3 characters to search',
                    selectedValue: _selectedPicHost,
                    items: hosts.map((e) {
                      final eName = (e['name'] ?? 'Host').toString();
                      String orgName = '';
                      final rawOrg = e['Organization'] ?? e['organization'];
                      if (rawOrg is Map) {
                        orgName = (rawOrg['name'] ?? rawOrg['code'] ?? '').toString();
                      } else if (rawOrg is String && !rawOrg.startsWith('{')) {
                        orgName = rawOrg;
                      } else if (e['organization_name'] != null) {
                        orgName = e['organization_name'].toString();
                      }
                      final itemLabel = orgName.isNotEmpty ? '$eName ($orgName)' : eName;
                      return DropdownMenuItemData<Map<String, dynamic>>(value: e, label: itemLabel);
                    }).toList(),
                    onSelected: (val) => setState(() => _selectedPicHost = val),
                  ),
                ],
              ),
            );
          }

          if (remarks == 'agenda') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(label.isNotEmpty ? label : 'Agenda', isRequired: isMandatory, showInfo: true),
                  const SizedBox(height: 6),
                  _buildCleanDropdownField<String>(
                    hint: 'Select agenda',
                    selectedValue: _selectedAgenda,
                    items: _agendaOptions.map((agenda) {
                      return DropdownMenuItemData<String>(value: agenda, label: agenda);
                    }).toList(),
                    onSelected: (val) => setState(() => _selectedAgenda = val),
                  ),
                  if (_selectedAgenda == 'Others') ...[
                    const SizedBox(height: 8),
                    _buildTextInputField(
                      controller: _otherAgendaController,
                      hint: 'Please specify agenda',
                    ),
                  ],
                ],
              ),
            );
          }

          if (remarks == 'visitor_period_start') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(label.isNotEmpty ? label : 'Visit Start', isRequired: isMandatory, showInfo: true),
                  const SizedBox(height: 6),
                  _buildDateTimePickerField(
                    value: _visitStart,
                    title: 'Select Visit Start',
                    onChanged: (dt) {
                      setState(() {
                        _visitStart = dt;
                        if (_visitEnd != null && (_visitEnd!.isBefore(dt) || _visitEnd!.isAtSameMomentAs(dt))) {
                          _visitEnd = dt.add(const Duration(hours: 2));
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          }

          if (remarks == 'visitor_period_end') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(label.isNotEmpty ? label : 'Visit End', isRequired: isMandatory, showInfo: true),
                  const SizedBox(height: 6),
                  _buildDateTimePickerField(
                    value: _visitEnd,
                    minDateTime: _visitStart,
                    title: 'Select Visit End',
                    showNowButton: false,
                    onChanged: (dt) => setState(() => _visitEnd = dt),
                  ),
                ],
              ),
            );
          }

          final ctrl = _purposeExtraControllers.putIfAbsent(remarks, () => TextEditingController());
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormFieldLabel(label, isRequired: isMandatory),
                const SizedBox(height: 6),
                _buildTextInputField(
                  controller: ctrl,
                  hint: 'Enter $label',
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 4: Vehicle / Parking Information
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep4VehicleInfo() {
    if (_isGroup == true) {
      return _buildGroupVehicleInfoContent();
    }
    return _buildSingleVehicleInfoContent();
  }

  Widget _buildSingleVehicleInfoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormFieldLabel('Are you driving or riding a vehicle?', isRequired: false),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRadioOption(
                label: 'Driving',
                isSelected: _singleIsDriving == true,
                onTap: () => setState(() => _singleIsDriving = true),
              ),
              const SizedBox(width: 24),
              _buildRadioOption(
                label: 'No Vehicle',
                isSelected: _singleIsDriving == false,
                onTap: () => setState(() {
                  _singleIsDriving = false;
                  _singleVehicleType = null;
                  _singleVehiclePlateCtrl.clear();
                }),
              ),
            ],
          ),

          if (_singleIsDriving) ...[
            const SizedBox(height: 20),
            _buildFormFieldLabel('Vehicle Type', isRequired: true),
            const SizedBox(height: 6),
            _buildCleanDropdownField<String>(
              hint: 'Select Vehicle Type',
              selectedValue: _singleVehicleType,
              items: _getVehicleTypeOptions(),
              onSelected: (val) {
                setState(() {
                  _singleVehicleType = val;
                  if (_isBicycle(val)) {
                    _singleVehiclePlateCtrl.clear();
                  }
                });
              },
            ),
            if (!_isBicycle(_singleVehicleType)) ...[
              const SizedBox(height: 16),
              _buildFormFieldLabel('Vehicle License Plate', isRequired: true),
              const SizedBox(height: 6),
              _buildTextInputField(
                controller: _singleVehiclePlateCtrl,
                hint: 'e.g. B 1234 XYZ',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGroupVehicleInfoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information for Group Members',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groupVisitors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, idx) {
              final v = _groupVisitors[idx];
              final name = v.fullNameCtrl.text.trim().isNotEmpty
                  ? v.fullNameCtrl.text.trim()
                  : 'Visitor ${idx + 1}';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF004385),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRadioOption(
                          label: 'Driving',
                          isSelected: v.isDriving == true,
                          onTap: () => setState(() => v.isDriving = true),
                        ),
                        const SizedBox(width: 20),
                        _buildRadioOption(
                          label: 'No Vehicle',
                          isSelected: v.isDriving == false,
                          onTap: () => setState(() {
                            v.isDriving = false;
                            v.vehicleType = null;
                            v.vehiclePlateCtrl.clear();
                          }),
                        ),
                      ],
                    ),
                    if (v.isDriving) ...[
                      const SizedBox(height: 12),
                      _buildFormFieldLabel('Vehicle Type', isRequired: true),
                      const SizedBox(height: 6),
                      _buildCleanDropdownField<String>(
                        hint: 'Select Vehicle Type',
                        selectedValue: v.vehicleType,
                        items: _getVehicleTypeOptions(),
                        onSelected: (val) {
                          setState(() {
                            v.vehicleType = val;
                            if (_isBicycle(val)) {
                              v.vehiclePlateCtrl.clear();
                            }
                          });
                        },
                      ),
                      if (!_isBicycle(v.vehicleType)) ...[
                        const SizedBox(height: 10),
                        _buildFormFieldLabel('Vehicle License Plate', isRequired: true),
                        const SizedBox(height: 6),
                        _buildTextInputField(
                          controller: v.vehiclePlateCtrl,
                          hint: 'License Plate (e.g. B 1234 XYZ)',
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 5 & 6: Selfie Image & KTP Upload (Upload & Camera with 5MB validation)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep5SelfieImage() {
    if (_isGroup == true) {
      return _buildGroupImageUploadStep(isKtp: false);
    }
    return _buildSingleImageUploadStep(
      isKtp: false,
      title: 'Selfie Image',
      image: _singleSelfieImage,
    );
  }

  Widget _buildStep6KtpImage() {
    if (_isGroup == true) {
      return _buildGroupImageUploadStep(isKtp: true);
    }
    return _buildSingleImageUploadStep(
      isKtp: true,
      title: 'Upload Identity (KTP)',
      image: _singleKtpImage,
    );
  }

  Widget _buildSingleImageUploadStep({
    required bool isKtp,
    required String title,
    required UploadedFileData? image,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormFieldLabel(title, isRequired: false),
          const SizedBox(height: 14),

          if (image == null)
            _buildUploadCard(
              isKtp: isKtp,
              onTapGallery: () => _pickImageFile(isKtp: isKtp, isGroupMember: false),
              onTapCamera: () => _captureImageFromCamera(isKtp: isKtp, isGroupMember: false),
            )
          else
            _buildImagePreviewCard(
              image: image,
              onRemove: () => _removeUploadedImage(isKtp: isKtp, isGroupMember: false),
              onReUpload: () => _pickImageFile(isKtp: isKtp, isGroupMember: false),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupImageUploadStep({required bool isKtp}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormFieldLabel(isKtp ? 'Upload Identity (KTP) for Group' : 'Selfie Image for Group', isRequired: false),
          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_groupVisitors.length, (idx) {
                final v = _groupVisitors[idx];
                final name = v.fullNameCtrl.text.trim().isNotEmpty ? v.fullNameCtrl.text.trim() : 'Visitor ${idx + 1}';
                final isSelected = _selectedGroupMemberIndex == idx;
                final hasImage = (isKtp ? v.ktpImage : v.selfieImage) != null;

                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedGroupMemberIndex = idx),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF004385) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF004385) : const Color(0xFFCBD5E1),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF004385).withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasImage
                                ? Icons.check_circle_rounded
                                : (isSelected ? Icons.person_rounded : Icons.person_outline_rounded),
                            size: 16,
                            color: hasImage
                                ? const Color(0xFF10B981)
                                : (isSelected ? Colors.white : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedGroupMemberIndex < _groupVisitors.length) ...[
            Builder(builder: (_) {
              final v = _groupVisitors[_selectedGroupMemberIndex];
              final img = isKtp ? v.ktpImage : v.selfieImage;

              if (img == null) {
                return _buildUploadCard(
                  isKtp: isKtp,
                  onTapGallery: () => _pickImageFile(
                    isKtp: isKtp,
                    isGroupMember: true,
                    groupIndex: _selectedGroupMemberIndex,
                  ),
                  onTapCamera: () => _captureImageFromCamera(
                    isKtp: isKtp,
                    isGroupMember: true,
                    groupIndex: _selectedGroupMemberIndex,
                  ),
                );
              }
              return _buildImagePreviewCard(
                image: img,
                onRemove: () => _removeUploadedImage(
                  isKtp: isKtp,
                  isGroupMember: true,
                  groupIndex: _selectedGroupMemberIndex,
                ),
                onReUpload: () => _pickImageFile(
                  isKtp: isKtp,
                  isGroupMember: true,
                  groupIndex: _selectedGroupMemberIndex,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required bool isKtp,
    required VoidCallback onTapGallery,
    required VoidCallback onTapCamera,
  }) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF90CAF9),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapGallery,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE3F2FD),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 26,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload File',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F2B48),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Drag and drop or tap to select file.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Supports: JPG, PNG, JPEG, Up to 5Mb',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onTapCamera,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF004385)),
                          const SizedBox(width: 4),
                          Text(
                            'Use Camera',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF004385),
                            ),
                          ),
                        ],
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

  Widget _buildImagePreviewCard({
    required UploadedFileData image,
    required VoidCallback onRemove,
    required VoidCallback onReUpload,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF004385), width: 1.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 90,
              height: 90,
              child: image.bytes != null
                  ? Image.memory(image.bytes!, fit: BoxFit.cover)
                  : (image.localPath != null && !kIsWeb
                      ? Image.file(File(image.localPath!), fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, size: 40))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.name,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F2B48),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        image.extension.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF0284C7)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      image.sizeFormatted,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onReUpload,
            icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF004385)),
            label: Text('Replace', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF004385))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF004385)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  bool _isSubmitting = false;

  String _getDefaultVisitorRole() {
    final rolesRaw = (_visitorTypeDetail?['visitor_roles'] ??
        _selectedVisitorType?['visitor_roles']) as List<dynamic>?;
    if (rolesRaw != null && rolesRaw.isNotEmpty) {
      final defaultRole = rolesRaw.firstWhereOrNull((r) => r['is_default'] == true);
      if (defaultRole != null && defaultRole['role'] != null) {
        return defaultRole['role'].toString();
      }
      final firstRole = rolesRaw.first['role'];
      if (firstRole != null) return firstRole.toString();
    }
    return 'Visitor';
  }

  Future<List<Map<String, dynamic>>> _buildDynamicQuestionPage({
    required String name,
    required String email,
    required String phone,
    required String org,
    required String identity,
    required bool isEmployee,
    required String? role,
    required String employeeId,
    required Map<String, TextEditingController> extraCtrls,
    required String hostId,
    required String agenda,
    required String siteId,
    required DateTime? start,
    required DateTime? end,
    required bool isDriving,
    required String? vehicleType,
    required String vehiclePlate,
    required UploadedFileData? selfieImage,
    required UploadedFileData? ktpImage,
  }) async {
    final startIso = start?.toUtc().toIso8601String();
    final endIso = end?.toUtc().toIso8601String();

    // Upload Selfie Image to CDN if present
    String? uploadedSelfiePath;
    if (selfieImage != null && selfieImage.bytes != null) {
      debugPrint('==> Uploading Selfie Image (${selfieImage.name}, ${selfieImage.bytes!.length} bytes)...');
      uploadedSelfiePath = await controller.uploadCdnFile(
        selfieImage.bytes!,
        selfieImage.name,
        path: 'face',
      );
      debugPrint('==> Uploaded Selfie Result: $uploadedSelfiePath');
    }

    // Upload KTP Image to CDN if present
    String? uploadedKtpPath;
    if (ktpImage != null && ktpImage.bytes != null) {
      debugPrint('==> Uploading KTP Image (${ktpImage.name}, ${ktpImage.bytes!.length} bytes)...');
      uploadedKtpPath = await controller.uploadCdnFile(
        ktpImage.bytes!,
        ktpImage.name,
        path: 'face',
      );
      debugPrint('==> Uploaded KTP Result: $uploadedKtpPath');
    }

    final sectionsRaw = _visitorTypeDetail?['section_page_visitor_types'] as List<dynamic>?;

    if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
      final List<Map<String, dynamic>> questionPages = [];

      for (var s in sectionsRaw) {
        final sec = Map<String, dynamic>.from(s as Map);
        final secId = sec['id']?.toString() ?? '';
        final secSort = sec['sort'] ?? 0;
        final secName = sec['name']?.toString() ?? '';
        final secStatus = sec['status'] ?? 0;
        final isDoc = sec['is_document'] == true;
        final canMulti = sec['can_multiple_used'] ?? false;
        final selfOnly = sec['self_only'] ?? false;
        final foreignId = sec['foreign_id']?.toString() ?? '';

        final formListRaw = (sec['visit_form'] as List<dynamic>?) ??
            (sec['pra_form'] as List<dynamic>?) ??
            (sec['form'] as List<dynamic>?) ??
            [];

        final List<Map<String, dynamic>> builtFormList = [];

        for (var f in formListRaw) {
          final field = Map<String, dynamic>.from(f as Map);
          final remarks = (field['remarks'] ?? '').toString().toLowerCase().trim();
          final fieldType = field['field_type'] ?? 0;
          final customFieldId = field['custom_field_id']?.toString() ?? '';
          final shortName = field['short_name']?.toString() ?? '';
          final longText = field['long_display_text']?.toString() ?? '';
          final isPrimary = field['is_primary'] ?? false;
          final isEnable = field['is_enable'] ?? true;
          final mandatory = field['mandatory'] ?? false;
          final multiOpts = field['multiple_option_fields'] ?? [];
          final vFormType = field['visitor_form_type'] ?? 1;

          Map<String, dynamic> formItem = {
            'sort': field['sort'] ?? builtFormList.length,
            'short_name': shortName,
            'long_display_text': longText,
            'field_type': fieldType,
            'is_primary': isPrimary,
            'is_enable': isEnable,
            'mandatory': mandatory,
            'remarks': remarks,
            if (customFieldId.isNotEmpty) 'custom_field_id': customFieldId,
            'multiple_option_fields': multiOpts,
            'visitor_form_type': vFormType,
          };

          if (isDoc || fieldType == 10 || fieldType == 12 || fieldType == 11) {
            // Document section (Selfie / KTP)
            if (remarks.contains('selfie') || fieldType == 10) {
              formItem['answer_file'] = uploadedSelfiePath;
            } else if (remarks.contains('identity') || remarks.contains('ktp') || fieldType == 12) {
              formItem['answer_file'] = uploadedKtpPath;
            } else {
              formItem['answer_file'] = null;
            }
          } else if (fieldType == 9) {
            // Date Time fields
            if (remarks == 'visitor_period_start') {
              formItem['answer_datetime'] = startIso;
            } else if (remarks == 'visitor_period_end') {
              formItem['answer_datetime'] = endIso;
            } else {
              formItem['answer_datetime'] = null;
            }
          } else {
            // Text / Dropdown / Radio fields
            if (remarks == 'name') {
              formItem['answer_text'] = name;
            } else if (remarks == 'email') {
              formItem['answer_text'] = email;
            } else if (remarks == 'phone') {
              formItem['answer_text'] = phone;
            } else if (remarks == 'organization' || remarks == 'company') {
              formItem['answer_text'] = org;
            } else if (remarks == 'identity_id' || remarks == 'indentity_id') {
              formItem['answer_text'] = identity;
            } else if (remarks == 'is_employee') {
              formItem['answer_text'] = isEmployee ? 'true' : 'false';
            } else if (remarks == 'employee') {
              formItem['answer_text'] = employeeId;
            } else if (remarks == 'visitor_role' || remarks == 'role') {
              formItem['answer_text'] = role ?? '';
            } else if (remarks == 'site_place' || remarks == 'destination') {
              formItem['answer_text'] = siteId;
            } else if (remarks == 'host' || remarks == 'pic_host') {
              formItem['answer_text'] = hostId;
            } else if (remarks == 'agenda') {
              formItem['answer_text'] = agenda;
            } else if (remarks == 'is_driving') {
              formItem['answer_text'] = isDriving ? 'true' : 'false';
            } else if (remarks == 'vehicle_type') {
              formItem['answer_text'] = isDriving ? (vehicleType?.isNotEmpty == true ? vehicleType : null) : null;
            } else if (remarks == 'vehicle_plate') {
              formItem['answer_text'] = (!isDriving || _isBicycle(vehicleType))
                  ? null
                  : (vehiclePlate.trim().isNotEmpty ? vehiclePlate.trim() : null);
            } else {
              formItem['answer_text'] = extraCtrls[remarks]?.text.trim() ?? '';
            }
          }

          builtFormList.add(formItem);
        }

        questionPages.add({
          if (secId.isNotEmpty) 'id': secId,
          'sort': secSort,
          'name': secName,
          'status': secStatus,
          'is_document': isDoc,
          'can_multiple_used': canMulti,
          'self_only': selfOnly,
          'foreign_id': foreignId,
          'form': builtFormList,
        });
      }

      return questionPages;
    }

    // Fallback standard structure matching user schema
    return [
      {
        'id': '4d3f2e76-e5b9-4943-834c-cdbd87dc4062',
        'sort': 0,
        'name': 'Visitor Information',
        'status': 0,
        'is_document': false,
        'can_multiple_used': false,
        'self_only': false,
        'foreign_id': '',
        'form': [
          {
            'sort': 0,
            'short_name': 'Full Name',
            'long_display_text': 'Fullname',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'name',
            'custom_field_id': 'e953c360-ecfd-4710-90dc-0fab6fb3bfa0',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': name,
          },
          {
            'sort': 1,
            'short_name': 'Email',
            'long_display_text': 'Email',
            'field_type': 2,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'email',
            'custom_field_id': 'd402e40e-cf1a-4a65-8770-f1344f795071',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': email,
          },
          {
            'sort': 2,
            'short_name': 'Phone',
            'long_display_text': 'Phone',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'phone',
            'custom_field_id': '08bf266b-a8f0-408a-8639-97ac35615db1',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': phone,
          },
          {
            'sort': 3,
            'short_name': 'Organization',
            'long_display_text': 'Department / Organization / Company',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'organization',
            'custom_field_id': '7e7a0eee-e2a4-4a9f-85d0-c6dd612b16ac',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': org,
          },
          {
            'sort': 4,
            'short_name': 'Indentity Id',
            'long_display_text': 'Identity Id (KTP)',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'indentity_id',
            'custom_field_id': '7b9cd4b9-f6e0-4438-8088-220c8bafaa3f',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': identity,
          },
        ],
      },
      {
        'id': 'a7859ca6-eae5-44ac-bac2-ad4b97efeb98',
        'sort': 1,
        'name': 'Purpose Visit',
        'status': 0,
        'is_document': false,
        'can_multiple_used': true,
        'self_only': false,
        'foreign_id': '',
        'form': [
          {
            'sort': 0,
            'short_name': 'PIC Host',
            'long_display_text': 'PIC Host',
            'field_type': 3,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'host',
            'custom_field_id': 'c52bc3f6-7ee8-49b6-b980-ca01d9967800',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': hostId,
          },
          {
            'sort': 1,
            'short_name': 'Agenda',
            'long_display_text': 'Agenda',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'agenda',
            'custom_field_id': '179eec7f-c1c1-4bd1-8175-9548ebd7e1ce',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': agenda,
          },
          {
            'sort': 2,
            'short_name': 'Destination',
            'long_display_text': 'Destination',
            'field_type': 3,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'site_place',
            'custom_field_id': '344626ff-f72a-4ae1-83af-f0c8d4441553',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': siteId,
          },
          {
            'sort': 3,
            'short_name': 'Visit Start',
            'long_display_text': 'Visit Start',
            'field_type': 9,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'visitor_period_start',
            'custom_field_id': '770c3fd2-ca8e-47d6-b1a6-54cabfaca83d',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_datetime': startIso,
          },
          {
            'sort': 4,
            'short_name': 'Visit End',
            'long_display_text': 'Visit End',
            'field_type': 9,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'visitor_period_end',
            'custom_field_id': 'cea5edb2-8a71-4532-bc18-e8f06583fdda',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_datetime': endIso,
          },
        ],
      },
      {
        'id': '38bd9858-31eb-4353-8de1-f98c3069ec1a',
        'sort': 2,
        'name': 'Vehicle/Parking Information',
        'status': 0,
        'is_document': false,
        'can_multiple_used': false,
        'self_only': false,
        'foreign_id': '',
        'form': [
          {
            'sort': 0,
            'short_name': 'Is Driving/Riding',
            'long_display_text': 'Are you driving?',
            'field_type': 5,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'is_driving',
            'custom_field_id': '88efa996-9305-480e-ac11-e8263061e569',
            'multiple_option_fields': [
              {'value': 'true', 'name': 'Yes'},
              {'value': 'false', 'name': 'No'},
            ],
            'visitor_form_type': 1,
            'answer_text': isDriving ? 'true' : 'false',
          },
          {
            'sort': 1,
            'short_name': 'Vehicle Type',
            'long_display_text': 'Vehicle Type',
            'field_type': 5,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'vehicle_type',
            'custom_field_id': '6ec27b6a-016e-4aa8-94e7-fa37292bed4a',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': isDriving ? (vehicleType?.isNotEmpty == true ? vehicleType : null) : null,
          },
          {
            'sort': 2,
            'short_name': 'Vehicle Plate',
            'long_display_text': 'Vehicle Plate Number',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'vehicle_plate',
            'custom_field_id': '66f05293-fea2-4948-b871-cf65124b3edc',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': (!isDriving || _isBicycle(vehicleType))
                ? null
                : (vehiclePlate.trim().isNotEmpty ? vehiclePlate.trim() : null),
          },
        ],
      },
      {
        'id': 'fd2c076a-d074-4f88-bc07-ebb8bc027557',
        'sort': 3,
        'name': 'Selfie Image',
        'status': 0,
        'is_document': true,
        'can_multiple_used': false,
        'self_only': false,
        'foreign_id': '33e0ac34-6cc3-4228-88e0-6a7efc873905',
        'form': [
          {
            'sort': 0,
            'short_name': 'Selfie Image',
            'long_display_text': 'Selfie Image',
            'field_type': 10,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'selfie_image',
            'custom_field_id': '9d45c726-64db-4ee9-bd12-0d9bfe2403fc',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_file': uploadedSelfiePath,
          },
        ],
      },
      {
        'id': 'd23296e7-e02d-4e85-9e02-8cb548602e17',
        'sort': 4,
        'name': 'Upload Identity (KTP)',
        'status': 0,
        'is_document': true,
        'can_multiple_used': false,
        'self_only': false,
        'foreign_id': 'f1ac46d5-25c5-40bb-8a9c-1fcae42abc92',
        'form': [
          {
            'sort': 0,
            'short_name': 'Identity Image',
            'long_display_text': 'Upload Identity (KTP)',
            'field_type': 12,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'identity_image',
            'custom_field_id': '44f3d868-7c2e-4d3d-968a-47a17524a89b',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_file': uploadedKtpPath,
          },
        ],
      },
    ];
  }

  Future<void> _handleSubmit() async {
    if (_selectedDestination == null) {
      AppSnackbar.warning(
        title: 'Destination Required',
        message: 'Please select a destination site.',
      );
      return;
    }
    if (_selectedPicHost == null) {
      AppSnackbar.warning(
        title: 'PIC Host Required',
        message: 'Please select a PIC Host.',
      );
      return;
    }
    if (_selectedAgenda == null) {
      AppSnackbar.warning(
        title: 'Agenda Required',
        message: 'Please select a visit agenda.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final visitorTypeId = (_selectedVisitorType?['id'] ?? '').toString();
      final siteId = (_selectedDestination?['id'] ?? '').toString();
      final hostId = (_selectedPicHost?['id'] ?? '').toString();
      final resolvedAgenda = _selectedAgenda == 'Others'
          ? _otherAgendaController.text.trim()
          : _selectedAgenda!;

      _visitorTypeDetail ??= await controller.fetchVisitorTypeDetail(visitorTypeId);
      final resolvedRole = _getDefaultVisitorRole();
      final isSelf = _invitationTarget == 'self';

      Map<String, dynamic> payload;

      if (_isGroup == true) {
        // Group Mode -> POST /api/operator-invitation/new-visit-group
        final List<Map<String, dynamic>> dataVisitors = [];

        final primaryVisitor = _groupVisitors.isNotEmpty ? _groupVisitors.first : null;
        final primaryName = primaryVisitor?.fullNameCtrl.text.trim() ?? '';
        final primaryEmail = primaryVisitor?.emailCtrl.text.trim() ?? '';
        final primaryPhone = primaryVisitor?.phoneCtrl.text.trim() ?? '';

        for (final v in _groupVisitors) {
          final memberEmployeeId = (v.isEmployee == true)
              ? (v.selectedData?['id'] ?? v.selectedData?['employee_id'] ?? '').toString()
              : '';

          final memberQuestionPages = await _buildDynamicQuestionPage(
            name: v.fullNameCtrl.text.trim(),
            email: v.emailCtrl.text.trim(),
            phone: v.phoneCtrl.text.trim(),
            org: v.orgCtrl.text.trim(),
            identity: v.identityCtrl.text.trim(),
            isEmployee: v.isEmployee == true,
            role: v.role,
            employeeId: memberEmployeeId,
            extraCtrls: v.extraControllers,
            hostId: hostId,
            agenda: resolvedAgenda,
            siteId: siteId,
            start: _visitStart,
            end: _visitEnd,
            isDriving: v.isDriving,
            vehicleType: v.vehicleType,
            vehiclePlate: v.vehiclePlateCtrl.text.trim(),
            selfieImage: v.selfieImage,
            ktpImage: v.ktpImage,
          );

          dataVisitors.add({
            'question_page': memberQuestionPages,
          });
        }

        final groupObject = {
          'visitor_type': visitorTypeId,
          'is_group': true,
          'type_registered': 1,
          'tz': 'Asia/Jakarta',
          if (siteId.isNotEmpty) 'registered_site': siteId,
          'group_code': _groupCode,
          'group_name': _groupNameController.text.trim(),
          'is_self_registered': isSelf,
          'filled_by_name': primaryName,
          'filled_by_email': primaryEmail,
          'filled_by_phone': primaryPhone,
          'filled_by_relationship': isSelf ? 'Self' : 'Other',
          'filled_by_relationship_name': isSelf ? 'Self' : 'Other',
          'flow': 'Invitation',
          'visitor_role': _groupVisitors.first.role ?? resolvedRole,
          'data_visitor': dataVisitors,
        };

        payload = {
          'list_group': [groupObject],
        };
      } else {
        // Single Mode -> POST /api/operator-invitation/new-visit
        final singleEmployeeId = (_singleIsEmployee == true)
            ? (_singleSelectedData?['id'] ?? _singleSelectedData?['employee_id'] ?? '').toString()
            : '';

        final singleQuestionPages = await _buildDynamicQuestionPage(
          name: _singleFullNameCtrl.text.trim(),
          email: _singleEmailCtrl.text.trim(),
          phone: _singlePhoneCtrl.text.trim(),
          org: _singleOrgCtrl.text.trim(),
          identity: _singleIdentityCtrl.text.trim(),
          isEmployee: _singleIsEmployee == true,
          role: _singleRole,
          employeeId: singleEmployeeId,
          extraCtrls: _singleExtraControllers,
          hostId: hostId,
          agenda: resolvedAgenda,
          siteId: siteId,
          start: _visitStart,
          end: _visitEnd,
          isDriving: _singleIsDriving,
          vehicleType: _singleVehicleType,
          vehiclePlate: _singleVehiclePlateCtrl.text.trim(),
          selfieImage: _singleSelfieImage,
          ktpImage: _singleKtpImage,
        );

        payload = {
          'visitor_type': visitorTypeId,
          'type_registered': 1,
          'is_group': false,
          'tz': 'Asia/Jakarta',
          if (siteId.isNotEmpty) 'registered_site': siteId,
          'flow': 'Invitation',
          'visitor_role': _singleRole ?? resolvedRole,
          'data_visitor': [
            {'question_page': singleQuestionPages}
          ],
        };
      }

      final success = await controller.submitOperatorWalkInRegistration(
        payload: payload,
        isGroup: _isGroup == true,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Submit Walk In Exception: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      AppSnackbar.error(
        title: 'Submit Failed',
        message: 'An error occurred while submitting: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Footer Navigation Bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final isValid = _isCurrentStepValid && !_isSubmitting;
    final isFinalStep = _currentStep == _maxSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: !_isSubmitting
                ? () {
                    if (_currentStep == 0) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _currentStep--);
                    }
                  }
                : null,
            icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF004385)),
            label: Text(
              'Back',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004385),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? const Color(0xFF004385) : const Color(0xFFE2E8F0),
              foregroundColor: isValid ? Colors.white : const Color(0xFF94A3B8),
              elevation: isValid ? 2 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isValid
                ? () {
                    if (isFinalStep) {
                      _handleSubmit();
                    } else {
                      if (_currentStep + 1 > _maxStepReached) {
                        _maxStepReached = _currentStep + 1;
                      }
                      setState(() => _currentStep++);
                    }
                  }
                : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFinalStep ? 'Submit' : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isValid ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (!isFinalStep) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: isValid ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Helper Widgets (Matching Pra-Register exact design system)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 3),
          Text(
            '*',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormFieldLabel(String label, {bool isRequired = false, bool showInfo = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 3),
          Text(
            '*',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    final isFieldDisabled = !enabled || readOnly;
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        enabled: enabled,
        readOnly: isFieldDisabled,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        onChanged: (val) {
          if (onChanged != null) {
            onChanged(val);
          } else {
            setState(() {});
          }
        },
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isFieldDisabled ? const Color(0xFF64748B) : const Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: isFieldDisabled ? const Color(0xFFF1F5F9) : Colors.white,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isFieldDisabled ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isFieldDisabled ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isFieldDisabled ? const Color(0xFFE2E8F0) : const Color(0xFF004385),
              width: isFieldDisabled ? 1.0 : 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? const Color(0xFF004385) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF004385) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanDropdownField<T>({
    required String hint,
    required T? selectedValue,
    required List<DropdownMenuItemData<T>> items,
    required ValueChanged<T> onSelected,
  }) {
    String displayLabel = hint;
    if (selectedValue != null) {
      final match = items.firstWhereOrNull((it) => it.value == selectedValue);
      if (match != null) {
        displayLabel = match.label;
      }
    }

    final isSet = selectedValue != null;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final result = await _showCleanDropdownPopup<T>(
          context: context,
          title: hint,
          items: items,
          selectedValue: selectedValue,
        );
        if (result != null) {
          onSelected(result);
        }
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                displayLabel,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSet ? FontWeight.w500 : FontWeight.w400,
                  color: isSet ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Future<T?> _showCleanDropdownPopup<T>({
    required BuildContext context,
    required String title,
    required List<DropdownMenuItemData<T>> items,
    required T? selectedValue,
  }) {
    final searchCtrl = TextEditingController();

    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = items.where((it) {
              if (query.isEmpty) return true;
              return it.label.toLowerCase().contains(query);
            }).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 440,
                constraints: const BoxConstraints(maxHeight: 460),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.of(dialogContext).pop(null),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    if (items.length > 5)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) => setPopupState(() {}),
                          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            hintText: 'Type to filter...',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF004385), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: filtered.length,
                        separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF8FAFC)),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final isSelected = item.value == selectedValue;

                          return InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(item.value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected
                                            ? const Color(0xFF004385)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_rounded, size: 18, color: Color(0xFF004385)),
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

  Widget _buildSearchInput({
    required String hint,
    required TextEditingController controller,
    required bool isSearchOpen,
    required Map<String, dynamic>? selectedData,
    required List<Map<String, dynamic>> filteredItems,
    required bool isEmployeeMode,
    required VoidCallback onTap,
    required VoidCallback onToggleOpen,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
    required ValueChanged<Map<String, dynamic>> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onTap: onTap,
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedData != null || controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      tooltip: 'Clear',
                      onPressed: onClear,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  IconButton(
                    icon: Icon(
                      isSearchOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF64748B),
                      size: 22,
                    ),
                    tooltip: isSearchOpen ? 'Collapse list' : 'Expand list',
                    onPressed: onToggleOpen,
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF004385), width: 1.5),
              ),
            ),
          ),
        ),
        if (isSearchOpen && filteredItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filteredItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final it = filteredItems[index];
                final name = (it['name'] ?? it['visitor_name'] ?? 'User').toString();
                final email = (it['email'] ?? '-').toString();
                final phone = (it['phone'] ?? '-').toString();
                final org = _extractOrganizationName(it['Organization'] ?? it['organization'], it['company']);

                return InkWell(
                  onTap: () => onSelect(it),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: Icon(
                            isEmployeeMode ? Icons.badge_outlined : Icons.person_outline,
                            size: 16,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                org.isNotEmpty ? '$email | $phone ($org)' : '$email | $phone',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDateTimePickerField({
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
    DateTime? minDateTime,
    String title = 'Select Date & Time',
    bool showNowButton = true,
  }) {
    final formatted = value != null
        ? _formatDateTime(value)
        : 'EEEE, DD MMMM YYYY, hh:mm';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await _showTabletDateTimePicker(
          context,
          value,
          minDateTime: minDateTime,
          title: title,
          showNowButton: showNowButton,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                formatted,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                  color: value != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final dayStr = dt.day.toString().padLeft(2, '0');
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');

    return '$dayName, $dayStr $monthName ${dt.year}, $hourStr:$minStr';
  }

  DateTime _getGmt7Now() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: 7));
  }

  Future<DateTime?> _showTabletDateTimePicker(
    BuildContext context,
    DateTime? initialDateTime, {
    DateTime? minDateTime,
    String title = 'Select Date & Time',
    bool showNowButton = true,
  }) {
    DateTime liveTime = _getGmt7Now();
    DateTime selectedDate = initialDateTime != null
        ? DateTime(initialDateTime.year, initialDateTime.month, initialDateTime.day)
        : DateTime(liveTime.year, liveTime.month, liveTime.day);

    if (minDateTime != null) {
      final minDate = DateTime(minDateTime.year, minDateTime.month, minDateTime.day);
      if (selectedDate.isBefore(minDate)) {
        selectedDate = minDate;
      }
    }

    int? selectedHour = initialDateTime?.hour;
    int? selectedMinute = initialDateTime?.minute;

    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        final ScrollController hourScrollController = ScrollController();
        final ScrollController minuteScrollController = ScrollController();

        bool isSameDayAsMin(DateTime date) {
          if (minDateTime == null) return false;
          return date.year == minDateTime.year &&
              date.month == minDateTime.month &&
              date.day == minDateTime.day;
        }

        if (selectedHour != null && isSameDayAsMin(selectedDate)) {
          if (selectedHour! < minDateTime!.hour) {
            selectedHour = minDateTime.hour;
          }
          if (selectedMinute != null &&
              selectedHour == minDateTime.hour &&
              selectedMinute! <= minDateTime.minute) {
            selectedMinute = minDateTime.minute + 1;
            if (selectedMinute! >= 60) {
              selectedHour = selectedHour! + 1;
              selectedMinute = 0;
            }
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final h = selectedHour;
          final m = selectedMinute;
          if (h != null && hourScrollController.hasClients) {
            final targetH = (h * 38.0) - 92.0;
            hourScrollController.jumpTo(targetH.clamp(0.0, hourScrollController.position.maxScrollExtent));
          } else if (hourScrollController.hasClients) {
            if (minDateTime != null && isSameDayAsMin(selectedDate)) {
              final targetH = minDateTime.hour * 38.0;
              hourScrollController.jumpTo(targetH.clamp(0.0, hourScrollController.position.maxScrollExtent));
            } else {
              hourScrollController.jumpTo(0.0);
            }
          }
          if (m != null && minuteScrollController.hasClients) {
            final targetM = (m * 38.0) - 92.0;
            minuteScrollController.jumpTo(targetM.clamp(0.0, minuteScrollController.position.maxScrollExtent));
          } else if (minuteScrollController.hasClients) {
            minuteScrollController.jumpTo(0.0);
          }
        });

        Timer? tickerTimer;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            tickerTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  liveTime = _getGmt7Now();
                });
              }
            });

            final isSameDay = isSameDayAsMin(selectedDate);
            final hasSelectedTime = selectedHour != null && selectedMinute != null;

            final currentPreview = hasSelectedTime
                ? DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedHour!,
                    selectedMinute!,
                  )
                : null;

            final isSelectionValid = hasSelectedTime &&
                (minDateTime == null || currentPreview!.isAfter(minDateTime));

            final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
            final months = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            final liveDayName = days[liveTime.weekday % 7];
            final liveMonthName = months[liveTime.month - 1];
            final liveHourStr = liveTime.hour.toString().padLeft(2, '0');
            final liveMinStr = liveTime.minute.toString().padLeft(2, '0');
            final liveSecStr = liveTime.second.toString().padLeft(2, '0');
            final liveClockDisplay = '$liveDayName, ${liveTime.day} $liveMonthName ${liveTime.year}, $liveHourStr:$liveMinStr:$liveSecStr';

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: 670,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF004385)),
                          const SizedBox(width: 10),
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF004385)),
                                const SizedBox(width: 6),
                                Text(
                                  liveClockDisplay,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF004385),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 11,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF004385),
                                  onPrimary: Colors.white,
                                  onSurface: Color(0xFF1E293B),
                                ),
                              ),
                              child: CalendarDatePicker(
                                key: ValueKey('${selectedDate.year}-${selectedDate.month}-${selectedDate.day}'),
                                initialDate: selectedDate,
                                firstDate: minDateTime != null
                                    ? DateTime(minDateTime.year, minDateTime.month, minDateTime.day)
                                    : DateTime(2020),
                                lastDate: DateTime(2035),
                                onDateChanged: (newDate) {
                                    setDialogState(() {
                                      selectedDate = newDate;
                                      if (selectedHour != null && isSameDayAsMin(newDate)) {
                                        if (selectedHour! < minDateTime!.hour) {
                                          selectedHour = minDateTime.hour;
                                        }
                                        if (selectedMinute != null &&
                                            selectedHour == minDateTime.hour &&
                                            selectedMinute! <= minDateTime.minute) {
                                          selectedMinute = minDateTime.minute + 1;
                                          if (selectedMinute! >= 60) {
                                            selectedHour = selectedHour! + 1;
                                            selectedMinute = 0;
                                          }
                                        }
                                      }
                                    });
                                    if (selectedHour == null && hourScrollController.hasClients) {
                                      if (minDateTime != null && isSameDayAsMin(newDate)) {
                                        final targetH = minDateTime.hour * 38.0;
                                        hourScrollController.animateTo(targetH.clamp(0.0, hourScrollController.position.maxScrollExtent), duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
                                      } else {
                                        hourScrollController.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
                                      }
                                    }
                                  },
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 290,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            flex: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Selected Time: ',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        hasSelectedTime
                                            ? '${selectedHour.toString().padLeft(2, '0')} : ${selectedMinute.toString().padLeft(2, '0')}'
                                            : '-- : -- (Not selected)',
                                        style: GoogleFonts.inter(
                                          fontSize: hasSelectedTime ? 15 : 12.5,
                                          fontWeight: hasSelectedTime ? FontWeight.w800 : FontWeight.w600,
                                          color: hasSelectedTime ? const Color(0xFF004385) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Hour (24h)',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Minute',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 230,
                                  child: ScrollConfiguration(
                                    behavior: const MaterialScrollBehavior().copyWith(
                                      dragDevices: {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind.mouse,
                                        PointerDeviceKind.trackpad,
                                        PointerDeviceKind.stylus,
                                      },
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: RawScrollbar(
                                              controller: hourScrollController,
                                              thumbVisibility: true,
                                              thickness: 3.5,
                                              radius: const Radius.circular(4),
                                              thumbColor: const Color(0xFF94A3B8),
                                              child: ListView.builder(
                                                controller: hourScrollController,
                                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                                itemCount: 24,
                                                itemBuilder: (ctx, h) {
                                                  final isHourDisabled = isSameDay && h < minDateTime!.hour;
                                                  final isSelected = selectedHour == h;

                                                  return SizedBox(
                                                    height: 38,
                                                    child: Center(
                                                      child: InkWell(
                                                        borderRadius: BorderRadius.circular(6),
                                                        onTap: isHourDisabled
                                                            ? null
                                                            : () {
                                                                setDialogState(() {
                                                                  selectedHour = h;
                                                                  selectedMinute ??= 0;
                                                                  if (isSameDay && h == minDateTime!.hour) {
                                                                    if (selectedMinute! <= minDateTime.minute) {
                                                                      selectedMinute = minDateTime.minute + 1;
                                                                      if (selectedMinute! >= 60) {
                                                                        selectedHour = h + 1;
                                                                        selectedMinute = 0;
                                                                      }
                                                                    }
                                                                  }
                                                                });
                                                                if (hourScrollController.hasClients) {
                                                                  hourScrollController.animateTo(
                                                                    ((h * 38.0) - 92.0).clamp(0.0, hourScrollController.position.maxScrollExtent),
                                                                    duration: const Duration(milliseconds: 250),
                                                                    curve: Curves.easeOutCubic,
                                                                  );
                                                                }
                                                              },
                                                        child: Container(
                                                          width: double.infinity,
                                                          height: 34,
                                                          decoration: BoxDecoration(
                                                            color: isSelected
                                                                ? const Color(0xFF004385)
                                                                : (isHourDisabled
                                                                    ? const Color(0xFFF1F5F9)
                                                                    : Colors.transparent),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          alignment: Alignment.center,
                                                          child: Text(
                                                            h.toString().padLeft(2, '0'),
                                                            style: GoogleFonts.inter(
                                                              fontSize: 13,
                                                              fontWeight: isSelected
                                                                  ? FontWeight.w700
                                                                  : (isHourDisabled
                                                                      ? FontWeight.w400
                                                                      : FontWeight.w600),
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : (isHourDisabled
                                                                      ? const Color(0xFFCBD5E1)
                                                                      : const Color(0xFF1E293B)),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: RawScrollbar(
                                              controller: minuteScrollController,
                                              thumbVisibility: true,
                                              thickness: 3.5,
                                              radius: const Radius.circular(4),
                                              thumbColor: const Color(0xFF94A3B8),
                                              child: ListView.builder(
                                                controller: minuteScrollController,
                                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                                itemCount: 60,
                                                itemBuilder: (ctx, m) {
                                                  final isMinuteDisabled = isSameDay &&
                                                      selectedHour != null &&
                                                      selectedHour == minDateTime!.hour &&
                                                      m <= minDateTime.minute;
                                                  final isSelected = selectedMinute == m;

                                                  return SizedBox(
                                                    height: 38,
                                                    child: Center(
                                                      child: InkWell(
                                                        borderRadius: BorderRadius.circular(6),
                                                        onTap: isMinuteDisabled
                                                            ? null
                                                            : () {
                                                                setDialogState(() {
                                                                  selectedMinute = m;
                                                                  selectedHour ??= isSameDay ? minDateTime!.hour : 9;
                                                                });
                                                                if (minuteScrollController.hasClients) {
                                                                  minuteScrollController.animateTo(
                                                                    ((m * 38.0) - 92.0).clamp(0.0, minuteScrollController.position.maxScrollExtent),
                                                                    duration: const Duration(milliseconds: 250),
                                                                    curve: Curves.easeOutCubic,
                                                                  );
                                                                }
                                                              },
                                                        child: Container(
                                                          width: double.infinity,
                                                          height: 34,
                                                          decoration: BoxDecoration(
                                                            color: isSelected
                                                                ? const Color(0xFF004385)
                                                                : (isMinuteDisabled
                                                                    ? const Color(0xFFF1F5F9)
                                                                    : Colors.transparent),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          alignment: Alignment.center,
                                                          child: Text(
                                                            m.toString().padLeft(2, '0'),
                                                            style: GoogleFonts.inter(
                                                              fontSize: 13,
                                                              fontWeight: isSelected
                                                                  ? FontWeight.w700
                                                                  : (isMinuteDisabled
                                                                      ? FontWeight.w400
                                                                      : FontWeight.w600),
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : (isMinuteDisabled
                                                                      ? const Color(0xFFCBD5E1)
                                                                      : const Color(0xFF1E293B)),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          if (showNowButton)
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                foregroundColor: const Color(0xFF004385),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                final nowGmt7 = _getGmt7Now();
                                final targetHour = nowGmt7.hour;
                                final targetMinute = nowGmt7.minute;

                                setDialogState(() {
                                  selectedDate = DateTime(nowGmt7.year, nowGmt7.month, nowGmt7.day);
                                  selectedHour = targetHour;
                                  selectedMinute = targetMinute;
                                });

                                if (hourScrollController.hasClients) {
                                  final targetH = (targetHour * 38.0) - 92.0;
                                  hourScrollController.animateTo(
                                    targetH.clamp(0.0, hourScrollController.position.maxScrollExtent),
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                                if (minuteScrollController.hasClients) {
                                  final targetM = (targetMinute * 38.0) - 92.0;
                                  minuteScrollController.animateTo(
                                    targetM.clamp(0.0, minuteScrollController.position.maxScrollExtent),
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                              child: Text(
                                'Today',
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () {
                              tickerTimer?.cancel();
                              Navigator.of(dialogContext).pop(null);
                            },
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelectionValid ? const Color(0xFF004385) : const Color(0xFFCBD5E1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: isSelectionValid
                                ? () {
                                    tickerTimer?.cancel();
                                    Navigator.of(dialogContext).pop(currentPreview);
                                  }
                                : null,
                            child: Text(
                              'OK',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
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
}
