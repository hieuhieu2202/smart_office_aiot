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
  WinScpUploadService({
    StpController? controller,
    bool shareSessionWithStpModule = true,
  })  : _shareSessionWithStpModule = shareSessionWithStpModule,
        _stpController = shareSessionWithStpModule
            ? controller ??
                (Get.isRegistered<StpController>()
                    ? Get.find<StpController>()
                    : Get.put(StpController()))
            : null;

  final bool _shareSessionWithStpModule;
  final StpController? _stpController;
  SSHClient? _standaloneSshClient;
  SftpClient? _standaloneSftpClient;

  static const _fallbackHost = '10.220.130.114';
  static const _fallbackPort = 6742;
  static const _fallbackUsername = 'automation';
  static const _fallbackPassword = 'auto123';

  Future<SftpClient> _ensureSftpClient() async {
    if (_shareSessionWithStpModule) {
      final controller = _stpController!;

      if (controller.isConnected.value && controller.sftpClient != null) {
        return controller.sftpClient!;
      }

      if (controller.host.value.isEmpty ||
          controller.username.value.isEmpty ||
          controller.password.value.isEmpty) {
        await controller.connectWithCredentials(
          host: _fallbackHost,
          port: _fallbackPort,
          username: _fallbackUsername,
          password: _fallbackPassword,
          remember: false,
        );
      } else {
        await controller.connectToSftp();
      }

      if (!controller.isConnected.value || controller.sftpClient == null) {
        throw const FileSystemException('Unable to connect to WinSCP server');
      }

      return controller.sftpClient!;
    }

    return _ensureStandaloneClient();
  }

  Future<SftpClient> _ensureStandaloneClient() async {
    final cached = _standaloneSftpClient;
    if (cached != null) {
      return cached;
    }

    try {
      final socket = await SSHSocket.connect(_fallbackHost, _fallbackPort);
      final sshClient = SSHClient(
        socket,
        username: _fallbackUsername,
        onPasswordRequest: () => _fallbackPassword,
      );

      final sftpClient = await sshClient.sftp();
      _standaloneSshClient = sshClient;
      _standaloneSftpClient = sftpClient;
      return sftpClient;
    } catch (error) {
      throw FileSystemException('Unable to connect to WinSCP server: $error');
    }
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

  Future<void> dispose() async {
    if (_shareSessionWithStpModule) {
      return;
    }

    final sftpClient = _standaloneSftpClient;
    final sshClient = _standaloneSshClient;
    _standaloneSftpClient = null;
    _standaloneSshClient = null;

    if (sftpClient != null) {
      await sftpClient.close();
    }

    if (sshClient != null) {
      await sshClient.close();
    }
  }
}
