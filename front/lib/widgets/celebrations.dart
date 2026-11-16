import 'dart:async';
import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/member_service.dart';

DateTime churchToday(DateTime instant) {
  final local = instant.toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime.utc(local.year, local.month, local.day);
}

class Celebration {
  const Celebration(this.member, this.date, this.anniversary);
  final Member member;
  final DateTime date;
  final bool anniversary;
}

List<Celebration> celebrationsForWeek(List<Member> members, DateTime today) {
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final events = <Celebration>[];
  for (var offset = 0; offset < 7; offset++) {
    final day = monday.add(Duration(days: offset));
    for (final member in members) {
      for (final anniversary in [false, true]) {
        final source = anniversary ? member.marriageDate : member.dob;
        if (source != null &&
            source.month == day.month &&
            source.day == day.day) {
          events.add(Celebration(member, day, anniversary));
        }
      }
    }
  }
  events.sort((a, b) {
    final date = a.date.compareTo(b.date);
    return date != 0 ? date : a.member.name.compareTo(b.member.name);
  });
  return events;
}

class Celebrations extends StatefulWidget {
  const Celebrations({super.key});
  @override
  State<Celebrations> createState() => CelebrationsState();
}

class CelebrationsState extends State<Celebrations>
    with WidgetsBindingObserver {
  List<Member> _members = [];
  bool _loading = true;
  String? _error;
  DateTime _today = churchToday(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (churchToday(DateTime.now()) != _today) refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _today = churchToday(DateTime.now());
    });
    try {
      final members = await MemberService().getMembers();
      if (mounted)
        setState(() {
          _members = members;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Unable to load celebrations.';
        });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = celebrationsForWeek(_members, _today);
    Widget section(String title, List<Celebration> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD6F078),
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Text(
            'No celebrations.',
            style: TextStyle(color: Color(0xFFA1A5AA)),
          ),
        for (final event in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  event.anniversary
                      ? Icons.favorite_outline
                      : Icons.cake_outlined,
                  color: const Color(0xFF75D99A),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.member.name,
                        style: const TextStyle(
                          color: Color(0xFFF5F5F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${event.anniversary ? 'Wedding anniversary' : 'Birthday'} · ${event.date.day}/${event.date.month}',
                        style: const TextStyle(color: Color(0xFFA1A5AA)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151719),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF292D31)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Celebrations',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF5F5F5),
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : refresh,
                tooltip: 'Refresh celebrations',
                icon: const Icon(Icons.refresh, color: Color(0xFF75D99A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: refresh, child: const Text('Retry')),
          ] else ...[
            section('Today', events.where((e) => e.date == _today).toList()),
            const Divider(height: 32, color: Color(0xFF292D31)),
            section(
              'This week · Monday–Sunday',
              events.where((e) => e.date != _today).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
