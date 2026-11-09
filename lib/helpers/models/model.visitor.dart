import 'package:flutter/material.dart';

class VisitorCategoryOption {
  final String id;
  final String titleEn;
  final String titleMl;
  final String subtitleEn;
  final String subtitleMl;
  final IconData icon;
  final Color primaryColor;
  final Color bgColor;
  final Color borderColor;
  final bool requiresStudentInfo;

  const VisitorCategoryOption({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.subtitleEn,
    required this.subtitleMl,
    required this.icon,
    required this.primaryColor,
    required this.bgColor,
    required this.borderColor,
    required this.requiresStudentInfo,
  });
}

class VisitorPurposeOption {
  final String id;
  final String titleEn;
  final String titleMl;
  final String personToMeetEn;
  final String personToMeetMl;
  final String instructionEn;
  final String instructionMl;
  final IconData icon;
  final List<String> applicableCategories;
  final bool requiresStudentInfo;

  const VisitorPurposeOption({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.personToMeetEn,
    required this.personToMeetMl,
    required this.instructionEn,
    required this.instructionMl,
    required this.icon,
    required this.applicableCategories,
    this.requiresStudentInfo = false,
  });
}

class VisitorCatalog {
  static const List<VisitorCategoryOption> categories = [
    VisitorCategoryOption(
      id: 'parent',
      titleEn: 'Parent / Guardian',
      titleMl: 'രക്ഷിതാവ്',
      subtitleEn: 'Visiting regarding a current student',
      subtitleMl: 'വിദ്യാർത്ഥിയുമായി ബന്ധപ്പെട്ട സന്ദർശനം',
      icon: Icons.family_restroom_rounded,
      primaryColor: Color(0xFF0284C7),
      bgColor: Color(0xFFF0F9FF),
      borderColor: Color(0xFFBAE6FD),
      requiresStudentInfo: true,
    ),
    VisitorCategoryOption(
      id: 'admission',
      titleEn: 'Admission Inquiry',
      titleMl: 'അഡ്മിഷൻ അന്വേഷണം',
      subtitleEn: 'New admission, registration or prospectus',
      subtitleMl: 'പുതിയ പ്രവേശന വിവരങ്ങൾക്കായി',
      icon: Icons.school_rounded,
      primaryColor: Color(0xFF0D9488),
      bgColor: Color(0xFFF0FDFA),
      borderColor: Color(0xFF99F6E4),
      requiresStudentInfo: false,
    ),
    VisitorCategoryOption(
      id: 'alumni',
      titleEn: 'Alumni (NEXUS)',
      titleMl: 'പൂർവ്വ വിദ്യാർത്ഥി',
      subtitleEn: 'Former student or NEXUS alumni visit',
      subtitleMl: 'പൂർവ്വ വിദ്യാർത്ഥി സന്ദർശനം',
      icon: Icons.workspace_premium_rounded,
      primaryColor: Color(0xFF7C3AED),
      bgColor: Color(0xFFF5F3FF),
      borderColor: Color(0xFFDDD6FE),
      requiresStudentInfo: false,
    ),
    VisitorCategoryOption(
      id: 'vendor',
      titleEn: 'Vendor / Official',
      titleMl: 'വെണ്ടർ / ഔദ്യോഗികം',
      subtitleEn: 'Deliveries, maintenance or official inspection',
      subtitleMl: 'ഡെലിവറി അല്ലെങ്കിൽ ഔദ്യോഗിക ആവശ്യം',
      icon: Icons.business_center_rounded,
      primaryColor: Color(0xFFD97706),
      bgColor: Color(0xFFFFFBEB),
      borderColor: Color(0xFFFDE68A),
      requiresStudentInfo: false,
    ),
    VisitorCategoryOption(
      id: 'guest',
      titleEn: 'Guest / General Visit',
      titleMl: 'അതിഥി / മറ്റ് ആവശ്യങ്ങൾ',
      subtitleEn: 'Event guest, general inquiry or appointment',
      subtitleMl: 'മറ്റ് പൊതുവായ സന്ദർശനങ്ങൾ',
      icon: Icons.badge_rounded,
      primaryColor: Color(0xFF10B981),
      bgColor: Color(0xFFECFDF5),
      borderColor: Color(0xFFA7F3D0),
      requiresStudentInfo: false,
    ),
  ];

  static const List<VisitorPurposeOption> purposes = [
    VisitorPurposeOption(
      id: 'meet_principal',
      titleEn: "Meet the Principal",
      titleMl: "പ്രിൻസിപ്പലിനെ കാണാൻ",
      personToMeetEn: "Principal (Sr. Lins Maria Alackal SABS)",
      personToMeetMl: "പ്രിൻസിപ്പൽ (സി. ലിൻസ് മരിയ ആലക്കൽ)",
      instructionEn:
          "Please be seated at the Reception lounge. The receptionist will verify your appointment with the Principal's Office.",
      instructionMl:
          "ദയവായി റിസപ്ഷനിൽ ഇരിക്കുക. പ്രിൻസിപ്പൽ ഓഫീസുമായി ബന്ധപ്പെട്ട ശേഷം നിങ്ങളെ അറിയിക്കുന്നതാണ്.",
      icon: Icons.account_balance_rounded,
      applicableCategories: ['parent', 'admission', 'alumni', 'vendor', 'guest'],
      requiresStudentInfo: false,
    ),
    VisitorPurposeOption(
      id: 'meet_vice_principal',
      titleEn: "Meet the Vice Principal",
      titleMl: "വൈസ് പ്രിൻസിപ്പലിനെ കാണാൻ",
      personToMeetEn: "Vice Principal",
      personToMeetMl: "വൈസ് പ്രിൻസിപ്പൽ",
      instructionEn:
          "Please wait at the Reception area while we notify the Vice Principal's office.",
      instructionMl:
          "വൈസ് പ്രിൻസിപ്പൽ ഓഫീസിൽ അറിയിക്കുന്നതുവരെ ദയവായി റിസപ്ഷനിൽ കാത്തിരിക്കുക.",
      icon: Icons.supervisor_account_rounded,
      applicableCategories: ['parent', 'alumni', 'guest'],
      requiresStudentInfo: false,
    ),
    VisitorPurposeOption(
      id: 'meet_teacher',
      titleEn: "Meet Class / Subject Teacher",
      titleMl: "അധ്യാപകരെ കാണാൻ",
      personToMeetEn: "Class / Subject Teacher",
      personToMeetMl: "ക്ലാസ് / വിഷയ അധ്യാപകർ",
      instructionEn:
          "Note: Teachers cannot be met during active classroom teaching hours without prior permission. Please show this token at the Reception Desk.",
      instructionMl:
          "ക്ലാസ് സമയങ്ങളിൽ മുൻകൂർ അനുമതിയില്ലാതെ അധ്യാപകരെ കാണാൻ കഴിയില്ല. ദയവായി ഈ ടോക്കൺ റിസപ്ഷനിൽ കാണിക്കുക.",
      icon: Icons.co_present_rounded,
      applicableCategories: ['parent'],
      requiresStudentInfo: true,
    ),
    VisitorPurposeOption(
      id: 'fee_office',
      titleEn: "School Office / Fee Inquiry",
      titleMl: "സ്കൂൾ ഓഫീസ് / ഫീസ് വിവരങ്ങൾ",
      personToMeetEn: "Administrative / Fee Counter",
      personToMeetMl: "സ്കൂൾ ഓഫീസ് കൗണ്ടർ",
      instructionEn:
          "Please proceed to the School Office counter (Office Hours: 9:00 AM – 4:00 PM) and present your token.",
      instructionMl:
          "ദയവായി സ്കൂൾ ഓഫീസ് കൗണ്ടറിലേക്ക് സമീപിക്കുക (ഓഫീസ് സമയം: രാവിലെ 9:00 മുതൽ വൈകുന്നേരം 4:00 വരെ).",
      icon: Icons.receipt_long_rounded,
      applicableCategories: ['parent', 'alumni', 'vendor', 'guest'],
      requiresStudentInfo: false,
    ),
    VisitorPurposeOption(
      id: 'tc_certificates',
      titleEn: "TC / Certificates / Documents",
      titleMl: "ടി.സി / സർട്ടിഫിക്കറ്റുകൾ",
      personToMeetEn: "School Office Records Desk",
      personToMeetMl: "സർട്ടിഫിക്കറ്റ് വിഭാഗം",
      instructionEn:
          "Please present your token at the School Office Desk. (Note: TC requests require a written application two weeks in advance).",
      instructionMl:
          "ദയവായി സ്കൂൾ ഓഫീസ് ഡെസ്കിൽ ഈ ടോക്കൺ കാണിക്കുക.",
      icon: Icons.description_rounded,
      applicableCategories: ['parent', 'alumni'],
      requiresStudentInfo: false,
    ),
    VisitorPurposeOption(
      id: 'student_pickup_drop',
      titleEn: "Student Pick-up / Drop / Item Handover",
      titleMl: "കുട്ടിയെ കൂട്ടിക്കൊണ്ടുപോകാൻ / സാധനങ്ങൾ നൽകാൻ",
      personToMeetEn: "Reception Security / Duty Staff",
      personToMeetMl: "റിസപ്ഷൻ ഡ്യൂട്ടി സ്റ്റാഫ്",
      instructionEn:
          "Students require official permission to leave during school hours. Please hand this token to the Reception Desk.",
      instructionMl:
          "സ്കൂൾ സമയത്ത് കുട്ടികളെ കൂട്ടിക്കൊണ്ടുപോകാൻ അനുമതി ആവശ്യമാണ്. ദയവായി റിസപ്ഷൻ ഡെസ്കിൽ സമീപിക്കുക.",
      icon: Icons.transfer_within_a_station_rounded,
      applicableCategories: ['parent'],
      requiresStudentInfo: true,
    ),
    VisitorPurposeOption(
      id: 'admission_desk',
      titleEn: "Admissions & Registration",
      titleMl: "അഡ്മിഷൻ വിഭാഗം",
      personToMeetEn: "Admissions Office",
      personToMeetMl: "അഡ്മിഷൻ ഓഫീസ്",
      instructionEn:
          "Welcome! Please show this token at the Admissions Desk. You can also use the 'Mini Admission Assistant' on this kiosk to register online.",
      instructionMl:
          "സ്വാഗതം! ദയവായി ഈ ടോക്കൺ അഡ്മിഷൻ ഡെസ്കിൽ കാണിക്കുക. ഓൺലൈൻ രജിസ്ട്രേഷനായി കിയോസ്കിലെ അഡ്മിഷൻ അസിസ്റ്റന്റും ഉപയോഗിക്കാം.",
      icon: Icons.how_to_reg_rounded,
      applicableCategories: ['admission', 'parent', 'guest'],
      requiresStudentInfo: false,
    ),
    VisitorPurposeOption(
      id: 'transport_bus',
      titleEn: "School Bus / Transport Pass",
      titleMl: "സ്കൂൾ ബസ് / ട്രാൻസ്പോർട്ട്",
      personToMeetEn: "Transport Coordinator",
      personToMeetMl: "ട്രാൻസ്പോർട്ട് വിഭാഗം",
      instructionEn:
          "Please proceed to the School Office for bus route, GPS tracking, or bus pass inquiries.",
      instructionMl:
          "സ്കൂൾ ബസ് പാസ്, റൂട്ട് വിവരങ്ങൾക്കായി സ്കൂൾ ഓഫീസിൽ സമീപിക്കുക.",
      icon: Icons.directions_bus_rounded,
      applicableCategories: ['parent'],
      requiresStudentInfo: true,
    ),
    VisitorPurposeOption(
      id: 'delivery_maintenance',
      titleEn: "Delivery / Service / Official Visit",
      titleMl: "ഡെലിവറി / ഔദ്യോഗിക സന്ദർശനം",
      personToMeetEn: "Reception / Store / Admin Officer",
      personToMeetMl: "റിസപ്ഷൻ / ഓഫീസ്",
      instructionEn:
          "Please check in at the Reception Desk with your token number before entering campus corridors.",
      instructionMl:
          "ക്യാമ്പസിൽ പ്രവേശിക്കുന്നതിന് മുമ്പ് റിസപ്ഷൻ ഡെസ്കിൽ ഈ ടോക്കൺ നമ്പർ കാണിക്കുക.",
      icon: Icons.local_shipping_rounded,
      applicableCategories: ['vendor', 'guest'],
      requiresStudentInfo: false,
    ),
  ];

  static const List<String> studentClasses = [
    'Play School',
    'PREKG',
    'LKG',
    'UKG',
    'Class I',
    'Class II',
    'Class III',
    'Class IV',
    'Class V',
    'Class VI',
    'Class VII',
    'Class VIII',
    'Class IX',
    'Class X',
    'Plus One (XI)',
    'Plus Two (XII)',
  ];

  static const List<String> studentDivisions = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'N/A',
  ];

  static VisitorCategoryOption getCategoryById(String id) {
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => categories.first,
    );
  }

  static List<VisitorPurposeOption> getPurposesForCategory(String categoryId) {
    return purposes
        .where((p) => p.applicableCategories.contains(categoryId))
        .toList();
  }
}

class VisitorRecord {
  final String tokenId; // e.g., NBS-20261109-001
  final String shortToken; // e.g., V-001
  final DateTime timestamp;
  final String visitorName;
  final String phoneNumber;
  final String categoryId;
  final String categoryLabel;
  final String purposeId;
  final String purposeLabel;
  final String personToMeet;
  final String? studentName;
  final String? studentClass;
  final String? studentDiv;
  final String languageUsed;

  const VisitorRecord({
    required this.tokenId,
    required this.shortToken,
    required this.timestamp,
    required this.visitorName,
    required this.phoneNumber,
    required this.categoryId,
    required this.categoryLabel,
    required this.purposeId,
    required this.purposeLabel,
    required this.personToMeet,
    this.studentName,
    this.studentClass,
    this.studentDiv,
    this.languageUsed = 'en',
  });

  String get formattedDate {
    final y = timestamp.year.toString().padLeft(4, '0');
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get formattedTime {
    final hour12 = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final min = timestamp.minute.toString().padLeft(2, '0');
    final sec = timestamp.second.toString().padLeft(2, '0');
    final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$min:$sec $amPm';
  }

  String get studentSummary {
    if (studentName == null || studentName!.trim().isEmpty) {
      if (studentClass != null && studentClass!.trim().isNotEmpty) {
        final div = (studentDiv != null &&
                studentDiv!.isNotEmpty &&
                studentDiv != 'N/A')
            ? ' - Div $studentDiv'
            : '';
        return '$studentClass$div';
      }
      return 'N/A';
    }
    final cls = (studentClass != null && studentClass!.isNotEmpty)
        ? ' ($studentClass${(studentDiv != null && studentDiv!.isNotEmpty && studentDiv != 'N/A') ? '-$studentDiv' : ''})'
        : '';
    return '${studentName!.trim()}$cls';
  }

  Map<String, dynamic> toJson() => {
    'tokenId': tokenId,
    'shortToken': shortToken,
    'timestamp': timestamp.toIso8601String(),
    'visitorName': visitorName,
    'phoneNumber': phoneNumber,
    'categoryId': categoryId,
    'categoryLabel': categoryLabel,
    'purposeId': purposeId,
    'purposeLabel': purposeLabel,
    'personToMeet': personToMeet,
    'studentName': studentName,
    'studentClass': studentClass,
    'studentDiv': studentDiv,
    'languageUsed': languageUsed,
  };

  factory VisitorRecord.fromJson(Map<String, dynamic> json) {
    return VisitorRecord(
      tokenId: json['tokenId']?.toString() ?? '',
      shortToken: json['shortToken']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      visitorName: json['visitorName']?.toString() ?? 'Visitor',
      phoneNumber: json['phoneNumber']?.toString() ?? 'N/A',
      categoryId: json['categoryId']?.toString() ?? 'guest',
      categoryLabel: json['categoryLabel']?.toString() ?? 'Guest',
      purposeId: json['purposeId']?.toString() ?? 'general',
      purposeLabel: json['purposeLabel']?.toString() ?? 'General Visit',
      personToMeet: json['personToMeet']?.toString() ?? 'Reception',
      studentName: json['studentName']?.toString(),
      studentClass: json['studentClass']?.toString(),
      studentDiv: json['studentDiv']?.toString(),
      languageUsed: json['languageUsed']?.toString() ?? 'en',
    );
  }

  static String csvHeader() {
    return 'Token ID,Short Token,Date,Check-In Time,Visitor Name,Phone Number,Category,Purpose of Visit,Person / Office to Meet,Student Name,Student Class,Division,Language';
  }

  String toCsvRow() {
    String esc(String? val) {
      final clean = (val ?? '').replaceAll('"', '""');
      return '"$clean"';
    }

    return [
      esc(tokenId),
      esc(shortToken),
      esc(formattedDate),
      esc(formattedTime),
      esc(visitorName),
      esc(phoneNumber),
      esc(categoryLabel),
      esc(purposeLabel),
      esc(personToMeet),
      esc(studentName ?? ''),
      esc(studentClass ?? ''),
      esc(studentDiv ?? ''),
      esc(languageUsed.toUpperCase()),
    ].join(',');
  }
}

class ReturningVisitorProfile {
  final String phoneNumber;
  final String visitorName;
  final String lastCategoryId;
  final String? studentName;
  final String? studentClass;
  final String? studentDiv;
  final int visitCount;
  final DateTime lastVisitedAt;

  const ReturningVisitorProfile({
    required this.phoneNumber,
    required this.visitorName,
    required this.lastCategoryId,
    this.studentName,
    this.studentClass,
    this.studentDiv,
    required this.visitCount,
    required this.lastVisitedAt,
  });

  Map<String, dynamic> toJson() => {
    'phoneNumber': phoneNumber,
    'visitorName': visitorName,
    'lastCategoryId': lastCategoryId,
    'studentName': studentName,
    'studentClass': studentClass,
    'studentDiv': studentDiv,
    'visitCount': visitCount,
    'lastVisitedAt': lastVisitedAt.toIso8601String(),
  };

  factory ReturningVisitorProfile.fromJson(Map<String, dynamic> json) {
    return ReturningVisitorProfile(
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      visitorName: json['visitorName']?.toString() ?? '',
      lastCategoryId: json['lastCategoryId']?.toString() ?? 'parent',
      studentName: json['studentName']?.toString(),
      studentClass: json['studentClass']?.toString(),
      studentDiv: json['studentDiv']?.toString(),
      visitCount: (json['visitCount'] as num?)?.toInt() ?? 1,
      lastVisitedAt:
          DateTime.tryParse(json['lastVisitedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class EmailRecipient {
  final String email;
  final String label;
  final bool enabled;

  const EmailRecipient({
    required this.email,
    this.label = 'School Admin',
    this.enabled = true,
  });

  EmailRecipient copyWith({String? email, String? label, bool? enabled}) {
    return EmailRecipient(
      email: email ?? this.email,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'label': label,
    'enabled': enabled,
  };

  factory EmailRecipient.fromJson(Map<String, dynamic> json) {
    return EmailRecipient(
      email: json['email']?.toString().trim() ?? '',
      label: json['label']?.toString().trim() ?? 'School Admin',
      enabled: json['enabled'] != false,
    );
  }
}

