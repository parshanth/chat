class Member {
  final String id;
  final String name;
  final DateTime? dob;
  final String phoneNumber;
  final DateTime? baptismDate;
  final DateTime? marriageDate;

  const Member({
    required this.id,
    required this.name,
    this.dob,
    this.phoneNumber = '',
    this.baptismDate,
    this.marriageDate,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      dob: _parseDate(json['dob']),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      baptismDate: _parseDate(json['baptismDate']),
      marriageDate: _parseDate(json['marriageDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'name': name,
        'dob': _serializeDate(dob),
        'phoneNumber': phoneNumber,
        'baptismDate': _serializeDate(baptismDate),
        'marriageDate': _serializeDate(marriageDate),
      };

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String? _serializeDate(DateTime? value) {
    if (value == null) return null;

    return DateTime.utc(value.year, value.month, value.day).toIso8601String();
  }
}
