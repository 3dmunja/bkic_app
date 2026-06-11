class Membership {
  final String status;
  final String type;
  final String validUntil;
  final int memberSince;

  final List<int> paidYears;
  final List<int> missingYears;
  final int missingCount;

  final String warning;
  final int currentYear;
  final int selectedYear;
  final List<int> availableYears;
  final bool isCurrentPaid;
  final String payUrl;

  final String displayName;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String profileUrl;
  final String logoutUrl;
  final String lostPasswordUrl;

  Membership({
    required this.status,
    required this.type,
    required this.validUntil,
    required this.memberSince,
    required this.paidYears,
    required this.missingYears,
    required this.missingCount,
    required this.warning,
    required this.currentYear,
    required this.selectedYear,
    required this.availableYears,
    required this.isCurrentPaid,
    required this.payUrl,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.profileUrl,
    required this.logoutUrl,
    required this.lostPasswordUrl,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? fallback;
  }

  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' ||
          v == '1' ||
          v == 'yes' ||
          v == 'da' ||
          v == 'active' ||
          v == 'paid' ||
          v == 'plaćeno' ||
          v == 'placeno';
    }

    return false;
  }

  static List<int> _toIntList(dynamic value, {bool newestFirst = false}) {
    if (value == null) return <int>[];

    final List<dynamic> rawList;

    if (value is List) {
      rawList = value;
    } else if (value is String) {
      rawList = value
          .replaceAll(' ', '')
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .toList();
    } else {
      return <int>[];
    }

    final years = rawList
        .map((e) => _toInt(e))
        .where((e) => e > 0)
        .toSet()
        .toList();

    years.sort();

    return newestFirst ? years.reversed.toList() : years;
  }

  static Map<String, dynamic> _extractData(Map<String, dynamic> json) {
    final rawData = json['data'];

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return Map<String, dynamic>.from(json);
  }

  static String _pickString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _toString(data[key]);
      if (value.isNotEmpty) return value;
    }

    return '';
  }

  static String _firstPartOfName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '';

    final parts = clean.split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first.trim();
  }

  static String _lastPartOfName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '';

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length <= 1) return '';

    return parts.sublist(1).join(' ').trim();
  }

  factory Membership.fromJson(Map<String, dynamic> json) {
    final data = _extractData(json);

    final paidYears = _toIntList(data['paid_years'], newestFirst: true);
    final missingYears = _toIntList(data['missing_years'], newestFirst: true);

    final currentYear = _toInt(data['current_year']);
    final selectedYearRaw = _toInt(data['selected_year']);

    final rawAvailableYears =
        _toIntList(data['available_years'], newestFirst: true);

    final availableYears = rawAvailableYears.isNotEmpty
        ? rawAvailableYears
        : missingYears.isNotEmpty
            ? missingYears
            : <int>[];

    final selectedYear = selectedYearRaw > 0
        ? selectedYearRaw
        : availableYears.isNotEmpty
            ? availableYears.first
            : currentYear;

    final name = _pickString(data, [
      'name',
      'full_name',
      'user_name',
      'customer_name',
    ]);

    final rawDisplayName = _pickString(data, [
      'display_name',
      'displayName',
      'user_display_name',
      'nickname',
    ]);

    final sourceName = rawDisplayName.isNotEmpty ? rawDisplayName : name;

    final firstNameRaw = _pickString(data, [
      'first_name',
      'firstName',
      'billing_first_name',
      'user_first_name',
      'given_name',
      'ime',
    ]);

    final lastNameRaw = _pickString(data, [
      'last_name',
      'lastName',
      'billing_last_name',
      'user_last_name',
      'family_name',
      'prezime',
    ]);

    final firstName = firstNameRaw.isNotEmpty
        ? firstNameRaw
        : _firstPartOfName(sourceName);

    final lastName = lastNameRaw.isNotEmpty
        ? lastNameRaw
        : _lastPartOfName(sourceName);

    final email = _pickString(data, [
      'email',
      'user_email',
      'billing_email',
    ]);

    final combinedName = '$firstName $lastName'.trim();

    final displayName = rawDisplayName.isNotEmpty
        ? rawDisplayName
        : name.isNotEmpty
            ? name
            : combinedName.isNotEmpty
                ? combinedName
                : email.isNotEmpty
                    ? email
                    : 'Član';

    return Membership(
      status: _toString(data['status']),
      type: _toString(data['type']),
      validUntil: _toString(data['valid_until']),
      memberSince: _toInt(data['member_since']),
      paidYears: paidYears,
      missingYears: missingYears,
      missingCount: _toInt(
        data['missing_count'],
        fallback: missingYears.length,
      ),
      warning: _toString(data['warning']),
      currentYear: currentYear,
      selectedYear: selectedYear,
      availableYears: availableYears,
      isCurrentPaid: _toBool(data['is_current_paid']),
      payUrl: _toString(data['pay_url']),
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: _pickString(data, [
        'phone',
        'telephone',
        'billing_phone',
        'mobile',
        'telefon',
      ]),
      profileUrl: _toString(data['profile_url']).isNotEmpty
          ? _toString(data['profile_url'])
          : 'https://bkicsaff.dk/uredi-profil-2/',
      logoutUrl: _toString(data['logout_url']),
      lostPasswordUrl: _toString(data['lost_password_url']).isNotEmpty
          ? _toString(data['lost_password_url'])
          : 'https://bkicsaff.dk/lost-password/',
    );
  }

  bool get hasMissingYears {
    return missingYears.isNotEmpty || availableYears.isNotEmpty;
  }

  bool get isActive {
    final s = status.toLowerCase().trim();

    return s == 'active' ||
        s == 'aktivno' ||
        s == 'paid' ||
        s == 'plaćeno' ||
        s == 'placeno' ||
        isCurrentPaid;
  }

  String get fullName {
    final combined = '$firstName $lastName'.trim();

    if (combined.isNotEmpty) return combined;
    if (displayName.isNotEmpty) return displayName;
    if (email.isNotEmpty) return email;

    return 'Član';
  }

  String get statusText {
    if (isActive) return 'Aktivno';

    final s = status.trim();
    if (s.isNotEmpty) return s;

    return 'Neaktivno';
  }

  String get typeText {
    return type.isNotEmpty ? type : 'Nije navedeno';
  }

  String get paidYearsText {
    if (paidYears.isEmpty) return '—';
    return paidYears.join(', ');
  }

  String get missingYearsText {
    if (missingYears.isNotEmpty) return missingYears.join(', ');
    if (availableYears.isNotEmpty) return availableYears.join(', ');
    return '—';
  }

  String get memberSinceText {
    return memberSince > 0 ? memberSince.toString() : 'Nije navedeno';
  }

  String get validUntilText {
    return validUntil.isNotEmpty ? validUntil : '—';
  }

  String get phoneText {
    return phone.isNotEmpty ? phone : 'Nije navedeno';
  }

  String get emailText {
    return email.isNotEmpty ? email : 'Nije navedeno';
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'type': type,
      'valid_until': validUntil,
      'member_since': memberSince,
      'paid_years': paidYears,
      'missing_years': missingYears,
      'missing_count': missingCount,
      'warning': warning,
      'current_year': currentYear,
      'selected_year': selectedYear,
      'available_years': availableYears,
      'is_current_paid': isCurrentPaid,
      'pay_url': payUrl,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'profile_url': profileUrl,
      'logout_url': logoutUrl,
      'lost_password_url': lostPasswordUrl,
    };
  }

  Membership copyWith({
    String? status,
    String? type,
    String? validUntil,
    int? memberSince,
    List<int>? paidYears,
    List<int>? missingYears,
    int? missingCount,
    String? warning,
    int? currentYear,
    int? selectedYear,
    List<int>? availableYears,
    bool? isCurrentPaid,
    String? payUrl,
    String? displayName,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileUrl,
    String? logoutUrl,
    String? lostPasswordUrl,
  }) {
    return Membership(
      status: status ?? this.status,
      type: type ?? this.type,
      validUntil: validUntil ?? this.validUntil,
      memberSince: memberSince ?? this.memberSince,
      paidYears: paidYears ?? this.paidYears,
      missingYears: missingYears ?? this.missingYears,
      missingCount: missingCount ?? this.missingCount,
      warning: warning ?? this.warning,
      currentYear: currentYear ?? this.currentYear,
      selectedYear: selectedYear ?? this.selectedYear,
      availableYears: availableYears ?? this.availableYears,
      isCurrentPaid: isCurrentPaid ?? this.isCurrentPaid,
      payUrl: payUrl ?? this.payUrl,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileUrl: profileUrl ?? this.profileUrl,
      logoutUrl: logoutUrl ?? this.logoutUrl,
      lostPasswordUrl: lostPasswordUrl ?? this.lostPasswordUrl,
    );
  }
}