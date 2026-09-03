import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vms_operator_tablet/core/shared/widgets/app_snackbar.dart';
import 'package:vms_operator_tablet/features/dashboard/controller/dashboard_controller.dart';
import 'package:vms_operator_tablet/features/dashboard/widgets/add_walk_in_modal.dart';

class FillPraRegistrationModal extends StatefulWidget {
  final Map<String, dynamic> visitor;

  const FillPraRegistrationModal({
    super.key,
    required this.visitor,
  });

  static Future<void> show(BuildContext context, {required Map<String, dynamic> visitor}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: FillPraRegistrationModal(visitor: visitor),
      ),
    );
  }

  @override
  State<FillPraRegistrationModal> createState() => _FillPraRegistrationModalState();
}

class _FillPraRegistrationModalState extends State<FillPraRegistrationModal> {
  final DashboardController controller = Get.find<DashboardController>();

  // 0: Self vs Others (Step 0)
  // 1: Visitor Information
  // 2: Purpose Visit
  // 3: Vehicle/Parking Information
  // 4: Selfie Image
  // 5: Upload Identity (KTP)
  int _currentStep = 0;
  bool _isLoading = true;

  // --- Step 0 State ---
  String _invitationTarget = 'self'; // 'self' or 'others'

  // --- API Loaded Data ---
  Map<String, dynamic>? _rawDetailForm;
  List<Map<String, dynamic>> _questionPages = [];
  Map<String, dynamic>? _hostData;
  Map<String, dynamic>? _visitorTypeData;

  String _visitorTypeId = '';
  String _trxVisitorId = '';
  String _groupName = '';
  bool _isGroup = false;

  // --- Step 1 Controllers (Visitor Information - EDITABLE) ---
  String? _selectedRole;
  final TextEditingController _roleCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _orgCtrl = TextEditingController();
  final TextEditingController _identityCtrl = TextEditingController();
  final Map<String, TextEditingController> _visitorExtraCtrls = {};

  // --- Step 2 Controllers (Purpose Visit - READ-ONLY) ---
  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _picHostCtrl = TextEditingController();
  final TextEditingController _agendaCtrl = TextEditingController();
  final TextEditingController _visitStartCtrl = TextEditingController();
  final TextEditingController _visitEndCtrl = TextEditingController();
  final Map<String, TextEditingController> _purposeExtraCtrls = {};
  String? _rawSitePlaceId;
  String? _rawHostId;
  String? _rawVisitStartIso;
  String? _rawVisitEndIso;

  // --- Step 3 Controllers (Vehicle Information) ---
  bool _isDriving = false;
  String? _vehicleType;
  final TextEditingController _vehiclePlateCtrl = TextEditingController();

  final List<String> _vehicleTypeOptions = [
    'Bicycle',
    'Bus',
    'Car',
    'Motorcycle',
  ];

  // --- Step 4 & 5 Documents ---
  UploadedFileData? _selfieImage;
  UploadedFileData? _ktpImage;

  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);

    // Resolve trxVisitorId
    String targetTrxId = (widget.visitor['id'] ??
            widget.visitor['trx_visitor_id'] ??
            widget.visitor['transaction_visitor_id'] ??
            '')
        .toString()
        .trim();

    _visitorTypeId = (widget.visitor['visitor_type'] ??
            widget.visitor['visitor_type_id'] ??
            '')
        .toString();
    _groupName = (widget.visitor['group_name'] ??
            widget.visitor['group'] ??
            '')
        .toString();
    _isGroup = widget.visitor['is_group'] == true;

    if (controller.rxPraRegVisitorTypes.isEmpty) {
      controller.fetchPraRegistrationDependencies(silent: true);
    }

    // Fetch detail invitations form from API
    Map<String, dynamic>? detail;
    if (targetTrxId.isNotEmpty) {
      detail = await controller.fetchDetailInvitationsForm(targetTrxId);
    }

    if (detail != null) {
      _rawDetailForm = detail;
      _trxVisitorId = (detail['id'] ??
              detail['trx_visitor_id'] ??
              detail['transaction_visitor_id'] ??
              targetTrxId)
          .toString();

      if (detail['visitor_type'] != null) {
        _visitorTypeId = detail['visitor_type'].toString();
      }
      if (detail['group_name'] != null) {
        _groupName = detail['group_name'].toString();
      }
      if (detail['is_group'] != null) {
        _isGroup = detail['is_group'] == true;
      }

      _hostData = detail['host_data'] as Map<String, dynamic>?;
      _visitorTypeData = detail['visitor_type_data'] as Map<String, dynamic>?;

      final qPagesRaw = detail['question_page'] as List<dynamic>? ?? [];
      _questionPages = qPagesRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      _populateFieldsFromQuestionPages();
    } else {
      _trxVisitorId = targetTrxId;
      _populateFallbackFields();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _populateFieldsFromQuestionPages() {
    // 1. Parse Visitor Information (sort == 0 or name contains 'visitor')
    final visitorSec = _questionPages.firstWhereOrNull(
      (s) => (s['sort'] == 0) || (s['name'] ?? '').toString().toLowerCase().contains('visitor'),
    );
    if (visitorSec != null) {
      final forms = visitorSec['form'] as List<dynamic>? ?? [];
      for (final f in forms) {
        if (f is! Map) continue;
        final field = Map<String, dynamic>.from(f);
        final remarks = (field['remarks'] ?? '').toString().toLowerCase().trim();
        final shortName = (field['short_name'] ?? '').toString().toLowerCase().trim();
        final longText = (field['long_display_text'] ?? '').toString().toLowerCase().trim();
        final ans = (field['answer_text'] ?? '').toString();

        if (remarks == 'name' || shortName.contains('name') || longText.contains('name')) {
          _fullNameCtrl.text = ans.isNotEmpty ? ans : (widget.visitor['visitor_name'] ?? widget.visitor['name'] ?? '').toString();
        } else if (remarks == 'email' || shortName.contains('email') || longText.contains('email')) {
          _emailCtrl.text = ans.isNotEmpty ? ans : (widget.visitor['visitor_email'] ?? widget.visitor['email'] ?? '').toString();
        } else if (remarks == 'phone' || shortName.contains('phone') || longText.contains('phone')) {
          _phoneCtrl.text = ans.isNotEmpty ? ans : (widget.visitor['visitor_phone'] ?? widget.visitor['phone'] ?? '').toString();
        } else if (remarks == 'organization' || remarks == 'company' || shortName.contains('org') || shortName.contains('company') || longText.contains('org') || longText.contains('company')) {
          _orgCtrl.text = ans.isNotEmpty ? ans : (widget.visitor['visitor_organization_name'] ?? widget.visitor['organization'] ?? '').toString();
        } else if (remarks.contains('identity') || remarks.contains('indentity') || remarks.contains('citizenship') || shortName.contains('identity') || shortName.contains('citizenship') || longText.contains('citizenship') || longText.contains('identity')) {
          _identityCtrl.text = ans.isNotEmpty ? ans : (widget.visitor['visitor_identity_id'] ?? widget.visitor['identity_id'] ?? '').toString();
        } else if (remarks == 'visitor_role' || remarks == 'role' || shortName.contains('role') || longText.contains('role') || shortName.contains('visitor type')) {
          _selectedRole = ans.isNotEmpty
              ? ans
              : (_visitorTypeData?['name'] ??
                  _visitorTypeData?['type_name'] ??
                  widget.visitor['visitor_role'] ??
                  widget.visitor['visitor_type_name'] ??
                  widget.visitor['role'] ??
                  'Visitor')
                  .toString();
          _roleCtrl.text = _selectedRole!;
        } else {
          _visitorExtraCtrls.putIfAbsent(remarks, () => TextEditingController(text: ans));
        }
      }
      if (_selectedRole == null || _selectedRole!.isEmpty) {
        _selectedRole = (_visitorTypeData?['name'] ??
            _visitorTypeData?['type_name'] ??
            widget.visitor['visitor_role'] ??
            widget.visitor['visitor_type_name'] ??
            widget.visitor['role'] ??
            'Visitor')
            .toString();
        _roleCtrl.text = _selectedRole!;
      }
    } else {
      _populateFallbackFields();
    }

    // 2. Parse Purpose Visit (sort == 1 or name contains 'purpose')
    final purposeSec = _questionPages.firstWhereOrNull(
      (s) => (s['sort'] == 1) || (s['name'] ?? '').toString().toLowerCase().contains('purpose'),
    );
    if (purposeSec != null) {
      final forms = purposeSec['form'] as List<dynamic>? ?? [];
      for (final f in forms) {
        if (f is! Map) continue;
        final field = Map<String, dynamic>.from(f);
        final remarks = (field['remarks'] ?? '').toString().toLowerCase().trim();
        final ans = (field['answer_text'] ?? '').toString();
        final dt = (field['answer_datetime'] ?? '').toString();

        if (remarks == 'site_place' || remarks == 'destination') {
          _rawSitePlaceId = ans;
          _destinationCtrl.text = (_rawDetailForm?['site_place_name'] ??
                  widget.visitor['site_place_name'] ??
                  'Gedung SINERGI')
              .toString();
        } else if (remarks == 'host' || remarks == 'pic_host') {
          _rawHostId = ans;
          _picHostCtrl.text = (_rawDetailForm?['host_name'] ??
                  _hostData?['name'] ??
                  widget.visitor['host_name'] ??
                  'Endru')
              .toString();
        } else if (remarks == 'agenda') {
          _agendaCtrl.text = ans.isNotEmpty ? ans : (_rawDetailForm?['agenda'] ?? widget.visitor['agenda'] ?? 'Meeting').toString();
        } else if (remarks == 'visitor_period_start') {
          _rawVisitStartIso = dt.isNotEmpty ? dt : (_rawDetailForm?['visitor_period_start'] ?? widget.visitor['visitor_period_start'] ?? '').toString();
          _visitStartCtrl.text = _formatDateTimeDisplay(_rawVisitStartIso);
        } else if (remarks == 'visitor_period_end') {
          _rawVisitEndIso = dt.isNotEmpty ? dt : (_rawDetailForm?['visitor_period_end'] ?? widget.visitor['visitor_period_end'] ?? '').toString();
          _visitEndCtrl.text = _formatDateTimeDisplay(_rawVisitEndIso);
        } else {
          _purposeExtraCtrls.putIfAbsent(remarks, () => TextEditingController(text: ans));
        }
      }
    } else {
      _destinationCtrl.text = (widget.visitor['site_place_name'] ?? 'Gedung SINERGI').toString();
      _picHostCtrl.text = (widget.visitor['host_name'] ?? 'Endru').toString();
      _agendaCtrl.text = (widget.visitor['agenda'] ?? 'Meeting').toString();
      _visitStartCtrl.text = _formatDateTimeDisplay(widget.visitor['visitor_period_start']?.toString());
      _visitEndCtrl.text = _formatDateTimeDisplay(widget.visitor['visitor_period_end']?.toString());
    }

    // 3. Parse Vehicle Information (sort == 2)
    final vehicleSec = _questionPages.firstWhereOrNull(
      (s) => (s['sort'] == 2) || (s['name'] ?? '').toString().toLowerCase().contains('vehicle'),
    );
    if (vehicleSec != null) {
      final forms = vehicleSec['form'] as List<dynamic>? ?? [];
      for (final f in forms) {
        if (f is! Map) continue;
        final field = Map<String, dynamic>.from(f);
        final remarks = (field['remarks'] ?? '').toString().toLowerCase().trim();
        final ans = (field['answer_text'] ?? '').toString();

        if (remarks == 'is_driving') {
          _isDriving = ans == 'true';
        } else if (remarks == 'vehicle_type' && ans.isNotEmpty && ans != 'null') {
          _vehicleType = ans;
        } else if (remarks == 'vehicle_plate' && ans.isNotEmpty && ans != 'null') {
          _vehiclePlateCtrl.text = ans;
        }
      }
    }
  }

  void _populateFallbackFields() {
    _fullNameCtrl.text = (widget.visitor['visitor_name'] ?? widget.visitor['name'] ?? '').toString();
    _emailCtrl.text = (widget.visitor['visitor_email'] ?? widget.visitor['email'] ?? '').toString();
    _phoneCtrl.text = (widget.visitor['visitor_phone'] ?? '').toString();
    _orgCtrl.text = (widget.visitor['visitor_organization_name'] ?? '').toString();
    _identityCtrl.text = (widget.visitor['visitor_identity_id'] ?? '').toString();
    _selectedRole = (widget.visitor['visitor_role'] ?? 'Visitor').toString();
    _roleCtrl.text = _selectedRole!;

    _destinationCtrl.text = (widget.visitor['site_place_name'] ?? 'Gedung SINERGI').toString();
    _picHostCtrl.text = (widget.visitor['host_name'] ?? 'Endru').toString();
    _agendaCtrl.text = (widget.visitor['agenda'] ?? 'Meeting').toString();
    _visitStartCtrl.text = _formatDateTimeDisplay(widget.visitor['visitor_period_start']?.toString());
    _visitEndCtrl.text = _formatDateTimeDisplay(widget.visitor['visitor_period_end']?.toString());
  }

  String _formatDateTimeDisplay(String? iso) {
    if (iso == null || iso.isEmpty) return 'Jumat, 28 Agustus 2026, 09:00';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final dayName = days[dt.weekday % 7];
      final monthName = months[dt.month - 1];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$dayName, ${dt.day} $monthName ${dt.year}, $h:$m';
    } catch (_) {
      return iso;
    }
  }

  bool _isBicycle(String? vehicleType) {
    if (vehicleType == null) return false;
    final t = vehicleType.toLowerCase().trim();
    return t == 'bicycle' || t == 'sepeda' || t.contains('bicycle') || t.contains('sepeda') || t == 'bike';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validation Getters
  // ─────────────────────────────────────────────────────────────────────────
  bool get _isStep0Valid => true;

  bool get _isStep1Valid {
    if (_roleCtrl.text.trim().isEmpty) return false;
    if (_fullNameCtrl.text.trim().isEmpty) return false;
    if (_emailCtrl.text.trim().isEmpty) return false;
    if (_phoneCtrl.text.trim().isEmpty) return false;
    if (_orgCtrl.text.trim().isEmpty) return false;
    if (_identityCtrl.text.trim().isEmpty) return false;
    return true;
  }

  bool get _isStep2Valid => true; // Read-only step is always valid

  bool get _isStep3Valid {
    if (_isDriving) {
      if (_vehicleType == null || _vehicleType!.trim().isEmpty) return false;
      if (!_isBicycle(_vehicleType) && _vehiclePlateCtrl.text.trim().isEmpty) return false;
    }
    return true;
  }

  bool get _isStep4Valid => true; // Selfie is optional or valid

  bool get _isStep5Valid => true; // KTP is optional or valid

  bool get _isCurrentStepValid {
    if (_currentStep == 0) return _isStep0Valid;
    if (_currentStep == 1) return _isStep1Valid;
    if (_currentStep == 2) return _isStep2Valid;
    if (_currentStep == 3) return _isStep3Valid;
    if (_currentStep == 4) return _isStep4Valid;
    if (_currentStep == 5) return _isStep5Valid;
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submission
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      // 1. Upload Images if present
      String? selfieCdnUrl;
      if (_selfieImage?.bytes != null) {
        selfieCdnUrl = await controller.uploadCdnFile(
          _selfieImage!.bytes!,
          _selfieImage!.name,
          path: 'face',
        );
      }

      String? ktpCdnUrl;
      if (_ktpImage?.bytes != null) {
        ktpCdnUrl = await controller.uploadCdnFile(
          _ktpImage!.bytes!,
          _ktpImage!.name,
          path: 'face',
        );
      }

      // 2. Build serialized question pages matching exact user schema
      final builtQuestionPages = _buildFinalQuestionPages(
        selfieUrl: selfieCdnUrl,
        ktpUrl: ktpCdnUrl,
      );

      final isSelf = _invitationTarget == 'self';
      final primaryName = _fullNameCtrl.text.trim();
      final primaryEmail = _emailCtrl.text.trim();
      final primaryPhone = _phoneCtrl.text.trim();
      final primaryOrg = _orgCtrl.text.trim();
      final primaryIdentity = _identityCtrl.text.trim();
      final primaryRole = _selectedRole ?? 'Visitor';

      final payload = {
        'visitor_type': _visitorTypeId.isNotEmpty ? _visitorTypeId : '1e7ab7a0-1fdd-4546-b65f-6a8dcc345148',
        'type_registered': 0,
        'trx_visitor_id': _trxVisitorId,
        'is_group': _isGroup,
        'group_name': _groupName.isNotEmpty ? _groupName : "Visitor's Group",
        'tz': 'Asia/Jakarta',
        'flow': 'SubmitPraregister',
        'is_self_registered': isSelf,
        'filled_by_name': primaryName,
        'filled_by_email': primaryEmail,
        'filled_by_phone': primaryPhone,
        'filled_by_relationship': isSelf ? 'Self' : 'Other',
        'filled_by_relationship_name': isSelf ? 'Self' : 'Other',
        'data_visitor': [
          {
            'question_page': builtQuestionPages,
          }
        ],
      };

      final success = await controller.submitCompletePraRegistration(payload: payload);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          widget.visitor['is_praregister_done'] = true;
          widget.visitor['is_complete_preregister'] = true;
          if (primaryName.isNotEmpty) {
            widget.visitor['visitor_name'] = primaryName;
            widget.visitor['name'] = primaryName;
          }
          if (primaryEmail.isNotEmpty) {
            widget.visitor['visitor_email'] = primaryEmail;
            widget.visitor['email'] = primaryEmail;
          }
          if (primaryPhone.isNotEmpty) {
            widget.visitor['visitor_phone'] = primaryPhone;
            widget.visitor['phone'] = primaryPhone;
          }
          if (primaryOrg.isNotEmpty) {
            widget.visitor['visitor_organization_name'] = primaryOrg;
            widget.visitor['organization'] = primaryOrg;
            widget.visitor['organization_name'] = primaryOrg;
          }
          if (primaryIdentity.isNotEmpty) {
            widget.visitor['visitor_identity_id'] = primaryIdentity;
            widget.visitor['identity_id'] = primaryIdentity;
          }
          if (primaryRole.isNotEmpty) {
            widget.visitor['visitor_role'] = primaryRole;
            widget.visitor['visitor_type_name'] = primaryRole;
            widget.visitor['role'] = primaryRole;
          }
          if (selfieCdnUrl != null && selfieCdnUrl.isNotEmpty) {
            widget.visitor['selfie_image'] = selfieCdnUrl;
            widget.visitor['visitor_face'] = selfieCdnUrl;
            widget.visitor['face_image'] = selfieCdnUrl;
          }
          if (ktpCdnUrl != null && ktpCdnUrl.isNotEmpty) {
            widget.visitor['identity_image'] = ktpCdnUrl;
            widget.visitor['ktp_image'] = ktpCdnUrl;
          }
          if (_isDriving) {
            widget.visitor['is_driving'] = true;
            widget.visitor['vehicle_type'] = _vehicleType;
            widget.visitor['vehicle_plate_number'] = _isBicycle(_vehicleType) ? null : _vehiclePlateCtrl.text.trim();
          } else {
            widget.visitor['is_driving'] = false;
            widget.visitor['vehicle_type'] = null;
            widget.visitor['vehicle_plate_number'] = null;
          }

          if (widget.visitor['raw'] is Map) {
            final raw = widget.visitor['raw'] as Map<String, dynamic>;
            raw['is_praregister_done'] = true;
            raw['is_complete_preregister'] = true;
            if (primaryName.isNotEmpty) raw['visitor_name'] = primaryName;
            if (primaryEmail.isNotEmpty) raw['visitor_email'] = primaryEmail;
            if (primaryPhone.isNotEmpty) raw['visitor_phone'] = primaryPhone;
            if (primaryOrg.isNotEmpty) raw['visitor_organization_name'] = primaryOrg;
            if (primaryIdentity.isNotEmpty) raw['visitor_identity_id'] = primaryIdentity;
            if (primaryRole.isNotEmpty) raw['visitor_type_name'] = primaryRole;
            if (selfieCdnUrl != null) raw['selfie_image'] = selfieCdnUrl;
            if (ktpCdnUrl != null) raw['identity_image'] = ktpCdnUrl;
          }

          if (controller.rxSelectedVisitor.value != null) {
            final updatedMap = Map<String, dynamic>.from(controller.rxSelectedVisitor.value!);
            updatedMap['is_praregister_done'] = true;
            updatedMap['is_complete_preregister'] = true;
            if (primaryName.isNotEmpty) {
              updatedMap['visitor_name'] = primaryName;
              updatedMap['name'] = primaryName;
            }
            if (primaryEmail.isNotEmpty) {
              updatedMap['visitor_email'] = primaryEmail;
              updatedMap['email'] = primaryEmail;
            }
            if (primaryPhone.isNotEmpty) {
              updatedMap['visitor_phone'] = primaryPhone;
              updatedMap['phone'] = primaryPhone;
            }
            if (primaryOrg.isNotEmpty) {
              updatedMap['visitor_organization_name'] = primaryOrg;
              updatedMap['organization'] = primaryOrg;
              updatedMap['organization_name'] = primaryOrg;
            }
            if (primaryIdentity.isNotEmpty) {
              updatedMap['visitor_identity_id'] = primaryIdentity;
              updatedMap['identity_id'] = primaryIdentity;
            }
            if (primaryRole.isNotEmpty) {
              updatedMap['visitor_role'] = primaryRole;
              updatedMap['visitor_type_name'] = primaryRole;
              updatedMap['role'] = primaryRole;
            }
            if (selfieCdnUrl != null && selfieCdnUrl.isNotEmpty) {
              updatedMap['selfie_image'] = selfieCdnUrl;
              updatedMap['visitor_face'] = selfieCdnUrl;
              updatedMap['face_image'] = selfieCdnUrl;
            }
            if (ktpCdnUrl != null && ktpCdnUrl.isNotEmpty) {
              updatedMap['identity_image'] = ktpCdnUrl;
              updatedMap['ktp_image'] = ktpCdnUrl;
            }
            controller.rxSelectedVisitor.value = updatedMap;
          }

          final targetTrx = _trxVisitorId;
          for (var i = 0; i < controller.rxRelatedVisitors.length; i++) {
            final item = controller.rxRelatedVisitors[i];
            final itemId = (item['id'] ?? item['trx_id'] ?? item['transaction_visitor_id'] ?? '').toString();
            if (itemId == targetTrx) {
              controller.rxRelatedVisitors[i] = Map<String, dynamic>.from(controller.rxSelectedVisitor.value ?? widget.visitor);
              break;
            }
          }
          for (var i = 0; i < controller.rxAllRelatedVisitors.length; i++) {
            final item = controller.rxAllRelatedVisitors[i];
            final itemId = (item['id'] ?? item['trx_id'] ?? item['transaction_visitor_id'] ?? '').toString();
            if (itemId == targetTrx) {
              controller.rxAllRelatedVisitors[i] = Map<String, dynamic>.from(controller.rxSelectedVisitor.value ?? widget.visitor);
              break;
            }
          }

          controller.rxSelectedVisitor.refresh();
          controller.rxRelatedVisitors.refresh();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error in submit complete pra: $e');
      if (mounted) setState(() => _isSubmitting = false);
      AppSnackbar.error(
        title: 'Submission Error',
        message: 'An error occurred while submitting form: $e',
      );
    }
  }

  List<Map<String, dynamic>> _buildFinalQuestionPages({
    required String? selfieUrl,
    required String? ktpUrl,
  }) {
    // If API question pages are available, clone & inject answers
    if (_questionPages.isNotEmpty) {
      final List<Map<String, dynamic>> outPages = [];
      for (final p in _questionPages) {
        final pageMap = Map<String, dynamic>.from(p);
        final formsRaw = pageMap['form'] as List<dynamic>? ?? [];
        final List<Map<String, dynamic>> builtForms = [];

        for (final f in formsRaw) {
          if (f is! Map) continue;
          final field = Map<String, dynamic>.from(f);
          final remarks = (field['remarks'] ?? '').toString().toLowerCase().trim();
          final shortName = (field['short_name'] ?? '').toString().toLowerCase().trim();
          final longText = (field['long_display_text'] ?? '').toString().toLowerCase().trim();
          final fieldType = field['field_type'] ?? 0;

          if (remarks == 'email' || shortName.contains('email') || longText.contains('email')) {
            field['answer_text'] = _emailCtrl.text.trim();
          } else if (remarks == 'phone' || shortName.contains('phone') || longText.contains('phone') || remarks.contains('mobile')) {
            field['answer_text'] = _phoneCtrl.text.trim();
          } else if (remarks == 'organization' || remarks == 'company' || remarks == 'instansi' || shortName.contains('org') || shortName.contains('company') || longText.contains('org') || longText.contains('company') || longText.contains('instansi')) {
            field['answer_text'] = _orgCtrl.text.trim();
          } else if (remarks == 'indentity_id' || remarks == 'identity_id' || remarks.contains('identity') || remarks.contains('indentity') || remarks.contains('citizenship') || shortName.contains('identity') || shortName.contains('indentity') || shortName.contains('citizenship') || longText.contains('citizenship') || longText.contains('identity') || longText.contains('indentity')) {
            field['answer_text'] = _identityCtrl.text.trim();
          } else if (remarks == 'visitor_role' || remarks == 'role' || shortName == 'role' || shortName == 'visitor type') {
            field['answer_text'] = _selectedRole ?? 'Visitor';
          } else if (remarks == 'name' || remarks == 'full_name' || remarks == 'fullname' || shortName == 'full name' || shortName == 'fullname' || shortName == 'name' || longText == 'fullname' || longText == 'full name') {
            field['answer_text'] = _fullNameCtrl.text.trim();
          } else if (remarks == 'is_driving' || shortName.contains('driving')) {
            field['answer_text'] = _isDriving ? 'true' : 'false';
          } else if (remarks == 'vehicle_type' || shortName.contains('vehicle type')) {
            field['answer_text'] = _isDriving ? (_vehicleType?.isNotEmpty == true ? _vehicleType : null) : null;
          } else if (remarks == 'vehicle_plate' || remarks.contains('plate') || shortName.contains('plate')) {
            field['answer_text'] = (!_isDriving || _isBicycle(_vehicleType))
                ? null
                : (_vehiclePlateCtrl.text.trim().isNotEmpty ? _vehiclePlateCtrl.text.trim() : null);
          } else if (remarks.contains('selfie') || fieldType == 10 || shortName.contains('selfie')) {
            field['answer_file'] = selfieUrl;
          } else if (remarks.contains('identity') || remarks.contains('ktp') || fieldType == 12 || shortName.contains('identity') || shortName.contains('ktp')) {
            field['answer_file'] = ktpUrl;
          }

          builtForms.add(field);
        }

        pageMap['form'] = builtForms;
        outPages.add(pageMap);
      }
      return outPages;
    }

    // Fallback standard structure matching user schema
    return [
      {
        'id': '1bcc04b9-7517-4208-90eb-6603f8215640',
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
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'name',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _fullNameCtrl.text.trim(),
          },
          {
            'sort': 1,
            'short_name': 'Email',
            'long_display_text': 'Email',
            'field_type': 2,
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'email',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _emailCtrl.text.trim(),
          },
          {
            'sort': 2,
            'short_name': 'Phone',
            'long_display_text': 'Phone',
            'field_type': 0,
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'phone',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _phoneCtrl.text.trim(),
          },
          {
            'sort': 3,
            'short_name': 'Organization',
            'long_display_text': 'Instansi/Organization/Company',
            'field_type': 0,
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'organization',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _orgCtrl.text.trim(),
          },
          {
            'sort': 4,
            'short_name': 'Indentity Id',
            'long_display_text': 'Identity Id (KTP)',
            'field_type': 0,
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'indentity_id',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _identityCtrl.text.trim(),
          },
        ],
      },
      {
        'id': '01db4f46-1a7e-4c8e-acc7-adcaf2dd1d73',
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
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'host',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _rawHostId ?? 'f2b0c94e-312d-418b-bb6e-05709784e9c3',
          },
          {
            'sort': 1,
            'short_name': 'Agenda',
            'long_display_text': 'Agenda',
            'field_type': 0,
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'agenda',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _agendaCtrl.text.trim().isNotEmpty ? _agendaCtrl.text.trim() : 'Meeting',
          },
          {
            'sort': 2,
            'short_name': 'Destination',
            'long_display_text': 'Destination',
            'field_type': 3,
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'site_place',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _rawSitePlaceId ?? 'E3FACB54-EAE1-48D5-9457-3EF7D3F7BA3B',
          },
          {
            'sort': 3,
            'short_name': 'Visit Start',
            'long_display_text': 'Visit Start',
            'field_type': 9,
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'visitor_period_start',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_datetime': _rawVisitStartIso ?? '2026-08-28T02:45:00Z',
          },
          {
            'sort': 4,
            'short_name': 'Visit End',
            'long_display_text': 'Visit End',
            'field_type': 9,
            'is_primary': false,
            'is_enable': false,
            'mandatory': false,
            'remarks': 'visitor_period_end',
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_datetime': _rawVisitEndIso ?? '2026-08-28T13:00:00Z',
          },
        ],
      },
      {
        'id': 'a1e6cd4c-1baf-431f-b09e-06cf8993dcfe',
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
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _isDriving ? 'true' : 'false',
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
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': _isDriving ? (_vehicleType?.isNotEmpty == true ? _vehicleType : null) : null,
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
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_text': (!_isDriving || _isBicycle(_vehicleType))
                ? null
                : (_vehiclePlateCtrl.text.trim().isNotEmpty ? _vehiclePlateCtrl.text.trim() : null),
          },
        ],
      },
      {
        'id': '766db70e-83fd-4538-b4f1-ed1ab74f4a7c',
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
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_file': selfieUrl,
          },
        ],
      },
      {
        'id': '20cf5426-e20e-4fef-82e5-266dd37032be',
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
            'multiple_option_fields': [],
            'visitor_form_type': 1,
            'answer_file': ktpUrl,
          },
        ],
      },
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // File & Camera Image Picking
  // ─────────────────────────────────────────────────────────────────────────
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png'];

  Future<void> _pickImageFile({required bool isKtp}) async {
    try {
      Uint8List? fileBytes;
      String? fileName;
      String? filePath;

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
      } catch (e) {
        debugPrint('FilePicker fallback: $e');
      }

      if (fileBytes == null) {
        final xFile = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (xFile != null) {
          fileBytes = await xFile.readAsBytes();
          fileName = xFile.name;
          filePath = xFile.path;
        }
      }

      if (fileBytes != null && fileName != null) {
        if (fileBytes.length > _maxFileSizeBytes) {
          AppSnackbar.error(
            title: 'File Too Large',
            message: 'Image size exceeds 5MB limit. Please choose a smaller file.',
          );
          return;
        }

        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
        if (!_allowedExtensions.contains(ext)) {
          AppSnackbar.error(
            title: 'Invalid Format',
            message: 'Only JPG, JPEG, and PNG images are supported.',
          );
          return;
        }

        setState(() {
          final uploaded = UploadedFileData(
            name: fileName!,
            sizeBytes: fileBytes!.length,
            extension: ext,
            localPath: filePath,
            bytes: fileBytes,
          );
          if (isKtp) {
            _ktpImage = uploaded;
          } else {
            _selfieImage = uploaded;
          }
        });

        AppSnackbar.success(
          title: 'Image Uploaded',
          message: '${isKtp ? 'Upload Identity (KTP)' : 'Selfie'} image uploaded successfully.',
        );
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      AppSnackbar.error(title: 'Upload Error', message: 'Failed to select image: $e');
    }
  }

  Future<void> _captureImageFromCamera({required bool isKtp}) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: isKtp ? CameraDevice.rear : CameraDevice.front,
      );
      if (xFile != null) {
        final fileBytes = await xFile.readAsBytes();
        final fileName = xFile.name.isNotEmpty ? xFile.name : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

        if (fileBytes.length > _maxFileSizeBytes) {
          AppSnackbar.error(
            title: 'File Too Large',
            message: 'Image size exceeds 5MB limit. Please choose a smaller file.',
          );
          return;
        }

        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
        setState(() {
          final uploaded = UploadedFileData(
            name: fileName,
            sizeBytes: fileBytes.length,
            extension: ext,
            localPath: xFile.path,
            bytes: fileBytes,
          );
          if (isKtp) {
            _ktpImage = uploaded;
          } else {
            _selfieImage = uploaded;
          }
        });

        AppSnackbar.success(
          title: 'Photo Captured',
          message: '${isKtp ? 'Upload Identity (KTP)' : 'Selfie'} photo captured successfully.',
        );
      }
    } catch (e) {
      debugPrint('Camera capture error: $e');
      AppSnackbar.error(title: 'Camera Error', message: 'Failed to capture photo: $e');
    }
  }

  void _removeUploadedImage({required bool isKtp}) {
    setState(() {
      if (isKtp) {
        _ktpImage = null;
      } else {
        _selfieImage = null;
      }
    });

    AppSnackbar.info(
      title: 'Image Removed',
      message: '${isKtp ? 'Upload Identity (KTP)' : 'Selfie'} image has been removed.',
    );
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    _identityCtrl.dispose();
    for (final c in _visitorExtraCtrls.values) {
      c.dispose();
    }

    _destinationCtrl.dispose();
    _picHostCtrl.dispose();
    _agendaCtrl.dispose();
    _visitStartCtrl.dispose();
    _visitEndCtrl.dispose();
    for (final c in _purposeExtraCtrls.values) {
      c.dispose();
    }

    _vehiclePlateCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build Main Dialog
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 780,
      constraints: const BoxConstraints(maxHeight: 680),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),

          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF004385)),
                    SizedBox(height: 14),
                    Text('Loading Pra-Registration Form...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
              ),
            )
          else ...[
            // Stepper (Steps 1 to 5) - shown when _currentStep >= 1
            if (_currentStep >= 1) _buildStepperBar(),

            // Content Area
            Expanded(
              child: _buildCurrentStepContent(),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Footer Navigation
            _buildFooter(),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Fill Pra Registration Form',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step Indicator (Steps 1 to 5)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStepperBar() {
    final steps = [
      {'num': 1, 'title': 'Visitor Information'},
      {'num': 2, 'title': 'Purpose Visit'},
      {'num': 3, 'title': 'Vehicle/Parking Information'},
      {'num': 4, 'title': 'Selfie Image'},
      {'num': 5, 'title': 'Upload Identity (KTP)'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepBefore = (index ~/ 2) + 1;
            final isPassed = _currentStep > stepBefore;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 14),
                height: 2,
                color: isPassed ? const Color(0xFF004385) : const Color(0xFFCBD5E1),
              ),
            );
          }

          final stepIdx = index ~/ 2;
          final stepNum = steps[stepIdx]['num'] as int;
          final stepTitle = steps[stepIdx]['title'] as String;
          final isCurrent = _currentStep == stepNum;
          final isCompleted = _currentStep > stepNum;

          return SizedBox(
            width: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent || isCompleted
                        ? const Color(0xFF004385)
                        : const Color(0xFFE2E8F0),
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '$stepNum',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  stepTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? const Color(0xFF004385) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Current Step Content Router
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0SelfOrOthers();
      case 1:
        return _buildStep1VisitorInformation();
      case 2:
        return _buildStep2PurposeVisit();
      case 3:
        return _buildStep3VehicleInfo();
      case 4:
        return _buildStep4SelfieImage();
      case 5:
        return _buildStep5KtpImage();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 0: Self vs Others
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep0SelfOrOthers() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you filling this invitation for yourself or someone else?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select whether you are creating the invitation for yourself or for someone else.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildChoiceCard(
                  title: 'Self',
                  desc: 'Use this option if you are registering yourself.',
                  isSelected: _invitationTarget == 'self',
                  onTap: () => setState(() => _invitationTarget = 'self'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChoiceCard(
                  title: 'Others',
                  desc: 'Use this option if you are creating an invitation for someone else.',
                  isSelected: _invitationTarget == 'others',
                  onTap: () => setState(() => _invitationTarget = 'others'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF004385) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected ? const Color(0xFF004385) : const Color(0xFF94A3B8),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFF004385) : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: Visitor Information (EDITABLE)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1VisitorInformation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormFieldLabel('Role', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _roleCtrl,
            hint: 'Role',
            enabled: false,
            readOnly: true,
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('Fullname', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _fullNameCtrl,
            hint: 'Enter your fullname',
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('Email', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _emailCtrl,
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            enabled: false,
            readOnly: true,
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('Phone', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _phoneCtrl,
            hint: 'Enter your phone number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('Department/Organization/Company', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _orgCtrl,
            hint: 'Enter your organization',
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('Citizenship ID', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _identityCtrl,
            hint: 'Enter your citizenship ID (KTP)',
          ),
          const SizedBox(height: 16),

          // Extra dynamic fields if any
          ..._visitorExtraCtrls.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(e.key.capitalizeFirst ?? e.key, isRequired: false),
                  const SizedBox(height: 6),
                  _buildTextInputField(
                    controller: e.value,
                    hint: 'Enter ${e.key}',
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
  // Step 2: Purpose Visit (READ-ONLY / DISABLED)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2PurposeVisit() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormFieldLabel('Destination', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _destinationCtrl,
            hint: 'Gedung SINERGI',
            enabled: false,
            readOnly: true,
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('PIC Host', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _picHostCtrl,
            hint: 'Endru',
            enabled: false,
            readOnly: true,
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('Agenda', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _agendaCtrl,
            hint: 'Meeting',
            enabled: false,
            readOnly: true,
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('Visit Start', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _visitStartCtrl,
            hint: 'Visit Start Date & Time',
            enabled: false,
            readOnly: true,
          ),
          const SizedBox(height: 16),

          _buildFormFieldLabel('Visit End', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInputField(
            controller: _visitEndCtrl,
            hint: 'Visit End Date & Time',
            enabled: false,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3: Vehicle / Parking Information
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep3VehicleInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormFieldLabel('Are you driving?', isRequired: true),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildRadioOption(
                label: 'Yes',
                isSelected: _isDriving == true,
                onTap: () => setState(() => _isDriving = true),
              ),
              const SizedBox(width: 24),
              _buildRadioOption(
                label: 'No',
                isSelected: _isDriving == false,
                onTap: () => setState(() {
                  _isDriving = false;
                  _vehicleType = null;
                  _vehiclePlateCtrl.clear();
                }),
              ),
            ],
          ),

          if (_isDriving) ...[
            const SizedBox(height: 20),
            _buildFormFieldLabel('Vehicle Type', isRequired: true),
            const SizedBox(height: 6),
            _buildCleanDropdownField<String>(
              hint: 'Select Vehicle Type',
              selectedValue: _vehicleType,
              items: _vehicleTypeOptions.map((e) {
                return DropdownMenuItemData<String>(value: e, label: e);
              }).toList(),
              onSelected: (val) {
                setState(() {
                  _vehicleType = val;
                  if (_isBicycle(val)) {
                    _vehiclePlateCtrl.clear();
                  }
                });
              },
            ),
            if (!_isBicycle(_vehicleType)) ...[
              const SizedBox(height: 16),
              _buildFormFieldLabel('Vehicle License Plate', isRequired: true),
              const SizedBox(height: 6),
              _buildTextInputField(
                controller: _vehiclePlateCtrl,
                hint: 'e.g. B 1234 XYZ',
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 4 & 5: Selfie Image & KTP Upload
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep4SelfieImage() {
    return _buildImageUploadStep(
      isKtp: false,
      title: 'Selfie Image',
      image: _selfieImage,
    );
  }

  Widget _buildStep5KtpImage() {
    return _buildImageUploadStep(
      isKtp: true,
      title: 'Upload Identity (KTP)',
      image: _ktpImage,
    );
  }

  Widget _buildImageUploadStep({
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
              onTapGallery: () => _pickImageFile(isKtp: isKtp),
              onTapCamera: () => _captureImageFromCamera(isKtp: isKtp),
            )
          else
            _buildImagePreviewCard(
              image: image,
              onRemove: () => _removeUploadedImage(isKtp: isKtp),
              onReUpload: () => _pickImageFile(isKtp: isKtp),
            ),
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
      height: 200,
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
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE3F2FD),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 24,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Upload File',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F2B48),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Drag and drop or tap to select file.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Supports: JPG, JPEG, PNG, Up to 5MB',
                    style: GoogleFonts.inter(
                      fontSize: 11,
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
                          const Icon(Icons.camera_alt_outlined, size: 15, color: Color(0xFF004385)),
                          const SizedBox(width: 4),
                          Text(
                            'Use Camera',
                            style: GoogleFonts.inter(
                              fontSize: 11,
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
              width: 80,
              height: 80,
              child: image.bytes != null
                  ? Image.memory(image.bytes!, fit: BoxFit.cover)
                  : (image.localPath != null && !kIsWeb
                      ? Image.file(File(image.localPath!), fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, size: 36))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        image.extension.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF0284C7)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      image.sizeFormatted,
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onReUpload,
            icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF004385)),
            label: Text('Replace', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF004385))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF004385)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Footer
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final isValid = _isCurrentStepValid && !_isSubmitting;
    final isFinalStep = _currentStep == 5;

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
  // UI Helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFormFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 3),
          const Text('*', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w700)),
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
        onChanged: (_) => setState(() {}),
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
    bool showSearch = false,
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
          showSearch: showSearch,
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
    bool showSearch = false,
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
              if (!showSearch || query.isEmpty) return true;
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
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(null),
                            icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    if (showSearch)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: (_) => setPopupState(() {}),
                            style: GoogleFonts.inter(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                      ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, idx) {
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
}
