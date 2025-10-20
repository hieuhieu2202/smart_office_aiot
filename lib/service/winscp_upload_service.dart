import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:get/get.dart';

import 'package:smart_factory/screen/stp/controller/stp_controller.dart';

class RemoteDirectoryEntry {
  const RemoteDirectoryEntry({
    required this.name,
    required this.path,
  });

  final String name;
  final String path;
}

class WinScpUploadService {
  WinScpUploadService({StpController? controller})
      : _stpController = controller ??
            (Get.isRegistered<StpController>()
                ? Get.find<StpController>()
                : Get.put(StpController()));

  final StpController _stpController;

  static const _fallbackHost = '10.220.130.114';
  static const _fallbackPort = 6742;
  static const _fallbackUsername = 'automation';
  static const _fallbackPassword = 'auto123';

  Future<SftpClient> _ensureSftpClient() async {
    if (_stpController.isConnected.value &&
        _stpController.sftpClient != null) {
      return _stpController.sftpClient!;
    }

    if (_stpController.host.value.isEmpty ||
        _stpController.username.value.isEmpty ||
        _stpController.password.value.isEmpty) {
      await _stpController.connectWithCredentials(
        host: _fallbackHost,
        port: _fallbackPort,
        username: _fallbackUsername,
        password: _fallbackPassword,
        remember: false,
      );
    } else {
      await _stpController.connectToSftp();
    }

    if (!_stpController.isConnected.value ||
        _stpController.sftpClient == null) {
      throw const FileSystemException('Unable to connect to WinSCP server');
    }

    return _stpController.sftpClient!;
  }

  Future<List<RemoteDirectoryEntry>> listDirectories(String path) async {
    final client = await _ensureSftpClient();
    final sanitizedPath = path.isEmpty ? '/' : path;
    final entries = <RemoteDirectoryEntry>[];

    await for (final batch in client.readdir(sanitizedPath)) {
      for (final item in batch) {
        final name = item.filename;
        if (name == '.' || name == '..') {
          continue;
        }
        if (item.attr.isDirectory) {
          final nextPath = sanitizedPath == '/'
              ? '/$name'
              : '$sanitizedPath/$name';
          entries.add(RemoteDirectoryEntry(name: name, path: nextPath));
        }
      }
    }

    entries.sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }

  Future<String> uploadFile({
    required File file,
    required String remoteDirectory,
    required String remoteFileName,
  }) async {
    final client = await _ensureSftpClient();
    final sanitizedDirectory = remoteDirectory.isEmpty ? '/' : remoteDirectory;
    final sanitizedFileName = remoteFileName.trim();
    if (sanitizedFileName.isEmpty) {
      throw const FileSystemException('Invalid file name');
    }

    final remotePath = sanitizedDirectory == '/'
        ? '/$sanitizedFileName'
        : '$sanitizedDirectory/$sanitizedFileName';

    final bytes = await file.readAsBytes();
    final handle = await client.open(
      remotePath,
      mode: SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );
    await handle.writeBytes(bytes);
    await handle.close();

    return remotePath;
  }
}
