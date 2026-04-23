import 'dart:async';
import 'package:flutter/material.dart';

import '../core/config/app_environment.dart';
import '../core/logging/app_logger.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/board/application/board_session_controller.dart';
import '../features/board/presentation/board_workspace_page.dart';

class KanoliApp extends StatefulWidget {
  const KanoliApp({super.key, required this.environment, required this.logger});

  final AppEnvironment environment;
  final AppLogger logger;

  @override
  State<KanoliApp> createState() => _KanoliAppState();
}

class _KanoliAppState extends State<KanoliApp> {
  late final BoardSessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = BoardSessionController(logger: widget.logger);
    unawaited(_sessionController.restoreSessionIfAvailable());
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
      ),
    );
  }
}
