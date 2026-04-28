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
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString().trim() ?? '') ?? fallback;
  }

  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static List<int> _toIntList(dynamic value, {bool newestFirst = false}) {
    if (value is! List) return <int>[];

    final years = value
        .map((e) => _toInt(e))
        .where((e) => e > 0)
        .toSet()
        .toList();

    years.sort();

    if (newestFirst) {
      return years.reversed.toList();
    }

    return years;
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

  factory Membership.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];

    final Map<String, dynamic> data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : Map<String, dynamic>.from(json);

    final paidYears = _toIntList(data['paid_years'], newestFirst: true);
    final missingYears = _toIntList(data['missing_years'], newestFirst: true);

    final currentYear = _toInt(data['current_year']);
    final selectedYear = _toInt(data['selected_year']);

    final rawAvailableYears =
        _toIntList(data['available_years'], newestFirst: true);

    final availableYears = rawAvailableYears.isNotEmpty
        ? rawAvailableYears
        : missingYears.isNotEmpty
            ? missingYears
            : currentYear > 0
                ? <int>[currentYear]
                : <int>[];

    final calculatedMissingCount = missingYears.length;

    return Membership(
      status: _toString(data['status']),
      type: _toString(data['type']),
      validUntil: _toString(data['valid_until']),
      memberSince: _toInt(data['member_since']),
      paidYears: paidYears,
      missingYears: missingYears,
      missingCount: _toInt(
        data['missing_count'],
        fallback: calculatedMissingCount,
      ),
      warning: _toString(data['warning']),
      currentYear: currentYear,
      selectedYear: selectedYear > 0
          ? selectedYear
          : availableYears.isNotEmpty
              ? availableYears.first
              : currentYear,
      availableYears: availableYears,
      isCurrentPaid: _toBool(data['is_current_paid']),
      payUrl: _toString(data['pay_url']),
    );
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
    );
  }
}