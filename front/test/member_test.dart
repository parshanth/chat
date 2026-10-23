import 'package:flutter_test/flutter_test.dart';
import 'package:church_attendance/models/member.dart';

void main() {
  group('Member', () {
    test('loads legacy records without a marriage date', () {
      final member = Member.fromJson({'_id': 'member-1', 'name': 'Member One'});

      expect(member.id, 'member-1');
      expect(member.marriageDate, isNull);
    });

    test('parses and serializes marriage dates as ISO 8601', () {
      final member = Member.fromJson({
        '_id': 'member-1',
        'name': 'Member One',
        'marriageDate': '2020-10-23T00:00:00.000Z',
      });

      expect(member.marriageDate, DateTime(2020, 10, 23));
      expect(member.toJson()['marriageDate'], '2020-10-23T00:00:00.000Z');
    });

    test('treats null or invalid dates as absent', () {
      expect(Member.fromJson({'marriageDate': null}).marriageDate, isNull);
      expect(
        Member.fromJson({'marriageDate': 'not a date'}).marriageDate,
        isNull,
      );
    });
  });
}
