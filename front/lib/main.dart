import 'package:flutter/material.dart';

import 'models/auth_user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'utils/secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChurchAttendanceApp());
}

class ChurchAttendanceApp extends StatelessWidget {
  const ChurchAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF176B45);

    return MaterialApp(
      title: 'Church Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF6F8F6),
          foregroundColor: Color(0xFF183B2B),
        ),
      ),
      home: const StartupAuthGate(),
    );
  }
}

class StartupAuthGate extends StatefulWidget {
  const StartupAuthGate({super.key});

  @override
  State<StartupAuthGate> createState() => _StartupAuthGateState();
}

class _StartupAuthGateState extends State<StartupAuthGate> {
  final AuthService _authService = AuthService();

  AuthUser? _user;
  Object? _restoreError;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _restoring = true;
      _restoreError = null;
    });

    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _user = null;
          _restoring = false;
        });
        return;
      }

      final user = await _authService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _restoring = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401 || error.statusCode == 403) {
        setState(() {
          _user = null;
          _restoring = false;
        });
        return;
      }

      await _restoreCachedUser(error);
    } catch (error) {
      await _restoreCachedUser(error);
    }
  }

  Future<void> _restoreCachedUser(Object error) async {
    try {
      final cachedUser = await SecureStorage.getUser();
      if (!mounted) return;

      setState(() {
        _user = cachedUser;
        _restoreError = cachedUser == null ? error : null;
        _restoring = false;
      });
    } catch (storageError) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _restoreError = storageError;
        _restoring = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF176B45)),
        ),
      );
    }

    if (_user != null) {
      return HomeScreen(initialUser: _user!);
    }

    if (_restoreError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: Color(0xFF176B45),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not verify your saved session. '
                    'Your session has not been cleared. Check your network '
                    'and retry.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _restoreSession,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const LoginScreen();
  }
}
