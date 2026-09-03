import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/shared/widgets/app_snackbar.dart';
import '../controller/dashboard_controller.dart';

class GroupVisitorEntry {
  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController orgCtrl = TextEditingController();
  final TextEditingController identityCtrl = TextEditingController();
  final Map<String, TextEditingController> extraControllers = {};
  String? role;
  bool? isEmployee;
  bool isSearchOpen = false;
  Map<String, dynamic>? selectedData;

  void dispose() {
    searchCtrl.dispose();
    fullNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    orgCtrl.dispose();
    identityCtrl.dispose();
    for (final c in extraControllers.values) {
      c.dispose();
    }
  }

  bool get isValid =>
      fullNameCtrl.text.trim().isNotEmpty &&
      emailCtrl.text.trim().isNotEmpty &&
      phoneCtrl.text.trim().isNotEmpty &&
      orgCtrl.text.trim().isNotEmpty &&
      identityCtrl.text.trim().isNotEmpty;
}

class AddPraRegistrationModal extends StatefulWidget {
  final bool isWalkIn;

  const AddPraRegistrationModal({super.key, this.isWalkIn = false});

  static Future<void> show(BuildContext context, {bool isWalkIn = false}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: AddPraRegistrationModal(isWalkIn: isWalkIn),
      ),
    );
  }

  @override
  State<AddPraRegistrationModal> createState() =>
      _AddPraRegistrationModalState();
}

class _AddPraRegistrationModalState extends State<AddPraRegistrationModal> {
  final DashboardController controller = Get.find<DashboardController>();

  int _currentStep =
      1; // 1: User Type, 2: Visitor Information, 3: Purpose Visit
  int _maxStepReached = 1;

  // --- Step 1 State ---
  Map<String, dynamic>? _selectedVisitorType;
  Map<String, dynamic>? _visitorTypeDetail;
  bool? _isGroup; // null = unselected, false = Single, true = Group
  String _groupCode = '';
  final TextEditingController _groupNameController = TextEditingController();

  // --- Step 2 State (Single Mode) ---
  final TextEditingController _singleSearchCtrl = TextEditingController();
  final TextEditingController _singleFullNameCtrl = TextEditingController();
  final TextEditingController _singleEmailCtrl = TextEditingController();
  final TextEditingController _singlePhoneCtrl = TextEditingController();
  final TextEditingController _singleOrgCtrl = TextEditingController();
  final TextEditingController _singleIdentityCtrl = TextEditingController();
  final Map<String, TextEditingController> _singleExtraControllers = {};
  String? _singleRole;
  bool? _singleIsEmployee = false;
  bool _singleIsSearchOpen = false;
  Map<String, dynamic>? _singleSelectedData;

  // --- Step 2 State (Group Mode) ---
  final List<GroupVisitorEntry> _groupVisitors = [];

  // --- Step 3 State (Purpose Visit) ---
  Map<String, dynamic>? _selectedDestination;
  Map<String, dynamic>? _selectedParentSite;
  bool _isParentSiteChecked = true;
  Map<String, dynamic>? _selectedChildBuilding;
  bool _isChildBuildingChecked = false;
  Map<String, dynamic>? _selectedPicHost;
  String? _selectedAgenda;
  final TextEditingController _otherAgendaController = TextEditingController();
  final Map<String, TextEditingController> _purposeExtraControllers = {};
  DateTime? _visitStart;
  DateTime? _visitEnd;

  bool _isSubmitting = false;

  final List<String> _agendaOptions = [
    'Meeting',
    'Presentation',
    'Visit',
    'Training',
    'Report',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _groupCode = _generateGroupCode();
    _initGroupVisitors();
    controller.fetchPraRegistrationDependencies(silent: true);
  }

  void _initGroupVisitors() {
    _groupVisitors.clear();
    final entry = GroupVisitorEntry();
    entry.isEmployee = false;
    _groupVisitors.add(entry);
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
    super.dispose();
  }

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

        // Auto-select 'No' (false) for Employee
        _singleIsEmployee = false;
        for (final v in _groupVisitors) {
          v.isEmployee = false;
          v.role = null;
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
        }

        _singleRole = null;
        _maxStepReached = 1;
        _clearSingle();
      });
    }
  }

  List<String> _getRolesForSelectedType() {
    final rolesRaw =
        (_visitorTypeDetail?['visitor_roles'] ??
                _selectedVisitorType?['visitor_roles'])
            as List<dynamic>?;
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

  String _getDefaultVisitorRole() {
    if (_singleRole != null && _singleRole!.isNotEmpty) {
      return _singleRole!;
    }
    final rolesRaw =
        (_visitorTypeDetail?['visitor_roles'] ??
                _selectedVisitorType?['visitor_roles'])
            as List<dynamic>?;
    if (rolesRaw != null && rolesRaw.isNotEmpty) {
      final defaultRole = rolesRaw.firstWhereOrNull(
        (r) => r['is_default'] == true,
      );
      if (defaultRole != null) {
        return (defaultRole['role'] ?? 'Visitor').toString();
      }
      return (rolesRaw.first['role'] ?? 'Visitor').toString();
    }
    return 'Visitor';
  }

  List<Map<String, dynamic>> _getVisitorInfoPraFormFields() {
    final sectionsRaw =
        _visitorTypeDetail?['section_page_visitor_types'] as List<dynamic>?;
    if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
      for (var s in sectionsRaw) {
        final sec = Map<String, dynamic>.from(s as Map);
        final isDoc = sec['is_document'] == true;
        if (isDoc) continue;
        final secName = (sec['name'] ?? '').toString().toLowerCase();
        if (secName.contains('visitor info') || sec['sort'] == 0) {
          final praForm = sec['pra_form'] as List<dynamic>? ?? [];
          return praForm
              .where((f) => f['is_enable'] == true)
              .map((f) => Map<String, dynamic>.from(f as Map))
              .toList();
        }
      }
    }
    // Fallback standard fields if detail not yet loaded
    return [
      {
        'remarks': 'name',
        'long_display_text': 'Full Name',
        'mandatory': true,
        'field_type': 0,
      },
      {
        'remarks': 'email',
        'long_display_text': 'Email',
        'mandatory': true,
        'field_type': 2,
      },
      {
        'remarks': 'organization',
        'long_display_text': 'Department / Organization / Company',
        'mandatory': true,
        'field_type': 0,
      },
      {
        'remarks': 'phone',
        'long_display_text': 'Phone',
        'mandatory': true,
        'field_type': 0,
      },
      {
        'remarks': 'indentity_id',
        'long_display_text': 'Identity (KTP)',
        'mandatory': true,
        'field_type': 0,
      },
    ];
  }

  List<Map<String, dynamic>> _getPurposeVisitPraFormFields() {
    final sectionsRaw =
        _visitorTypeDetail?['section_page_visitor_types'] as List<dynamic>?;
    if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
      for (var s in sectionsRaw) {
        final sec = Map<String, dynamic>.from(s as Map);
        final isDoc = sec['is_document'] == true;
        if (isDoc) continue;
        final secName = (sec['name'] ?? '').toString().toLowerCase();
        if (secName.contains('purpose') || sec['sort'] == 1) {
          final praForm = sec['pra_form'] as List<dynamic>? ?? [];
          return praForm
              .where((f) => f['is_enable'] == true)
              .map((f) => Map<String, dynamic>.from(f as Map))
              .toList();
        }
      }
    }
    // Fallback standard purpose fields
    return [
      {
        'remarks': 'site_place',
        'long_display_text': 'Destination',
        'mandatory': true,
        'field_type': 3,
      },
      {
        'remarks': 'host',
        'long_display_text': 'PIC Host',
        'mandatory': true,
        'field_type': 3,
      },
      {
        'remarks': 'agenda',
        'long_display_text': 'Agenda',
        'mandatory': true,
        'field_type': 0,
      },
      {
        'remarks': 'visitor_period_start',
        'long_display_text': 'Visit Start',
        'mandatory': true,
        'field_type': 9,
      },
      {
        'remarks': 'visitor_period_end',
        'long_display_text': 'Visit End',
        'mandatory': true,
        'field_type': 9,
      },
    ];
  }

  bool get _isStep1Valid => _selectedVisitorType != null && _isGroup != null;

  bool get _isStep2Valid {
    final fields = _getVisitorInfoPraFormFields();
    if (_isGroup == true) {
      if (_groupNameController.text.trim().isEmpty) {
        return false;
      }
      if (_groupVisitors.isEmpty) {
        return false;
      }
      for (final v in _groupVisitors) {
        for (final f in fields) {
          final isMandatory = f['mandatory'] == true;
          if (!isMandatory) {
            continue;
          }
          final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
          if (remarks == 'is_employee' && v.isEmployee == null) {
            return false;
          }
          if (remarks == 'name' && v.fullNameCtrl.text.trim().isEmpty) {
            return false;
          }
          if (remarks == 'email' && v.emailCtrl.text.trim().isEmpty) {
            return false;
          }
          if (remarks == 'phone' && v.phoneCtrl.text.trim().isEmpty) {
            return false;
          }
          if ((remarks == 'organization' || remarks == 'company') &&
              v.orgCtrl.text.trim().isEmpty) {
            return false;
          }
          if ((remarks == 'identity_id' || remarks == 'indentity_id') &&
              v.identityCtrl.text.trim().isEmpty) {
            return false;
          }
          if ((remarks == 'visitor_role' || remarks == 'role') &&
              (v.role == null || v.role!.isEmpty)) {
            return false;
          }
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
            if (v.extraControllers[remarks]?.text.trim().isEmpty ?? true) {
              return false;
            }
          }
        }
      }
      return true;
    } else {
      for (final f in fields) {
        final isMandatory = f['mandatory'] == true;
        if (!isMandatory) {
          continue;
        }
        final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
        if (remarks == 'is_employee' && _singleIsEmployee == null) {
          return false;
        }
        if (remarks == 'name' && _singleFullNameCtrl.text.trim().isEmpty) {
          return false;
        }
        if (remarks == 'email' && _singleEmailCtrl.text.trim().isEmpty) {
          return false;
        }
        if (remarks == 'phone' && _singlePhoneCtrl.text.trim().isEmpty) {
          return false;
        }
        if ((remarks == 'organization' || remarks == 'company') &&
            _singleOrgCtrl.text.trim().isEmpty) {
          return false;
        }
        if ((remarks == 'identity_id' || remarks == 'indentity_id') &&
            _singleIdentityCtrl.text.trim().isEmpty) {
          return false;
        }
        if ((remarks == 'visitor_role' || remarks == 'role') &&
            (_singleRole == null || _singleRole!.isEmpty)) {
          return false;
        }
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
          if (_singleExtraControllers[remarks]?.text.trim().isEmpty ?? true) {
            return false;
          }
        }
      }
      return true;
    }
  }

  bool get _isStep3Valid {
    final fields = _getPurposeVisitPraFormFields();
    if (fields.isEmpty) {
      if (_selectedDestination == null) {
        return false;
      }
      if (_selectedPicHost == null) {
        return false;
      }
      if (_selectedAgenda == null || _selectedAgenda!.isEmpty) {
        return false;
      }
      if (_selectedAgenda == 'Others' &&
          _otherAgendaController.text.trim().isEmpty) {
        return false;
      }
      if (_visitStart == null) {
        return false;
      }
      if (_visitEnd == null) {
        return false;
      }
      if (_visitEnd!.isBefore(_visitStart!) ||
          _visitEnd!.isAtSameMomentAs(_visitStart!)) {
        return false;
      }
      return true;
    }

    for (final f in fields) {
      final isMandatory = f['mandatory'] == true;
      if (!isMandatory) {
        continue;
      }
      final remarks = (f['remarks'] ?? '').toString().toLowerCase().trim();
      if ((remarks == 'site_place' || remarks == 'destination') &&
          _selectedDestination == null) {
        return false;
      }
      if ((remarks == 'host' || remarks == 'pic_host') &&
          _selectedPicHost == null) {
        return false;
      }
      if (remarks == 'agenda') {
        if (_selectedAgenda == null || _selectedAgenda!.isEmpty) {
          return false;
        }
        if (_selectedAgenda == 'Others' &&
            _otherAgendaController.text.trim().isEmpty) {
          return false;
        }
      }
      if (remarks == 'visitor_period_start' && _visitStart == null) {
        return false;
      }
      if (remarks == 'visitor_period_end' && _visitEnd == null) {
        return false;
      }
      if (remarks != 'site_place' &&
          remarks != 'destination' &&
          remarks != 'host' &&
          remarks != 'pic_host' &&
          remarks != 'agenda' &&
          remarks != 'visitor_period_start' &&
          remarks != 'visitor_period_end') {
        if (_purposeExtraControllers[remarks]?.text.trim().isEmpty ?? true) {
          return false;
        }
      }
    }
    if (_visitStart != null && _visitEnd != null) {
      if (_visitEnd!.isBefore(_visitStart!) ||
          _visitEnd!.isAtSameMomentAs(_visitStart!)) {
        return false;
      }
    }
    return true;
  }

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
      _singleFullNameCtrl.text = (item['name'] ?? item['visitor_name'] ?? '')
          .toString();
      _singleEmailCtrl.text = (item['email'] ?? '').toString();
      _singlePhoneCtrl.text = (item['phone'] ?? '').toString();
      _singleOrgCtrl.text = _extractOrganizationName(
        item['Organization'] ?? item['organization'],
        item['company'],
      );
      _singleIdentityCtrl.text =
          (item['identity_id'] ?? item['nik'] ?? item['indentity_id'] ?? '')
              .toString();
      _singleSearchCtrl.text = _singleFullNameCtrl.text;
      _singleIsSearchOpen = false;
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
      _singleIsSearchOpen = false;
    });
  }

  void _onGroupSelect(int index, Map<String, dynamic> item) {
    final entry = _groupVisitors[index];
    setState(() {
      entry.selectedData = item;
      entry.fullNameCtrl.text = (item['name'] ?? item['visitor_name'] ?? '')
          .toString();
      entry.emailCtrl.text = (item['email'] ?? '').toString();
      entry.phoneCtrl.text = (item['phone'] ?? '').toString();
      entry.orgCtrl.text = _extractOrganizationName(
        item['Organization'] ?? item['organization'],
        item['company'],
      );
      entry.identityCtrl.text =
          (item['identity_id'] ?? item['nik'] ?? item['indentity_id'] ?? '')
              .toString();
      entry.searchCtrl.text = entry.fullNameCtrl.text;
      entry.isSearchOpen = false;
    });
  }

  void _clearGroup(int index) {
    final entry = _groupVisitors[index];
    setState(() {
      entry.selectedData = null;
      entry.searchCtrl.clear();
      entry.fullNameCtrl.clear();
      entry.emailCtrl.clear();
      entry.phoneCtrl.clear();
      entry.orgCtrl.clear();
      entry.identityCtrl.clear();
      for (final c in entry.extraControllers.values) {
        c.clear();
      }
      entry.isSearchOpen = false;
    });
  }

  void _addGroupVisitor() {
    setState(() {
      final entry = GroupVisitorEntry();
      entry.isEmployee = false;
      entry.role = null;
      _groupVisitors.add(entry);
    });
  }

  void _removeGroupVisitor(int index) {
    if (_groupVisitors.length <= 1) return;
    setState(() {
      _groupVisitors[index].dispose();
      _groupVisitors.removeAt(index);
    });
  }

  void _goToNextStep() {
    if (_currentStep == 1) {
      if (_selectedVisitorType == null || _isGroup == null) {
        AppSnackbar.warning(
          title: 'Selection Required',
          message:
              'Please select both Visitor Type and Status Visitor to continue.',
        );
        return;
      }
      if (_currentStep + 1 > _maxStepReached) {
        _maxStepReached = _currentStep + 1;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      final fields = _getVisitorInfoPraFormFields();
      final isEmpField = fields.firstWhereOrNull(
        (f) =>
            (f['remarks'] ?? '').toString().toLowerCase().trim() ==
            'is_employee',
      );

      if (_isGroup == true) {
        if (_groupNameController.text.trim().isEmpty) {
          AppSnackbar.warning(
            title: 'Group Name Required',
            message: 'Please enter a Group Name for this group visit.',
          );
          return;
        }
        if (isEmpField != null && isEmpField['mandatory'] == true) {
          for (int i = 0; i < _groupVisitors.length; i++) {
            if (_groupVisitors[i].isEmployee == null) {
              AppSnackbar.warning(
                title: 'Employee Status Required',
                message:
                    'Please specify whether Visitor ${i + 1} is an Employee (Yes / No).',
              );
              return;
            }
          }
        }
        for (int i = 0; i < _groupVisitors.length; i++) {
          if (!_groupVisitors[i].isValid) {
            AppSnackbar.warning(
              title: 'Incomplete Visitor ${i + 1}',
              message:
                  'Please complete all required fields for Visitor ${i + 1}.',
            );
            return;
          }
        }
      } else {
        if (isEmpField != null &&
            isEmpField['mandatory'] == true &&
            _singleIsEmployee == null) {
          AppSnackbar.warning(
            title: 'Employee Status Required',
            message: 'Please specify whether you are an Employee (Yes / No).',
          );
          return;
        }
        if (_singleFullNameCtrl.text.trim().isEmpty) {
          AppSnackbar.warning(
            title: 'Full Name Required',
            message: 'Please enter the visitor\'s full name.',
          );
          return;
        }
      }
      if (_currentStep + 1 > _maxStepReached) {
        _maxStepReached = _currentStep + 1;
      }
      setState(() => _currentStep = 3);
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  String _formatDateTime(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayName, ${dt.day} $monthName ${dt.year}, $hour:$minute';
  }

  List<Map<String, dynamic>> _buildDynamicQuestionPage({
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
  }) {
    final startIso = start != null
        ? start.toUtc().toIso8601String().substring(0, 19)
        : DateTime.now().toUtc().toIso8601String().substring(0, 19);
    final endIso = end != null
        ? end.toUtc().toIso8601String().substring(0, 19)
        : DateTime.now()
              .add(const Duration(hours: 2))
              .toUtc()
              .toIso8601String()
              .substring(0, 19);

    final sectionsRaw =
        _visitorTypeDetail?['section_page_visitor_types'] as List<dynamic>?;

    if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
      final List<Map<String, dynamic>> dynamicSections = [];

      for (var s in sectionsRaw) {
        final sec = Map<String, dynamic>.from(s as Map);
        final secId = (sec['Id'] ?? sec['id'] ?? '').toString();
        final secName = (sec['name'] ?? '').toString();
        final isDoc = sec['is_document'] == true;
        if (isDoc) {
          continue; // Pra-registration only submits non-document question pages
        }

        final praForm = sec['pra_form'] as List<dynamic>? ?? [];
        if (praForm.isEmpty) {
          continue; // Strictly use pra_form
        }

        final List<Map<String, dynamic>> formFields = [];

        for (var f in praForm) {
          final field = Map<String, dynamic>.from(f as Map);
          final isEnable = field['is_enable'] == true;
          if (!isEnable) {
            continue;
          }

          final remarks = (field['remarks'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final fieldType = field['field_type'] is int
              ? field['field_type'] as int
              : int.tryParse(field['field_type']?.toString() ?? '0') ?? 0;

          final isDateTimeField =
              fieldType == 4 ||
              fieldType == 9 ||
              remarks == 'visitor_period_start' ||
              remarks == 'visitor_period_end';

          String answerText = '';
          String answerDatetime = '';

          if (remarks == 'visitor_period_start') {
            answerDatetime = startIso;
          } else if (remarks == 'visitor_period_end') {
            answerDatetime = endIso;
          } else if (remarks == 'name') {
            answerText = name;
          } else if (remarks == 'email') {
            answerText = email;
          } else if (remarks == 'phone') {
            answerText = phone;
          } else if (remarks == 'organization' || remarks == 'company') {
            answerText = org;
          } else if (remarks == 'identity_id' || remarks == 'indentity_id') {
            answerText = identity;
          } else if (remarks == 'is_employee') {
            final isEmp = isEmployee;
            final target = isEmp ? 'yes' : 'no';
            final multipleOptions =
                field['multiple_option_fields'] as List<dynamic>? ?? [];
            final opt = multipleOptions.firstWhereOrNull(
              (o) =>
                  (o['name'] ?? '').toString().toLowerCase() == target ||
                  (o['value'] ?? '').toString().toLowerCase() == target,
            );
            if (opt != null) {
              answerText = (opt['value'] ?? opt['name'] ?? isEmp).toString();
            } else {
              answerText = isEmp ? 'true' : 'false';
            }
          } else if (remarks == 'employee' || remarks == 'employee_name') {
            answerText = employeeId;
          } else if (remarks == 'visitor_role' || remarks == 'role') {
            answerText = role ?? _getDefaultVisitorRole();
          } else if (remarks == 'host') {
            answerText = hostId;
          } else if (remarks == 'agenda') {
            answerText = agenda;
          } else if (remarks == 'site_place' || remarks == 'destination') {
            answerText = siteId;
          } else {
            answerText =
                extraCtrls[remarks]?.text.trim() ??
                (field['answer_text'] ?? '').toString();
          }

          final Map<String, dynamic> formJson = {
            'sort': field['sort'] ?? 0,
            'short_name': field['short_name'] ?? '',
            'long_display_text': field['long_display_text'] ?? '',
            'field_type': fieldType,
            'is_primary': field['is_primary'] ?? false,
            'is_enable': true,
            'mandatory': field['mandatory'] ?? false,
            'remarks': field['remarks'] ?? '',
            'custom_field_id': field['custom_field_id'] ?? '',
            'multiple_option_fields': field['multiple_option_fields'] ?? [],
            'visitor_form_type': field['visitor_form_type'] ?? 0,
          };

          if (isDateTimeField && answerDatetime.isNotEmpty) {
            formJson['answer_datetime'] = answerDatetime;
            formJson['answer_text'] = '';
          } else {
            formJson['answer_text'] = answerText;
          }

          formFields.add(formJson);
        }

        if (formFields.isNotEmpty) {
          dynamicSections.add({
            'id': secId,
            'sort': sec['sort'] ?? 0,
            'name': secName,
            'status': 0,
            'is_document': sec['is_document'] ?? false,
            'can_multiple_used': sec['can_multiple_used'] ?? false,
            'self_only': false,
            'foreign_id': sec['foreign_id'] ?? '',
            'form': formFields,
          });
        }
      }

      if (dynamicSections.isNotEmpty) {
        return dynamicSections;
      }
    }

    // Static fallback
    return [
      {
        'id': '54227c9b-39f6-4b98-92f1-6c94a333da3b',
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
            'long_display_text': 'Full Name',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'name',
            'custom_field_id': 'e953c360-ecfd-4710-90dc-0fab6fb3bfa0',
            'multiple_option_fields': [],
            'visitor_form_type': 0,
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
            'visitor_form_type': 0,
            'answer_text': email,
          },
          {
            'sort': 2,
            'short_name': 'Organization',
            'long_display_text': 'Department / Organization / Company',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'organization',
            'custom_field_id': '7e7a0eee-e2a4-4a9f-85d0-c6dd612b16ac',
            'multiple_option_fields': [],
            'visitor_form_type': 0,
            'answer_text': org,
          },
          {
            'sort': 3,
            'short_name': 'Phone',
            'long_display_text': 'Phone',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'phone',
            'custom_field_id': '08bf266b-a8f0-408a-8639-97ac35615db1',
            'multiple_option_fields': [],
            'visitor_form_type': 0,
            'answer_text': phone,
          },
          {
            'sort': 4,
            'short_name': 'Indentity Id',
            'long_display_text': 'Identity(KTP)',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'indentity_id',
            'custom_field_id': '7b9cd4b9-f6e0-4438-8088-220c8bafaa3f',
            'multiple_option_fields': [],
            'visitor_form_type': 0,
            'answer_text': identity,
          },
        ],
      },
      {
        'id': 'ddf3f81b-d130-4408-a43b-cd2a7d69ffe6',
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
            'short_name': 'Destination',
            'long_display_text': 'Destination',
            'field_type': 3,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'site_place',
            'custom_field_id': '344626ff-f72a-4ae1-83af-f0c8d4441553',
            'multiple_option_fields': [],
            'visitor_form_type': 0,
            'answer_text': siteId,
          },
          {
            'sort': 1,
            'short_name': 'PIC Host',
            'long_display_text': 'PIC Host',
            'field_type': 3,
            'is_primary': true,
            'is_enable': true,
            'mandatory': true,
            'remarks': 'host',
            'custom_field_id': 'c52bc3f6-7ee8-49b6-b980-ca01d9967800',
            'multiple_option_fields': [],
            'visitor_form_type': 0,
            'answer_text': hostId,
          },
          {
            'sort': 2,
            'short_name': 'Agenda',
            'long_display_text': 'Agenda',
            'field_type': 0,
            'is_primary': true,
            'is_enable': true,
            'mandatory': false,
            'remarks': 'agenda',
            'custom_field_id': '179eec7f-c1c1-4bd1-8175-9548ebd7e1ce',
            'multiple_option_fields': [],
            'visitor_form_type': 0,
            'answer_text': agenda,
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
            'visitor_form_type': 0,
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
            'visitor_form_type': 0,
            'answer_datetime': endIso,
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

    final visitorTypeId = (_selectedVisitorType?['id'] ?? '').toString();
    final siteId = (_selectedDestination?['id'] ?? '').toString();
    final isChildDestination = _selectedDestination?['is_child'] == true;
    final parentSiteId = (_selectedParentSite?['id'] ??
            _selectedDestination?['parent'] ??
            '')
        .toString();
    final registeredSiteId =
        (isChildDestination && _isParentSiteChecked && parentSiteId.isNotEmpty)
            ? parentSiteId
            : siteId;
    final hostId = (_selectedPicHost?['id'] ?? '').toString();
    final resolvedAgenda = _selectedAgenda == 'Others'
        ? _otherAgendaController.text.trim()
        : _selectedAgenda!;

    _visitorTypeDetail ??= await controller.fetchVisitorTypeDetail(
      visitorTypeId,
    );
    final resolvedRole = _getDefaultVisitorRole();

    Map<String, dynamic> payload;

    if (_isGroup == true) {
      // Group Mode
      final dataVisitors = _groupVisitors.map((v) {
        final memberEmployeeId = (v.isEmployee == true)
            ? (v.selectedData?['id'] ?? v.selectedData?['employee_id'] ?? '')
                  .toString()
            : '';
        return {
          'question_page': _buildDynamicQuestionPage(
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
          ),
        };
      }).toList();

      final groupObject = {
        'visitor_type': visitorTypeId,
        'is_group': true,
        'type_registered': 0,
        'tz': 'Asia/Jakarta',
        if (registeredSiteId.isNotEmpty) 'registered_site': registeredSiteId,
        'group_code': _groupCode,
        'group_name': _groupNameController.text.trim(),
        'flow': 'Praregister',
        'visitor_role': _groupVisitors.first.role ?? resolvedRole,
        'data_visitor': dataVisitors,
      };

      payload = {
        'list_group': [groupObject],
      };
    } else {
      // Single Mode
      final singleEmployeeId = (_singleIsEmployee == true)
          ? (_singleSelectedData?['id'] ??
                    _singleSelectedData?['employee_id'] ??
                    '')
                .toString()
            : '';

      final singleQuestionPage = _buildDynamicQuestionPage(
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
      );

      payload = {
        'visitor_type': visitorTypeId,
        'type_registered': 0,
        'is_group': false,
        'tz': 'Asia/Jakarta',
        'flow': 'Praregister',
        'visitor_role': _singleRole ?? resolvedRole,
        if (registeredSiteId.isNotEmpty) 'registered_site': registeredSiteId,
        'data_visitor': [
          {'question_page': singleQuestionPage},
        ],
      };
    }

    final success = await controller.submitOperatorPraRegistration(
      payload: payload,
      isGroup: _isGroup == true,
      isWalkIn: widget.isWalkIn,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1040,
      height: 660,
      constraints: const BoxConstraints(maxHeight: 720),
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
          _buildStepper(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: Builder(
              builder: (context) {
                switch (_currentStep) {
                  case 1:
                    return _buildStep1UserType();
                  case 2:
                    return (_isGroup == true)
                        ? _buildStep2GroupVisitorInfo()
                        : _buildStep2SingleVisitorInfo();
                  case 3:
                    return _buildStep3PurposeVisit();
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
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
            widget.isWalkIn ? 'Add Walk In' : 'Add Pra Registration',
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
            icon: const Icon(
              Icons.close_rounded,
              size: 22,
              color: Color(0xFF64748B),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final showAllSteps = _selectedVisitorType != null || _currentStep >= 2;

    return Container(
      color: const Color(0xFFFAFCFF),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(1, 'User Type'),
          if (showAllSteps) ...[
            _buildStepConnector(1),
            _buildStepItem(2, 'Visitor Information'),
            _buildStepConnector(2),
            _buildStepItem(3, 'Purpose Visit'),
          ],
        ],
      ),
    );
  }

  bool _isStepCompleted(int stepNum) {
    if (stepNum == _currentStep) return false;
    if (stepNum > _maxStepReached) return false;
    if (stepNum == 1)
      return _isStep1Valid && (_currentStep > 1 || _maxStepReached > 1);
    if (stepNum == 2)
      return _isStep1Valid &&
          _isStep2Valid &&
          (_currentStep > 2 || _maxStepReached > 2);
    if (stepNum == 3)
      return _isStep1Valid &&
          _isStep2Valid &&
          _isStep3Valid &&
          (_currentStep > 3 || _maxStepReached > 3);
    return false;
  }

  bool _canJumpToStep(int stepNum) {
    if (_currentStep == stepNum) return false;
    if (stepNum == 1) return true;
    if (stepNum == 2) return _isStep1Valid;
    if (stepNum == 3) return _isStep1Valid && _isStep2Valid;
    return false;
  }

  Widget _buildStepItem(int stepNumber, String title) {
    final isActive = _currentStep == stepNumber;
    final isCompleted = _isStepCompleted(stepNumber);
    final canJump = _canJumpToStep(stepNumber);
    final showCheckmark = isCompleted && !isActive;

    return MouseRegion(
      cursor: canJump ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: canJump
            ? () => setState(() {
                if (stepNumber > _maxStepReached) {
                  _maxStepReached = stepNumber;
                }
                _currentStep = stepNumber;
              })
            : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isCompleted
                      ? const Color(0xFF004385)
                      : (canJump
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFFCBD5E1)),
                ),
                child: Center(
                  child: showCheckmark
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '$stepNumber',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
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
  }

  Widget _buildStepConnector(int stepBefore) {
    bool isCompleted = false;
    if (stepBefore == 1) {
      isCompleted =
          _isStep1Valid && (_currentStep >= 2 || _maxStepReached >= 2);
    } else if (stepBefore == 2) {
      isCompleted =
          _isStep1Valid &&
          _isStep2Valid &&
          (_currentStep >= 3 || _maxStepReached >= 3);
    }

    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: isCompleted ? const Color(0xFF004385) : const Color(0xFFE2E8F0),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: User Type
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1UserType() {
    final List<Map<String, dynamic>> visitorTypes =
        controller.rxPraRegVisitorTypes.isNotEmpty
        ? controller.rxPraRegVisitorTypes.toList()
        : <Map<String, dynamic>>[
            {
              'name': 'All Access (VIP)',
              'id': '29b12a27-cff3-44dc-be0f-4a743510b836',
            },
            {'name': 'CIT', 'id': '0eac503e-d0c9-4ba5-afac-99a0b94e44f3'},
            {
              'name': 'General Visitor',
              'id': '1e7ab7a0-1fdd-4546-b65f-6a8dcc345148',
            },
            {
              'name': 'Non Remise',
              'id': '3e903b97-bb4a-42bb-a840-b2316202ea7d',
            },
            {'name': 'Remise', 'id': 'f0bd33a4-427a-4110-ab19-6e423dafa3e5'},
            {'name': 'Staff', 'id': '2e8a7639-84f9-42ab-8096-304c259245db'},
            {'name': 'Umum', 'id': 'e0533de1-52a7-4b47-8e80-79239d8f723d'},
            {
              'name': 'Utility Maintenance',
              'id': 'b3618bd5-b6f0-4329-9cf5-6c853970217d',
            },
            {
              'name': 'Visitor Resident',
              'id': '4bd22555-12fc-4aea-84a3-2163fe7dadc7',
            },
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
              final isSelected =
                  _selectedVisitorType != null &&
                  _selectedVisitorType!['id'] == type['id'];
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _onVisitorTypeSelected(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF004385)
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: isSelected
                            ? const Color(0xFF004385)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type['name']?.toString() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF004385)
                              : const Color(0xFF1E293B),
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
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
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
            color: isSelected
                ? const Color(0xFF004385)
                : const Color(0xFFCBD5E1),
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
                color: isSelected
                    ? const Color(0xFF004385)
                    : const Color(0xFFF1F5F9),
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
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected
                  ? const Color(0xFF004385)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Single Visitor Mode (Purely Dynamic from pra_form)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2SingleVisitorInfo() {
    final fields = _getVisitorInfoPraFormFields();
    final employees = controller.rxPraRegEmployees;
    final visitors = controller.rxPraRegVisitors;
    final searchList = _singleIsEmployee == true ? employees : visitors;
    final searchQuery = _singleSearchCtrl.text.trim().toLowerCase();

    final filtered = searchList.where((it) {
      if (searchQuery.isEmpty) return true;
      final name = (it['name'] ?? it['visitor_name'] ?? '')
          .toString()
          .toLowerCase();
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
          // Top Search Bar (Search Employee / Search Visitor)
          _buildSearchInput(
            hint: _singleIsEmployee == true
                ? 'Search Employee'
                : 'Search Visitor',
            controller: _singleSearchCtrl,
            isSearchOpen: _singleIsSearchOpen,
            selectedData: _singleSelectedData,
            filteredItems: filtered,
            isEmployeeMode: _singleIsEmployee == true,
            onTap: () => setState(() => _singleIsSearchOpen = true),
            onToggleOpen: () =>
                setState(() => _singleIsSearchOpen = !_singleIsSearchOpen),
            onChanged: (val) => setState(() => _singleIsSearchOpen = true),
            onClear: _clearSingle,
            onSelect: _onSingleSelect,
          ),

          const SizedBox(height: 18),

          // Dynamic fields according to pra_form in Visitor Information
          ...fields.map((f) {
            final remarks = (f['remarks'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            var label = (f['long_display_text'] ?? f['short_name'] ?? '')
                .toString();
            final isMandatory = f['mandatory'] == true;

            if (remarks == 'is_employee') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormFieldLabel(
                      label.isNotEmpty ? label : 'Are you Employee?',
                      isRequired: isMandatory,
                    ),
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
                    _buildFormFieldLabel(
                      label.isNotEmpty ? label : 'Role',
                      isRequired: isMandatory,
                    ),
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

            if (remarks == 'organization' ||
                remarks == 'company' ||
                label.toLowerCase().contains('inst')) {
              label = 'Department / Organization / Company';
            }

            TextEditingController targetCtrl;
            String hintText;

            if (remarks == 'name') {
              targetCtrl = _singleFullNameCtrl;
              hintText =
                  'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'full name'}';
            } else if (remarks == 'email') {
              targetCtrl = _singleEmailCtrl;
              hintText = 'Example: name@gmail.com';
            } else if (remarks == 'organization' || remarks == 'company') {
              targetCtrl = _singleOrgCtrl;
              hintText = 'Enter your department / organization / company';
            } else if (remarks == 'phone') {
              targetCtrl = _singlePhoneCtrl;
              hintText =
                  'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'phone'}';
            } else if (remarks == 'indentity_id' || remarks == 'identity_id') {
              targetCtrl = _singleIdentityCtrl;
              hintText =
                  'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'identity (ktp)'}';
            } else {
              _singleExtraControllers.putIfAbsent(
                remarks,
                () => TextEditingController(),
              );
              targetCtrl = _singleExtraControllers[remarks]!;
              hintText =
                  'Enter your ${label.isNotEmpty ? label.toLowerCase() : remarks}';
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
  // Step 2: Group Visitor Mode (Purely Dynamic from pra_form)
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: _addGroupVisitor,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Add Visitor',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
              final searchList = visitor.isEmployee == true
                  ? employees
                  : visitors;
              final searchQuery = visitor.searchCtrl.text.trim().toLowerCase();
              final filtered = searchList.where((it) {
                if (searchQuery.isEmpty) return true;
                final name = (it['name'] ?? it['visitor_name'] ?? '')
                    .toString()
                    .toLowerCase();
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
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            onPressed: () => _removeGroupVisitor(idx),
                          ),
                      ],
                    ),

                    const Divider(height: 16, color: Color(0xFFF1F5F9)),

                    // Search Bar
                    _buildSearchInput(
                      hint: visitor.isEmployee == true
                          ? 'Search Employee'
                          : 'Search Visitor',
                      controller: visitor.searchCtrl,
                      isSearchOpen: visitor.isSearchOpen,
                      selectedData: visitor.selectedData,
                      filteredItems: filtered,
                      isEmployeeMode: visitor.isEmployee == true,
                      onTap: () => setState(() => visitor.isSearchOpen = true),
                      onToggleOpen: () => setState(
                        () => visitor.isSearchOpen = !visitor.isSearchOpen,
                      ),
                      onChanged: (val) =>
                          setState(() => visitor.isSearchOpen = true),
                      onClear: () => _clearGroup(idx),
                      onSelect: (item) => _onGroupSelect(idx, item),
                    ),

                    const SizedBox(height: 12),

                    ...fields.map((f) {
                      final remarks = (f['remarks'] ?? '')
                          .toString()
                          .toLowerCase()
                          .trim();
                      var label =
                          (f['long_display_text'] ?? f['short_name'] ?? '')
                              .toString();
                      final isMandatory = f['mandatory'] == true;

                      if (remarks == 'is_employee') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormFieldLabel(
                                label.isNotEmpty ? label : 'Are you Employee?',
                                isRequired: isMandatory,
                              ),
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
                              _buildFormFieldLabel(
                                label.isNotEmpty ? label : 'Role',
                                isRequired: isMandatory,
                              ),
                              const SizedBox(height: 6),
                              _buildCleanDropdownField<String>(
                                hint:
                                    'Select ${label.isNotEmpty ? label : 'Role'}',
                                selectedValue: visitor.role,
                                items: roles.map((r) {
                                  return DropdownMenuItemData<String>(
                                    value: r,
                                    label: r,
                                  );
                                }).toList(),
                                onSelected: (val) =>
                                    setState(() => visitor.role = val),
                              ),
                            ],
                          ),
                        );
                      }

                      if (remarks == 'organization' ||
                          remarks == 'company' ||
                          label.toLowerCase().contains('inst')) {
                        label = 'Department / Organization / Company';
                      }

                      TextEditingController targetCtrl;
                      String hintText;

                      if (remarks == 'name') {
                        targetCtrl = visitor.fullNameCtrl;
                        hintText =
                            'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'full name'}';
                      } else if (remarks == 'email') {
                        targetCtrl = visitor.emailCtrl;
                        hintText = 'Example: name@gmail.com';
                      } else if (remarks == 'organization' ||
                          remarks == 'company') {
                        targetCtrl = visitor.orgCtrl;
                        hintText =
                            'Enter your department / organization / company';
                      } else if (remarks == 'phone') {
                        targetCtrl = visitor.phoneCtrl;
                        hintText =
                            'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'phone'}';
                      } else if (remarks == 'indentity_id' ||
                          remarks == 'identity_id') {
                        targetCtrl = visitor.identityCtrl;
                        hintText =
                            'Enter your ${label.isNotEmpty ? label.toLowerCase() : 'identity (ktp)'}';
                      } else {
                        visitor.extraControllers.putIfAbsent(
                          remarks,
                          () => TextEditingController(),
                        );
                        targetCtrl = visitor.extraControllers[remarks]!;
                        hintText =
                            'Enter your ${label.isNotEmpty ? label.toLowerCase() : remarks}';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormFieldLabel(
                              label,
                              isRequired: isMandatory,
                            ),
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
  // Step 3: Purpose Visit (Purely Dynamic from pra_form)
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
          final label = (f['long_display_text'] ?? f['short_name'] ?? '')
              .toString();
          final isMandatory = f['mandatory'] == true;

          if (remarks == 'site_place' || remarks == 'destination') {
            final isChildSite = _selectedDestination?['is_child'] == true;
            final parentId = (_selectedDestination?['parent'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            final parentSite = isChildSite && parentId.isNotEmpty
                ? sites.firstWhereOrNull(
                    (s) =>
                        (s['id'] ?? '').toString().trim().toLowerCase() ==
                        parentId,
                  )
                : null;

            final currentSiteId = (_selectedDestination?['id'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            final childBuildings = (!isChildSite && currentSiteId.isNotEmpty)
                ? sites
                    .where(
                      (s) =>
                          (s['parent'] ?? '')
                              .toString()
                              .trim()
                              .toLowerCase() ==
                          currentSiteId,
                    )
                    .toList()
                : <Map<String, dynamic>>[];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(
                    label.isNotEmpty ? label : 'Destination',
                    isRequired: isMandatory,
                    showInfo: true,
                  ),
                  const SizedBox(height: 6),
                  _buildCleanDropdownField<Map<String, dynamic>>(
                    hint: 'Select Site',
                    selectedValue: _selectedDestination,
                    items: sites.map((s) {
                      final isChild = s['is_child'] == true;
                      final pId = (s['parent'] ?? '')
                          .toString()
                          .trim()
                          .toLowerCase();
                      final parent = isChild && pId.isNotEmpty
                          ? sites.firstWhereOrNull(
                              (p) =>
                                  (p['id'] ?? '')
                                      .toString()
                                      .trim()
                                      .toLowerCase() ==
                                  pId,
                            )
                          : null;
                      final sName = s['name']?.toString() ?? 'Site';
                      final displayLabel = (isChild && parent != null)
                          ? '$sName, ${parent['name']}'
                          : sName;

                      return DropdownMenuItemData<Map<String, dynamic>>(
                        value: s,
                        label: displayLabel,
                      );
                    }).toList(),
                    onSelected: (val) {
                      setState(() {
                        _selectedDestination = val;
                        if (val['is_child'] == true) {
                          final pId = (val['parent'] ?? '')
                              .toString()
                              .trim()
                              .toLowerCase();
                          _selectedParentSite = sites.firstWhereOrNull(
                            (s) =>
                                (s['id'] ?? '')
                                    .toString()
                                    .trim()
                                    .toLowerCase() ==
                                pId,
                          );
                          _isParentSiteChecked = true;
                          _selectedChildBuilding = null;
                          _isChildBuildingChecked = false;
                        } else {
                          final cId = (val['id'] ?? '')
                              .toString()
                              .trim()
                              .toLowerCase();
                          final children = sites
                              .where(
                                (s) =>
                                    (s['parent'] ?? '')
                                        .toString()
                                        .trim()
                                        .toLowerCase() ==
                                    cId,
                              )
                              .toList();
                          _selectedParentSite = null;
                          _isParentSiteChecked = false;
                          _selectedChildBuilding =
                              children.isNotEmpty ? children.first : null;
                          _isChildBuildingChecked = false;
                        }
                      });
                    },
                  ),
                  if (isChildSite && parentSite != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isParentSiteChecked
                              ? const Color(0xFF004385).withValues(alpha: 0.35)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () =>
                                    _isParentSiteChecked =
                                        !_isParentSiteChecked,
                              );
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _isParentSiteChecked,
                                    activeColor: const Color(0xFF004385),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(
                                        () =>
                                            _isParentSiteChecked =
                                                val ?? true,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Parent Site',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isParentSiteChecked) ...[
                            const SizedBox(height: 8),
                            _buildCleanDropdownField<Map<String, dynamic>>(
                              hint: 'Select Parent Site',
                              selectedValue: _selectedParentSite ?? parentSite,
                              showSearch: false,
                              items: [
                                DropdownMenuItemData<Map<String, dynamic>>(
                                  value: parentSite,
                                  label:
                                      parentSite['name']?.toString() ??
                                      'Parent Site',
                                ),
                              ],
                              onSelected: (val) {
                                setState(() => _selectedParentSite = val);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (!isChildSite && childBuildings.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isChildBuildingChecked
                              ? const Color(0xFF004385).withValues(alpha: 0.35)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () =>
                                    _isChildBuildingChecked =
                                        !_isChildBuildingChecked,
                              );
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _isChildBuildingChecked,
                                    activeColor: const Color(0xFF004385),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(
                                        () =>
                                            _isChildBuildingChecked =
                                                val ?? false,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Building / Sub-Location',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isChildBuildingChecked) ...[
                            const SizedBox(height: 8),
                            _buildCleanDropdownField<Map<String, dynamic>>(
                              hint: 'Select Building',
                              selectedValue:
                                  _selectedChildBuilding ?? childBuildings.first,
                              showSearch: false,
                              items: childBuildings.map((b) {
                                return DropdownMenuItemData<
                                  Map<String, dynamic>
                                >(
                                  value: b,
                                  label: b['name']?.toString() ?? 'Building',
                                );
                              }).toList(),
                              onSelected: (val) {
                                setState(() => _selectedChildBuilding = val);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
                  _buildFormFieldLabel(
                    label.isNotEmpty ? label : 'PIC Host',
                    isRequired: isMandatory,
                    showInfo: true,
                  ),
                  const SizedBox(height: 6),
                  _buildCleanDropdownField<Map<String, dynamic>>(
                    hint: 'Select PIC Host',
                    selectedValue: _selectedPicHost,
                    showSearch: false,
                    items: hosts.map((e) {
                      final eName = (e['name'] ?? 'Host').toString();
                      String orgName = '';
                      final rawOrg = e['Organization'] ?? e['organization'];
                      if (rawOrg is Map) {
                        orgName = (rawOrg['name'] ?? rawOrg['code'] ?? '')
                            .toString();
                      } else if (rawOrg is String && !rawOrg.startsWith('{')) {
                        orgName = rawOrg;
                      } else if (e['organization_name'] != null) {
                        orgName = e['organization_name'].toString();
                      }
                      final itemLabel = orgName.isNotEmpty
                          ? '$eName ($orgName)'
                          : eName;
                      return DropdownMenuItemData<Map<String, dynamic>>(
                        value: e,
                        label: itemLabel,
                      );
                    }).toList(),
                    onSelected: (val) => setState(() => _selectedPicHost = val),
                  ),
                ],
              ),
            );
          }

          if (remarks == 'agenda') {
            final dynamicOpts = (f['multiple_option_fields'] as List?)
                ?.map((e) => (e is Map ? (e['name'] ?? e['value'] ?? '') : e.toString()).toString().trim())
                .where((s) => s.isNotEmpty)
                .toList();
            final agendaList = (dynamicOpts != null && dynamicOpts.isNotEmpty)
                ? dynamicOpts
                : List<String>.from(_agendaOptions);
            if (!agendaList.contains('Others')) {
              agendaList.add('Others');
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormFieldLabel(
                    label.isNotEmpty ? label : 'Agenda',
                    isRequired: isMandatory,
                    showInfo: true,
                  ),
                  const SizedBox(height: 6),
                  _buildCleanDropdownField<String>(
                    hint: 'Select Agenda',
                    selectedValue: _selectedAgenda,
                    showSearch: false,
                    items: agendaList.map((agenda) {
                      return DropdownMenuItemData<String>(
                        value: agenda,
                        label: agenda,
                      );
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
                  _buildFormFieldLabel(
                    label.isNotEmpty ? label : 'Visit Start',
                    isRequired: isMandatory,
                    showInfo: true,
                  ),
                  const SizedBox(height: 6),
                  _buildDateTimePickerField(
                    value: _visitStart,
                    title: 'Select Visit Start',
                    onChanged: (dt) {
                      setState(() {
                        _visitStart = dt;
                        if (_visitEnd != null &&
                            (_visitEnd!.isBefore(dt) ||
                                _visitEnd!.isAtSameMomentAs(dt))) {
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
                  _buildFormFieldLabel(
                    label.isNotEmpty ? label : 'Visit End',
                    isRequired: isMandatory,
                    showInfo: true,
                  ),
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

          // Any other dynamic field in purpose visit pra_form
          _purposeExtraControllers.putIfAbsent(
            remarks,
            () => TextEditingController(),
          );
          final targetCtrl = _purposeExtraControllers[remarks]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormFieldLabel(
                  label,
                  isRequired: isMandatory,
                  showInfo: true,
                ),
                const SizedBox(height: 6),
                _buildTextInputField(
                  controller: targetCtrl,
                  hint: 'Enter $label',
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected
                ? const Color(0xFF004385)
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
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
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedData != null || controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      tooltip: 'Clear',
                      onPressed: onClear,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
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
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF004385),
                  width: 1.5,
                ),
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
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final it = filteredItems[index];
                final name = (it['name'] ?? it['visitor_name'] ?? 'User')
                    .toString();
                final email = (it['email'] ?? '-').toString();
                final phone = (it['phone'] ?? '-').toString();
                final org = _extractOrganizationName(
                  it['Organization'] ?? it['organization'],
                  it['company'],
                );

                return InkWell(
                  onTap: () => onSelect(it),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: Icon(
                            isEmployeeMode
                                ? Icons.badge_outlined
                                : Icons.person_outline,
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
                                org.isNotEmpty
                                    ? '$email | $phone ($org)'
                                    : '$email | $phone',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
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
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCleanDropdownField<T>({
    required String hint,
    required T? selectedValue,
    required List<DropdownMenuItemData<T>> items,
    required ValueChanged<T> onSelected,
    bool showSearch = true,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayLabel,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSet ? FontWeight.w500 : FontWeight.w400,
                  color: isSet
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
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
    bool showSearch = true,
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Container(
                width: 440,
                constraints: const BoxConstraints(maxHeight: 460),
                clipBehavior: Clip.antiAlias,
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
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(null),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    if (showSearch && items.length > 5)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) => setPopupState(() {}),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type to filter...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF004385),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (context, idx) =>
                            const Divider(height: 1, color: Color(0xFFF8FAFC)),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final isSelected = item.value == selectedValue;

                          return InkWell(
                            onTap: () =>
                                Navigator.of(dialogContext).pop(item.value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? const Color(0xFF004385)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Color(0xFF004385),
                                    ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatted,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                  color: value != null
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getGmt7Now() {
    return DateTime.now().toUtc().add(const Duration(hours: 7));
  }

  Future<DateTime?> _showTabletDateTimePicker(
    BuildContext context,
    DateTime? initialDate, {
    DateTime? minDateTime,
    String title = 'Select Date & Time',
    bool showNowButton = true,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final gmt7Now = _getGmt7Now();
        DateTime liveTime = gmt7Now;

        DateTime selectedDate =
            initialDate ??
            (minDateTime != null && minDateTime.isAfter(gmt7Now)
                ? minDateTime
                : gmt7Now);

        int? selectedHour = initialDate?.hour;
        int? selectedMinute = initialDate?.minute;

        final ScrollController hourScrollController = ScrollController();
        final ScrollController minuteScrollController = ScrollController();

        bool isSameDayAsMin(DateTime date) {
          if (minDateTime == null) return false;
          return date.year == minDateTime.year &&
              date.month == minDateTime.month &&
              date.day == minDateTime.day;
        }

        if (selectedHour != null && isSameDayAsMin(selectedDate)) {
          if (selectedHour < minDateTime!.hour) {
            selectedHour = minDateTime.hour;
          }
          if (selectedMinute != null &&
              selectedHour == minDateTime.hour &&
              selectedMinute <= minDateTime.minute) {
            selectedMinute = minDateTime.minute + 1;
            if (selectedMinute >= 60) {
              selectedHour += 1;
              selectedMinute = 0;
            }
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final h = selectedHour;
          final m = selectedMinute;
          if (h != null && hourScrollController.hasClients) {
            final targetH = (h * 38.0) - 92.0;
            hourScrollController.jumpTo(
              targetH.clamp(0.0, hourScrollController.position.maxScrollExtent),
            );
          } else if (hourScrollController.hasClients) {
            if (minDateTime != null && isSameDayAsMin(selectedDate)) {
              final targetH = minDateTime.hour * 38.0;
              hourScrollController.jumpTo(
                targetH.clamp(
                  0.0,
                  hourScrollController.position.maxScrollExtent,
                ),
              );
            } else {
              hourScrollController.jumpTo(0.0);
            }
          }
          if (m != null && minuteScrollController.hasClients) {
            final targetM = (m * 38.0) - 92.0;
            minuteScrollController.jumpTo(
              targetM.clamp(
                0.0,
                minuteScrollController.position.maxScrollExtent,
              ),
            );
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
            final hasSelectedTime =
                selectedHour != null && selectedMinute != null;

            final currentPreview = hasSelectedTime
                ? DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedHour!,
                    selectedMinute!,
                  )
                : null;

            final isSelectionValid =
                hasSelectedTime &&
                (minDateTime == null || currentPreview!.isAfter(minDateTime));

            // Format Live Time String with seconds
            final days = [
              'Sunday',
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
            ];
            final months = [
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December',
            ];
            final liveDayName = days[liveTime.weekday % 7];
            final liveMonthName = months[liveTime.month - 1];
            final liveHourStr = liveTime.hour.toString().padLeft(2, '0');
            final liveMinStr = liveTime.minute.toString().padLeft(2, '0');
            final liveSecStr = liveTime.second.toString().padLeft(2, '0');
            final liveClockDisplay =
                '$liveDayName, ${liveTime.day} $liveMonthName ${liveTime.year}, $liveHourStr:$liveMinStr:$liveSecStr';

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
                    // Top Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: Color(0xFF004385),
                          ),
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
                          // 1. Real-time Live Clock GMT+7
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 14,
                                  color: Color(0xFF004385),
                                ),
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

                    // Center Content: Calendar (Left) + Hours/Minutes Selector (Right)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Calendar Date Picker
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
                                key: ValueKey(
                                  '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                                ),
                                initialDate: selectedDate,
                                firstDate: minDateTime != null
                                    ? DateTime(
                                        minDateTime.year,
                                        minDateTime.month,
                                        minDateTime.day,
                                      )
                                    : DateTime(2020),
                                lastDate: DateTime(2035),
                                onDateChanged: (newDate) {
                                  setDialogState(() {
                                    selectedDate = newDate;
                                    if (selectedHour != null &&
                                        isSameDayAsMin(newDate)) {
                                      if (selectedHour! < minDateTime!.hour) {
                                        selectedHour = minDateTime.hour;
                                      }
                                      if (selectedMinute != null &&
                                          selectedHour == minDateTime.hour &&
                                          selectedMinute! <=
                                              minDateTime.minute) {
                                        selectedMinute = minDateTime.minute + 1;
                                        if (selectedMinute! >= 60) {
                                          selectedHour = selectedHour! + 1;
                                          selectedMinute = 0;
                                        }
                                      }
                                    }
                                  });
                                  if (selectedHour == null &&
                                      hourScrollController.hasClients) {
                                    if (minDateTime != null &&
                                        isSameDayAsMin(newDate)) {
                                      final targetH = minDateTime.hour * 38.0;
                                      hourScrollController.animateTo(
                                        targetH.clamp(
                                          0.0,
                                          hourScrollController
                                              .position
                                              .maxScrollExtent,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        curve: Curves.easeOutCubic,
                                      );
                                    } else {
                                      hourScrollController.animateTo(
                                        0.0,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        curve: Curves.easeOutCubic,
                                      );
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

                          // Right: Hours & Minutes Selector
                          Expanded(
                            flex: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 2. Selected Time Box (Starts Empty / Unselected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
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
                                          fontWeight: hasSelectedTime
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: hasSelectedTime
                                              ? const Color(0xFF004385)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Headers for Hour & Minute
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

                                // Dual Scroll Lists with exact center alignment & touch dragging
                                SizedBox(
                                  height: 230,
                                  child: ScrollConfiguration(
                                    behavior: const MaterialScrollBehavior()
                                        .copyWith(
                                          dragDevices: {
                                            PointerDeviceKind.touch,
                                            PointerDeviceKind.mouse,
                                            PointerDeviceKind.trackpad,
                                            PointerDeviceKind.stylus,
                                          },
                                        ),
                                    child: Row(
                                      children: [
                                        // Hours List (00 - 23)
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: RawScrollbar(
                                              controller: hourScrollController,
                                              thumbVisibility: true,
                                              thickness: 3.5,
                                              radius: const Radius.circular(4),
                                              thumbColor: const Color(
                                                0xFF94A3B8,
                                              ),
                                              child: ListView.builder(
                                                controller:
                                                    hourScrollController,
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(
                                                      parent:
                                                          BouncingScrollPhysics(),
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 4,
                                                    ),
                                                itemCount: 24,
                                                itemBuilder: (ctx, h) {
                                                  final isHourDisabled =
                                                      isSameDay &&
                                                      h < minDateTime!.hour;
                                                  final isSelected =
                                                      selectedHour == h;

                                                  return SizedBox(
                                                    height: 38,
                                                    child: Center(
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                        onTap: isHourDisabled
                                                            ? null
                                                            : () {
                                                                setDialogState(() {
                                                                  selectedHour =
                                                                      h;
                                                                  selectedMinute ??=
                                                                      0;
                                                                  if (isSameDay &&
                                                                      h ==
                                                                          minDateTime!
                                                                              .hour) {
                                                                    if (selectedMinute! <=
                                                                        minDateTime
                                                                            .minute) {
                                                                      selectedMinute =
                                                                          minDateTime
                                                                              .minute +
                                                                          1;
                                                                      if (selectedMinute! >=
                                                                          60) {
                                                                        selectedHour =
                                                                            h +
                                                                            1;
                                                                        selectedMinute =
                                                                            0;
                                                                      }
                                                                    }
                                                                  }
                                                                });
                                                                if (hourScrollController
                                                                    .hasClients) {
                                                                  hourScrollController.animateTo(
                                                                    ((h * 38.0) -
                                                                            92.0)
                                                                        .clamp(
                                                                          0.0,
                                                                          hourScrollController
                                                                              .position
                                                                              .maxScrollExtent,
                                                                        ),
                                                                    duration: const Duration(
                                                                      milliseconds:
                                                                          250,
                                                                    ),
                                                                    curve: Curves
                                                                        .easeOutCubic,
                                                                  );
                                                                }
                                                              },
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          height: 34,
                                                          decoration: BoxDecoration(
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFF004385,
                                                                  )
                                                                : (isHourDisabled
                                                                      ? const Color(
                                                                          0xFFF1F5F9,
                                                                        )
                                                                      : Colors
                                                                            .transparent),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            h
                                                                .toString()
                                                                .padLeft(
                                                                  2,
                                                                  '0',
                                                                ),
                                                            style: GoogleFonts.inter(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  isSelected
                                                                  ? FontWeight
                                                                        .w700
                                                                  : (isHourDisabled
                                                                        ? FontWeight
                                                                              .w400
                                                                        : FontWeight
                                                                              .w600),
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : (isHourDisabled
                                                                        ? const Color(
                                                                            0xFFCBD5E1,
                                                                          )
                                                                        : const Color(
                                                                            0xFF1E293B,
                                                                          )),
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

                                        // Minutes List (00 - 59)
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: RawScrollbar(
                                              controller:
                                                  minuteScrollController,
                                              thumbVisibility: true,
                                              thickness: 3.5,
                                              radius: const Radius.circular(4),
                                              thumbColor: const Color(
                                                0xFF94A3B8,
                                              ),
                                              child: ListView.builder(
                                                controller:
                                                    minuteScrollController,
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(
                                                      parent:
                                                          BouncingScrollPhysics(),
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 4,
                                                    ),
                                                itemCount: 60,
                                                itemBuilder: (ctx, m) {
                                                  final isMinuteDisabled =
                                                      isSameDay &&
                                                      selectedHour != null &&
                                                      selectedHour ==
                                                          minDateTime!.hour &&
                                                      m <= minDateTime.minute;
                                                  final isSelected =
                                                      selectedMinute == m;

                                                  return SizedBox(
                                                    height: 38,
                                                    child: Center(
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                        onTap: isMinuteDisabled
                                                            ? null
                                                            : () {
                                                                setDialogState(() {
                                                                  selectedMinute =
                                                                      m;
                                                                  selectedHour ??=
                                                                      isSameDay
                                                                      ? minDateTime!
                                                                            .hour
                                                                      : 9;
                                                                });
                                                                if (minuteScrollController
                                                                    .hasClients) {
                                                                  minuteScrollController.animateTo(
                                                                    ((m * 38.0) -
                                                                            92.0)
                                                                        .clamp(
                                                                          0.0,
                                                                          minuteScrollController
                                                                              .position
                                                                              .maxScrollExtent,
                                                                        ),
                                                                    duration: const Duration(
                                                                      milliseconds:
                                                                          250,
                                                                    ),
                                                                    curve: Curves
                                                                        .easeOutCubic,
                                                                  );
                                                                }
                                                              },
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          height: 34,
                                                          decoration: BoxDecoration(
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFF004385,
                                                                  )
                                                                : (isMinuteDisabled
                                                                      ? const Color(
                                                                          0xFFF1F5F9,
                                                                        )
                                                                      : Colors
                                                                            .transparent),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            m
                                                                .toString()
                                                                .padLeft(
                                                                  2,
                                                                  '0',
                                                                ),
                                                            style: GoogleFonts.inter(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  isSelected
                                                                  ? FontWeight
                                                                        .w700
                                                                  : (isMinuteDisabled
                                                                        ? FontWeight
                                                                              .w400
                                                                        : FontWeight
                                                                              .w600),
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : (isMinuteDisabled
                                                                        ? const Color(
                                                                            0xFFCBD5E1,
                                                                          )
                                                                        : const Color(
                                                                            0xFF1E293B,
                                                                          )),
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

                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),

                    // Bottom Action Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // 3. Automatic Now Button (GMT+7 Live Sync & Auto Scroll)
                          if (showNowButton)
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                foregroundColor: const Color(0xFF004385),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                final nowGmt7 = _getGmt7Now();
                                final targetHour = nowGmt7.hour;
                                final targetMinute = nowGmt7.minute;

                                setDialogState(() {
                                  selectedDate = DateTime(
                                    nowGmt7.year,
                                    nowGmt7.month,
                                    nowGmt7.day,
                                  );
                                  selectedHour = targetHour;
                                  selectedMinute = targetMinute;
                                });

                                if (hourScrollController.hasClients) {
                                  final targetH = (targetHour * 38.0) - 92.0;
                                  hourScrollController.animateTo(
                                    targetH.clamp(
                                      0.0,
                                      hourScrollController
                                          .position
                                          .maxScrollExtent,
                                    ),
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                                if (minuteScrollController.hasClients) {
                                  final targetM = (targetMinute * 38.0) - 92.0;
                                  minuteScrollController.animateTo(
                                    targetM.clamp(
                                      0.0,
                                      minuteScrollController
                                          .position
                                          .maxScrollExtent,
                                    ),
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                              child: Text(
                                'Today',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              tickerTimer?.cancel();
                              Navigator.of(dialogContext).pop(null);
                            },
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelectionValid
                                  ? const Color(0xFF004385)
                                  : const Color(0xFFE2E8F0),
                              foregroundColor: isSelectionValid
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                            ),
                            onPressed: isSelectionValid
                                ? () {
                                    tickerTimer?.cancel();
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(currentPreview);
                                  }
                                : null,
                            child: Text(
                              'OK',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
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

  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626),
            ),
          ),
      ],
    );
  }

  Widget _buildFormFieldLabel(
    String label, {
    bool isRequired = false,
    bool showInfo = false,
  }) {
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
          color: isFieldDisabled
              ? const Color(0xFF64748B)
              : const Color(0xFF1E293B),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isFieldDisabled
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isFieldDisabled
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isFieldDisabled
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF004385),
              width: isFieldDisabled ? 1.0 : 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final isLastStep = _currentStep == 3;
    final canProceedStep1 = _selectedVisitorType != null && _isGroup != null;
    final canProceedStep2 = _isStep2Valid;
    final canProceedStep3 = _isStep3Valid;

    final isNextDisabled =
        (_currentStep == 1 && !canProceedStep1) ||
        (_currentStep == 2 && !canProceedStep2) ||
        (_currentStep == 3 && !canProceedStep3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // 1. Pada Page 1, gausah ada tombol back
          if (_currentStep > 1) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF475569),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: !_isSubmitting ? _goToPreviousStep : null,
              icon: const Icon(Icons.arrow_back, size: 14),
              label: Text(
                'Back',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const Spacer(),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isNextDisabled
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF004385),
              foregroundColor: isNextDisabled
                  ? const Color(0xFF94A3B8)
                  : Colors.white,
              elevation: isNextDisabled ? 0 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            onPressed: (_isSubmitting || isNextDisabled)
                ? null
                : (isLastStep ? _handleSubmit : _goToNextStep),
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
                        isLastStep ? 'Submit' : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isNextDisabled
                              ? const Color(0xFF94A3B8)
                              : Colors.white,
                        ),
                      ),
                      if (!isLastStep) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: isNextDisabled
                              ? const Color(0xFF94A3B8)
                              : Colors.white,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class DropdownMenuItemData<T> {
  final T value;
  final String label;

  DropdownMenuItemData({required this.value, required this.label});
}
