import 'dart:convert';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

const kBackupFileName = 'xpense-backup.sqlite';

class _AuthedClient extends http.BaseClient {
  _AuthedClient(this._inner, this._headers);
  final http.Client _inner;
  final Map<String, String> _headers;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class BackupMetadata {
  final int schemaVersion;
  final DateTime createdAt;
  final int recordCount;
  final String appVersion;

  /// App settings (currency, theme, display name, balance visibility) so a
  /// restore on a new device brings these back too — not just the database.
  final Map<String, dynamic>? settings;

  const BackupMetadata({
    required this.schemaVersion,
    required this.createdAt,
    required this.recordCount,
    required this.appVersion,
    this.settings,
  });

  String toJsonString() => jsonEncode({
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'recordCount': recordCount,
        'appVersion': appVersion,
        if (settings != null) 'settings': settings,
      });

  static BackupMetadata? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return BackupMetadata(
        schemaVersion: m['schemaVersion'] as int? ?? 1,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        recordCount: m['recordCount'] as int? ?? 0,
        appVersion: m['appVersion'] as String? ?? 'unknown',
        settings: m['settings'] as Map<String, dynamic>?,
      );
    } catch (_) {
      return null;
    }
  }
}

class RemoteBackupInfo {
  final String fileId;
  final int sizeBytes;
  final DateTime modifiedAt;
  final BackupMetadata? metadata;
  const RemoteBackupInfo({
    required this.fileId,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.metadata,
  });
}

class DriveClient {
  DriveClient(this._account);
  final GoogleSignInAccount _account;

  Future<drive.DriveApi> _api() async {
    final headers = await _account.authHeaders;
    final client = _AuthedClient(http.Client(), headers);
    return drive.DriveApi(client);
  }

  Future<RemoteBackupInfo?> findBackup() async {
    final api = await _api();
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$kBackupFileName' and trashed = false",
      $fields: 'files(id, name, size, modifiedTime, description)',
      pageSize: 5,
    );
    final files = list.files ?? const <drive.File>[];
    if (files.isEmpty) return null;
    // Latest-modified wins.
    files.sort((a, b) =>
        (b.modifiedTime ?? DateTime(0))
            .compareTo(a.modifiedTime ?? DateTime(0)));
    final f = files.first;
    return RemoteBackupInfo(
      fileId: f.id!,
      sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
      modifiedAt: f.modifiedTime ?? DateTime.now(),
      metadata: BackupMetadata.tryParse(f.description),
    );
  }

  Future<void> uploadOrUpdate(
      Uint8List bytes, BackupMetadata metadata) async {
    final api = await _api();
    final existing = await findBackup();
    final media = drive.Media(Stream.value(bytes), bytes.length);
    if (existing == null) {
      final file = drive.File()
        ..name = kBackupFileName
        ..parents = ['appDataFolder']
        ..description = metadata.toJsonString();
      await api.files.create(file, uploadMedia: media);
    } else {
      final file = drive.File()..description = metadata.toJsonString();
      await api.files.update(file, existing.fileId, uploadMedia: media);
    }
  }

  Future<Uint8List> download(String fileId) async {
    final api = await _api();
    final media = await api.files.get(fileId,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }
}
