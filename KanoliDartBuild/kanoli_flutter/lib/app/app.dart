import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_environment.dart';
import '../core/files/board_file_access_service.dart';
import '../core/logging/app_logger.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/board/application/board_session_controller.dart';
import '../features/board/presentation/board_workspace_page.dart';

class KanoliApp extends StatefulWidget {
  const KanoliApp({
    super.key,
    required this.environment,
    required this.logger,
    required this.previousStartupIncomplete,
    required this.startupStateKey,
  });

  final AppEnvironment environment;
  final AppLogger logger;
  final bool previousStartupIncomplete;
  final String startupStateKey;

  @override
  State<KanoliApp> createState() => _KanoliAppState();
}

class _KanoliAppState extends State<KanoliApp> {
  late final BoardSessionController _sessionController;
  late final BoardFileAccessService _fileAccessService;

  @override
  void initState() {
    super.initState();
    _sessionController = BoardSessionController(logger: widget.logger);
    _fileAccessService = DefaultBoardFileAccessService();
    unawaited(_restoreSessionAfterNativeStartup());
    unawaited(_markStartupCompleted());
    if (widget.previousStartupIncomplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_promptSafeModeRecovery());
      });
    }
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanoli',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkAura,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: BoardWorkspacePage(
        environment: widget.environment,
        controller: _sessionController,
        fileAccessService: _fileAccessService,
      ),
    );
  }

  Future<void> _restoreSessionAfterNativeStartup() async {
    await _sessionController.restoreSessionIfAvailable();
    if (_sessionController.hasActiveBoard) {
      return;
    }

    // On macOS, native bookmark restoration can finish shortly after
    // Flutter startup. Retry once to avoid a launch-order race.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || _sessionController.hasActiveBoard) {
      return;
    }
    await _sessionController.restoreSessionIfAvailable();
  }

  Future<void> _markStartupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.startupStateKey, false);
  }

  Future<void> _promptSafeModeRecovery() async {
    if (!mounted) {
      return;
    }
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recover From Previous Startup'),
          content: const Text(
            'Kanoli detected the previous launch may have ended unexpectedly.\n\n'
            'Would you like to start in safe mode by clearing remembered session data?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Session'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Safe Mode'),
            ),
          ],
        );
      },
    );
    if (shouldClear == true) {
      await _sessionController.clearRememberedSessionData();
      _sessionController.clearSession();
    }
  }
}
