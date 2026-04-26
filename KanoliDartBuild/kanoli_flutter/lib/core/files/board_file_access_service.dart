import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

class BoardImportSelection {
  BoardImportSelection({required this.jsonPath, required this.boardPath});

  final String jsonPath;
  final String boardPath;
}

abstract class BoardFileAccessService {
  Future<String?> pickOpenBoardPath();
  Future<String?> pickCreateBoardPath({required String suggestedName});
  Future<BoardImportSelection?> pickImportBoardSelection({
    required String suggestedBoardName,
  });
}

class DefaultBoardFileAccessService implements BoardFileAccessService {
  static const MethodChannel _nativeDialogsChannel = MethodChannel(
    'kanoli/native_dialogs',
  );

  @override
  Future<String?> pickOpenBoardPath() async {
    if (Platform.isMacOS) {
      return _pickFileViaNativeDialog('openBoard');
    }

    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'Board Files', extensions: <String>['md', 'txt']),
      ],
    ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    return file?.path;
  }

  @override
  Future<String?> pickCreateBoardPath({required String suggestedName}) async {
    if (Platform.isMacOS) {
      return _pickSaveViaNativeDialog(suggestedName: suggestedName);
    }

    final saveLocation = await getSaveLocation(
      suggestedName: suggestedName,
    ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    return saveLocation?.path;
  }

  @override
  Future<BoardImportSelection?> pickImportBoardSelection({
    required String suggestedBoardName,
  }) async {
    if (Platform.isMacOS) {
      final jsonPath = await _pickFileViaNativeDialog('openJson');
      if (jsonPath == null || jsonPath.trim().isEmpty) {
        return null;
      }
      final boardPath = await _pickSaveViaNativeDialog(
        suggestedName: suggestedBoardName,
      );
      if (boardPath == null || boardPath.trim().isEmpty) {
        return null;
      }
      return BoardImportSelection(jsonPath: jsonPath, boardPath: boardPath);
    }

    final jsonFile = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'JSON',
          extensions: <String>['json'],
          mimeTypes: <String>['application/json', 'text/json'],
          uniformTypeIdentifiers: <String>['public.json'],
        ),
      ],
    ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    if (jsonFile == null) {
      return null;
    }

    final saveLocation = await getSaveLocation(
      suggestedName: suggestedBoardName,
    ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    if (saveLocation == null || saveLocation.path.trim().isEmpty) {
      return null;
    }

    return BoardImportSelection(
      jsonPath: jsonFile.path,
      boardPath: saveLocation.path,
    );
  }

  Future<String?> _pickSaveViaNativeDialog({
    required String suggestedName,
  }) async {
    try {
      final path = await _nativeDialogsChannel
          .invokeMethod<String>('saveBoard', <String, Object?>{
            'suggestedName': suggestedName,
          })
          .timeout(const Duration(seconds: 30), onTimeout: () => null);
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      return path.trim();
    } on PlatformException {
      return null;
    }
  }

  Future<String?> _pickFileViaNativeDialog(String method) async {
    try {
      final path = await _nativeDialogsChannel
          .invokeMethod<String>(method)
          .timeout(const Duration(seconds: 30), onTimeout: () => null);
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      return path.trim();
    } on PlatformException {
      return null;
    }
  }
}
