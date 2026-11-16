import 'dart:async';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

Future<void> openActivityLogs(BuildContext context) async {
  final controller = TextEditingController();
  final secret = await showDialog<String>(context: context, builder: (context) => AlertDialog(
    title: const Text('Activity logs'),
    content: TextField(controller: controller, obscureText: true, autofocus: true,
      decoration: const InputDecoration(labelText: 'Secret code'),
      onSubmitted: (value) => Navigator.pop(context, value)),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Unlock'))],
  ));
  // The dialog finishes its closing animation before its controller is disposed.
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  if (secret == null || !context.mounted) return;
  try {
    final result = await AttendanceService.instance.getActivityLogs(secret);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActivityLogsScreen(secret: secret, initial: result)));
  } catch (error) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
  }
}

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key, required this.secret, required this.initial});
  final String secret;
  final Map<String, dynamic> initial;
  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> with WidgetsBindingObserver {
  late List<dynamic> _logs;
  late bool _hasMore;
  bool _busy = false;
  String? _error;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _logs = List.of(widget.initial['logs'] as List);
    _hasMore = widget.initial['hasMore'] == true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }
  Future<void> _load({bool older = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await AttendanceService.instance.getActivityLogs(widget.secret,
        before: older && _logs.isNotEmpty ? _logs.last['_id'].toString() : null);
      if (!mounted) return;
      setState(() {
        final incoming = result['logs'] as List;
        if (older) {
          final ids = _logs.map((e) => e['_id']).toSet();
          _logs.addAll(incoming.where((e) => !ids.contains(e['_id'])));
          _hasMore = result['hasMore'] == true;
        } else {
          // Preserve previously loaded history while inserting refreshed entries.
          final byId = {for (final entry in [..._logs, ...incoming]) entry['_id']: entry};
          _logs = byId.values.toList()..sort((a, b) => b['_id'].toString().compareTo(a['_id'].toString()));
          if (_logs.length <= 100) _hasMore = result['hasMore'] == true;
        }
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally { _busy = false; }
  }
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF090A0B),
    appBar: AppBar(title: const Text('Activity logs'), backgroundColor: const Color(0xFF151719), foregroundColor: Colors.white),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
      child: RefreshIndicator(onRefresh: _load, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
          if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFFF8585))),
          if (_logs.isEmpty) const Text('No activity yet. New attendance changes will appear here.', style: TextStyle(color: Colors.white70)),
          for (final entry in _logs) Padding(padding: const EdgeInsets.only(bottom: 12),
            child: Text(entry['message'].toString(), style: const TextStyle(fontFamily: 'DMSans', color: Color(0xFFF5F5F5), fontSize: 15))),
          if (_hasMore) TextButton(onPressed: () => _load(older: true), child: const Text('Load older activity')),
        ],
      )),
    )),
  );
}
