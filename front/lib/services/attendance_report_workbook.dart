import 'package:excel/excel.dart';

class WeeklyAttendanceMember {
  const WeeklyAttendanceMember({required this.name, required this.status});

  final String name;
  final String status;
}

class MonthlyAttendanceMember {
  const MonthlyAttendanceMember({required this.id, required this.name});

  final String id;
  final String name;
}

class AttendanceReportWorkbook {
  AttendanceReportWorkbook._();

  static const _churchName = 'church';
  static const _sheetGreen = 'FF1B5E20';
  static final _border = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: ExcelColor.grey,
  );

  static List<int> weekly({
    required String date,
    required String generatedDate,
    required List<WeeklyAttendanceMember> members,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Weekly Attendance';
    excel.rename('Sheet1', sheetName);
    final columnCount = 4;

    _mergeRow(excel, sheetName, 0, columnCount);
    _writeRow(excel, sheetName, 0, [_churchName], style: _titleStyle);
    _mergeRow(excel, sheetName, 1, columnCount);
    _writeRow(
      excel,
      sheetName,
      1,
      ['Weekly Attendance Report'],
      style: _subtitleStyle,
    );
    _mergeRow(excel, sheetName, 2, columnCount);
    _writeRow(excel, sheetName, 2, ['Attendance Date: $date']);
    _mergeRow(excel, sheetName, 3, columnCount);
    _writeRow(excel, sheetName, 3, ['Report Generated: $generatedDate']);

    const headerRow = 5;
    _writeRow(
      excel,
      sheetName,
      headerRow,
      ['S.No.', 'Member Name', 'Attendance Status', 'Attendance Date'],
      style: _headerStyle,
    );

    var present = 0;
    var absent = 0;
    var unmarked = 0;
    for (var index = 0; index < members.length; index++) {
      final member = members[index];
      final status = _normalizeStatus(member.status);
      switch (status) {
        case 'Present':
          present++;
        case 'Absent':
          absent++;
        default:
          unmarked++;
      }
      _writeRow(excel, sheetName, headerRow + index + 1, [
        '${index + 1}',
        member.name,
        status,
        date,
      ], style: _bodyStyle);
    }

    final totalsRow = headerRow + members.length + 2;
    _writeRow(
      excel,
      sheetName,
      totalsRow,
      ['Totals', 'Present: $present', 'Absent: $absent', 'Unmarked: $unmarked'],
      style: _summaryStyle,
    );

    final sheet = excel[sheetName];
    sheet.setColumnWidth(0, 10);
    sheet.setColumnWidth(1, 32);
    sheet.setColumnWidth(2, 24);
    sheet.setColumnWidth(3, 20);

    return _encode(excel);
  }

  static List<int> monthly({
    required int year,
    required int month,
    required String generatedDate,
    required List<DateTime> sundays,
    required List<MonthlyAttendanceMember> members,
    required Map<String, Map<String, String>> statusByMemberAndDate,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Monthly Attendance';
    excel.rename('Sheet1', sheetName);

    final finalColumn = sundays.length + 2;
    final columnCount = finalColumn + 1;
    final monthName = _monthName(month);

    _mergeRow(excel, sheetName, 0, columnCount);
    _writeRow(
      excel,
      sheetName,
      0,
      [_churchName],
      style: _titleStyle,
    );
    _mergeRow(excel, sheetName, 1, columnCount);
    _writeRow(
      excel,
      sheetName,
      1,
      ['$monthName $year Attendance Report'],
      style: _subtitleStyle,
    );
    _mergeRow(excel, sheetName, 2, columnCount);
    _writeRow(excel, sheetName, 2, ['Report Generated: $generatedDate']);

    const headerRow = 4;
    final headers = <String>['S.No.', 'Member Name'];
    headers.addAll(sundays.map((date) => _dateKey(date)));
    headers.add('Present / Absent / Attendance %');
    _writeRow(excel, sheetName, headerRow, headers, style: _headerStyle);

    final dateTotals = List.generate(
      sundays.length,
      (_) => <String, int>{'Present': 0, 'Absent': 0, 'Unmarked': 0},
    );
    var rowIndex = headerRow + 1;
    for (var memberIndex = 0; memberIndex < members.length; memberIndex++) {
      final member = members[memberIndex];
      final statuses = <String>[];
      var present = 0;
      var absent = 0;

      for (var sundayIndex = 0; sundayIndex < sundays.length; sundayIndex++) {
        final key = _dateKey(sundays[sundayIndex]);
        final status = _normalizeStatus(
          statusByMemberAndDate[member.id]?[key] ?? 'unmarked',
        );
        statuses.add(status);
        dateTotals[sundayIndex][status] =
            dateTotals[sundayIndex][status]! + 1;
        if (status == 'Present') present++;
        if (status == 'Absent') absent++;
      }

      final marked = present + absent;
      final percentage = marked == 0 ? 0.0 : present / marked * 100;
      _writeRow(excel, sheetName, rowIndex++, [
        '${memberIndex + 1}',
        member.name,
        ...statuses,
        'Present: $present; Absent: $absent; '
            'Attendance: ${percentage.toStringAsFixed(1)}%',
      ], style: _bodyStyle);
    }

    rowIndex++;
    _mergeRow(excel, sheetName, rowIndex, columnCount);
    _writeRow(
      excel,
      sheetName,
      rowIndex++,
      ['Overall Attendance Totals by Sunday'],
      style: _subtitleStyle,
    );
    _writeRow(
      excel,
      sheetName,
      rowIndex++,
      ['Sunday', 'Present', 'Absent', 'Unmarked'],
      style: _headerStyle,
    );
    for (var index = 0; index < sundays.length; index++) {
      final totals = dateTotals[index];
      _writeRow(excel, sheetName, rowIndex++, [
        _dateKey(sundays[index]),
        '${totals['Present']}',
        '${totals['Absent']}',
        '${totals['Unmarked']}',
      ], style: _bodyStyle);
    }

    final sheet = excel[sheetName];
    sheet.setColumnWidth(0, 10);
    sheet.setColumnWidth(1, 30);
    for (var index = 0; index < sundays.length; index++) {
      sheet.setColumnWidth(index + 2, 18);
    }
    sheet.setColumnWidth(finalColumn, 42);

    return _encode(excel);
  }

  static void _mergeRow(
    Excel excel,
    String sheetName,
    int rowIndex,
    int columnCount,
  ) {
    if (columnCount < 2) return;
    excel.merge(
      sheetName,
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(
        columnIndex: columnCount - 1,
        rowIndex: rowIndex,
      ),
    );
  }

  static void _writeRow(
    Excel excel,
    String sheetName,
    int rowIndex,
    List<String> values, {
    CellStyle? style,
  }) {
    for (var columnIndex = 0; columnIndex < values.length; columnIndex++) {
      excel.updateCell(
        sheetName,
        CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: rowIndex,
        ),
        TextCellValue(values[columnIndex]),
        cellStyle: style,
      );
    }
  }

  static String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      default:
        return 'Unmarked';
    }
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _monthName(int month) {
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
    if (month < 1 || month > months.length) {
      throw ArgumentError.value(month, 'month', 'Must be between 1 and 12.');
    }
    return months[month - 1];
  }

  static List<int> _encode(Excel excel) {
    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Could not generate the Excel workbook.');
    }
    return bytes;
  }

  static final _titleStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString(_sheetGreen),
    fontColorHex: ExcelColor.white,
    fontSize: 16,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final _subtitleStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('FFE8F5E9'),
    fontColorHex: ExcelColor.fromHexString(_sheetGreen),
    fontSize: 12,
    bold: true,
  );

  static final _headerStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString(_sheetGreen),
    fontColorHex: ExcelColor.white,
    bold: true,
    textWrapping: TextWrapping.WrapText,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    bottomBorder: _border,
  );

  static final _bodyStyle = CellStyle(
    verticalAlign: VerticalAlign.Center,
    bottomBorder: _border,
  );

  static final _summaryStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('FFE8F5E9'),
    fontColorHex: ExcelColor.fromHexString(_sheetGreen),
    bold: true,
    bottomBorder: _border,
  );
}
