class AttendanceChartCounts {
  const AttendanceChartCounts({
    required this.total,
    required this.present,
    required this.absent,
    required this.unmarked,
  });

  factory AttendanceChartCounts.fromStatuses(Iterable<String> statuses) {
    var present = 0;
    var absent = 0;
    var unmarked = 0;

    for (final status in statuses) {
      switch (status.toLowerCase()) {
        case 'present':
          present++;
        case 'absent':
          absent++;
        default:
          unmarked++;
      }
    }

    return AttendanceChartCounts(
      total: present + absent + unmarked,
      present: present,
      absent: absent,
      unmarked: unmarked,
    );
  }

  final int total;
  final int present;
  final int absent;
  final int unmarked;

  double get attendancePercentage {
    final marked = present + absent;
    return marked == 0 ? 0 : present / marked * 100;
  }
}

class AttendanceChartData {
  AttendanceChartData._();

  static List<DateTime> sundaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;

    return [
      for (var day = 1; day <= lastDay; day++)
        if (DateTime(year, month, day).weekday == DateTime.sunday)
          DateTime(year, month, day),
    ];
  }

  static List<DateTime> sundaysInYear(int year) {
    return [
      for (var month = 1; month <= 12; month++)
        ...sundaysInMonth(year, month),
    ];
  }

  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String statusForDate(
    DateTime date,
    Map<String, String> statusByDate,
  ) {
    switch (statusByDate[dateKey(date)]?.toLowerCase()) {
      case 'present':
        return 'present';
      case 'absent':
        return 'absent';
      default:
        return 'unmarked';
    }
  }
}
