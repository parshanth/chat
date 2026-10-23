import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_basic_app/utils/attendance_chart_data.dart';

void main() {
  group('AttendanceChartData', () {
    test('generates four- and five-Sunday months within their boundaries', () {
      expect(AttendanceChartData.sundaysInMonth(2023, 3), [
        DateTime(2023, 3, 5),
        DateTime(2023, 3, 12),
        DateTime(2023, 3, 19),
        DateTime(2023, 3, 26),
      ]);
      expect(AttendanceChartData.sundaysInMonth(2023, 4), [
        DateTime(2023, 4, 2),
        DateTime(2023, 4, 9),
        DateTime(2023, 4, 16),
        DateTime(2023, 4, 23),
        DateTime(2023, 4, 30),
      ]);
    });

    test('supports years with 52 and 53 Sundays', () {
      expect(AttendanceChartData.sundaysInYear(2023), hasLength(53));
      expect(AttendanceChartData.sundaysInYear(2024), hasLength(52));
    });

    test('uses unmarked for missing or unsupported attendance statuses', () {
      final statuses = {
        '2024-01-07': 'present',
        '2024-01-14': 'absent',
        '2024-01-21': 'unmarked',
      };

      expect(
        AttendanceChartData.statusForDate(DateTime(2024, 1, 7), statuses),
        'present',
      );
      expect(
        AttendanceChartData.statusForDate(DateTime(2024, 1, 14), statuses),
        'absent',
      );
      expect(
        AttendanceChartData.statusForDate(DateTime(2024, 1, 21), statuses),
        'unmarked',
      );
      expect(
        AttendanceChartData.statusForDate(DateTime(2024, 1, 28), statuses),
        'unmarked',
      );
    });

    test('excludes unmarked Sundays from attendance percentage', () {
      final counts = AttendanceChartCounts.fromStatuses([
        'present',
        'present',
        'absent',
        'unmarked',
        'unmarked',
      ]);

      expect(counts.total, 5);
      expect(counts.present, 2);
      expect(counts.absent, 1);
      expect(counts.unmarked, 2);
      expect(counts.attendancePercentage, closeTo(66.6667, 0.001));
      expect(
        AttendanceChartCounts.fromStatuses(['unmarked']).attendancePercentage,
        0,
      );
    });
  });
}
