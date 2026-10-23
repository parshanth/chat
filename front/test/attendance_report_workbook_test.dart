import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_attendance/services/attendance_report_workbook.dart';

String _cellText(Sheet sheet, int column, int row) {
  final value = sheet
      .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
      .value;
  return (value as TextCellValue).value.text ?? '';
}

void main() {
  group('AttendanceReportWorkbook', () {
    test('creates a valid weekly workbook with statuses and totals', () {
      final bytes = AttendanceReportWorkbook.weekly(
        date: '2026-10-25',
        generatedDate: '2026-10-22',
        members: const [
          WeeklyAttendanceMember(name: 'Member One', status: 'present'),
          WeeklyAttendanceMember(name: 'Member Two', status: 'absent'),
          WeeklyAttendanceMember(name: 'Member Three', status: 'unmarked'),
        ],
      );

      expect(bytes.take(2).toList(), [0x50, 0x4b]);
      final workbook = Excel.decodeBytes(bytes);
      expect(workbook.tables.keys, contains('Weekly Attendance'));
      final sheet = workbook.tables['Weekly Attendance']!;
      expect(_cellText(sheet, 0, 0), 'Church');
      expect(_cellText(sheet, 0, 5), 'S.No.');
      expect(_cellText(sheet, 1, 6), 'Member One');
      expect(_cellText(sheet, 2, 6), 'Present');
      expect(_cellText(sheet, 2, 7), 'Absent');
      expect(_cellText(sheet, 2, 8), 'Unmarked');
      expect(_cellText(sheet, 1, 10), 'Present: 1');
      expect(_cellText(sheet, 2, 10), 'Absent: 1');
      expect(_cellText(sheet, 3, 10), 'Unmarked: 1');
    });

    test(
      'creates a monthly workbook with all Sundays and per-Sunday totals',
      () {
        final sundays = [
          DateTime(2023, 4, 2),
          DateTime(2023, 4, 9),
          DateTime(2023, 4, 16),
          DateTime(2023, 4, 23),
          DateTime(2023, 4, 30),
        ];
        final bytes = AttendanceReportWorkbook.monthly(
          year: 2023,
          month: 4,
          generatedDate: '2023-05-01',
          sundays: sundays,
          members: const [
            MonthlyAttendanceMember(id: 'member-1', name: 'Member One'),
            MonthlyAttendanceMember(id: 'member-2', name: 'Member Two'),
          ],
          statusByMemberAndDate: {
            'member-1': {
              '2023-04-02': 'present',
              '2023-04-09': 'absent',
              '2023-04-16': 'present',
              '2023-04-23': 'unmarked',
              '2023-04-30': 'present',
            },
            'member-2': {
              '2023-04-02': 'absent',
              '2023-04-09': 'unmarked',
              '2023-04-16': 'unmarked',
              '2023-04-23': 'unmarked',
              '2023-04-30': 'unmarked',
            },
          },
        );

        expect(bytes.take(2).toList(), [0x50, 0x4b]);
        final workbook = Excel.decodeBytes(bytes);
        expect(workbook.tables.keys, contains('Monthly Attendance'));
        final sheet = workbook.tables['Monthly Attendance']!;
        expect(_cellText(sheet, 0, 0), 'Church');
        expect(_cellText(sheet, 2, 4), '2023-04-02');
        expect(_cellText(sheet, 7, 4), 'Present / Absent / Attendance %');
        expect(
          _cellText(sheet, 7, 5),
          'Present: 3; Absent: 1; Attendance: 75.0%',
        );
        expect(_cellText(sheet, 0, 11), '2023-04-09');
        expect(_cellText(sheet, 1, 11), '0');
        expect(_cellText(sheet, 2, 11), '1');
        expect(_cellText(sheet, 3, 11), '1');
      },
    );
  });
}
