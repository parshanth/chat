import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../utils/attendance_chart_data.dart';
import 'attendance_service.dart';
import 'attendance_report_workbook.dart';

enum ReportShareOutcome { shared, dismissed, unavailable }

class AttendanceReportService {
  AttendanceReportService({AttendanceService? attendanceService})
    : _attendanceService = attendanceService ?? AttendanceService.instance;

  static const _excelMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  final AttendanceService _attendanceService;

  Future<ReportShareOutcome> shareWeeklyReport({required String date}) async {
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null ||
        parsedDate.weekday != DateTime.sunday ||
        AttendanceChartData.dateKey(parsedDate) != date) {
      throw ArgumentError.value(date, 'date', 'Must be a valid Sunday date.');
    }

    final data = _responseData(await _attendanceService.getAttendance(date));
    final members = _responseMembers(data).map((member) {
      return WeeklyAttendanceMember(
        name: _memberName(member),
        status: member['status']?.toString() ?? 'unmarked',
      );
    }).toList();

    final generatedDate = AttendanceChartData.dateKey(DateTime.now());
    final bytes = AttendanceReportWorkbook.weekly(
      date: date,
      generatedDate: generatedDate,
      members: members,
    );
    final filename = 'Attendance_$date.xlsx';
    return _share(bytes, filename);
  }

  Future<ReportShareOutcome> shareMonthlyReport({
    required int year,
    required int month,
  }) async {
    if (year < 2000 || year > 2100) {
      throw ArgumentError.value(year, 'year', 'Must be between 2000 and 2100.');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Must be between 1 and 12.');
    }

    final sundays = AttendanceChartData.sundaysInMonth(year, month);
    final membersById = <String, MonthlyAttendanceMember>{};
    final statusByMemberAndDate = <String, Map<String, String>>{};

    for (final sunday in sundays) {
      final date = AttendanceChartData.dateKey(sunday);
      final data = _responseData(await _attendanceService.getAttendance(date));
      for (final member in _responseMembers(data)) {
        final id = _memberId(member);
        if (id == null || id.isEmpty) {
          throw const FormatException(
            'The attendance response contains a member without an ID.',
          );
        }

        membersById.putIfAbsent(
          id,
          () => MonthlyAttendanceMember(id: id, name: _memberName(member)),
        );
        statusByMemberAndDate.putIfAbsent(id, () => {})[date] =
            member['status']?.toString() ?? 'unmarked';
      }
    }

    final generatedDate = AttendanceChartData.dateKey(DateTime.now());
    final bytes = AttendanceReportWorkbook.monthly(
      year: year,
      month: month,
      generatedDate: generatedDate,
      sundays: sundays,
      members: membersById.values.toList(),
      statusByMemberAndDate: statusByMemberAndDate,
    );
    final monthValue = month.toString().padLeft(2, '0');
    final filename = 'Monthly_Attendance_$year-$monthValue.xlsx';
    return _share(bytes, filename);
  }

  Future<ReportShareOutcome> _share(List<int> bytes, String filename) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        title: filename,
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: filename,
            mimeType: _excelMimeType,
          ),
        ],
        fileNameOverrides: [filename],
        downloadFallbackEnabled: true,
      ),
    );

    switch (result.status) {
      case ShareResultStatus.success:
        return ReportShareOutcome.shared;
      case ShareResultStatus.dismissed:
        return ReportShareOutcome.dismissed;
      case ShareResultStatus.unavailable:
        return ReportShareOutcome.unavailable;
    }
  }

  Map<String, dynamic> _responseData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException(
        'The attendance response does not contain valid data.',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> _responseMembers(Map<String, dynamic> data) {
    final members = data['members'];
    if (members is! List) {
      throw const FormatException(
        'The attendance response does not contain a members list.',
      );
    }
    return members
        .whereType<Map>()
        .map((member) => Map<String, dynamic>.from(member))
        .toList();
  }

  String? _memberId(Map<String, dynamic> member) {
    return (member['_id'] ?? member['id'] ?? member['memberId'])?.toString();
  }

  String _memberName(Map<String, dynamic> member) {
    final name =
        (member['fullName'] ?? member['name'] ?? member['firstName'] ?? '')
            .toString()
            .trim();
    return name.isEmpty ? 'Unnamed member' : name;
  }
}
