import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A build published on the "latest" GitHub release (from its version.json).
class UpdateInfo {
  final int versionCode;
  final String versionName;
  final List<String> changes;
  const UpdateInfo(this.versionCode, this.versionName, this.changes);

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        (json['versionCode'] as num).toInt(),
        json['versionName'] as String? ?? '',
        [for (final c in json['changes'] as List? ?? const []) c.toString()],
      );
}

/// Keeps the app up to date from the repository's "latest" GitHub release,
/// the same way Torrent Study does: CI publishes PantryChef.apk and a
/// version.json describing it; the app reads version.json, and when it names
/// a newer build it offers to download the APK and open Android's install
/// screen. Every build is signed with the same key, so installing it keeps
/// all your data. The repository is public, so no token is needed.
class Updater extends ChangeNotifier {
  static const _base = 'https://github.com/ridhun30/PantryChef/releases/download/latest/';
  static const _channel = MethodChannel('pantry_chef/update');
  static const _minInterval = Duration(hours: 1);

  /// False off Android (tests, desktop/web previews): nothing to update.
  bool supported = false;
  int installedCode = 0;
  String installedName = '';
  String? _cacheDir;

  UpdateInfo? available;
  bool checking = false;
  double? downloadProgress; // non-null while downloading (0..1, or -1 if unknown size)
  String? error;
  DateTime? lastCheck;
  bool dismissed = false;

  bool get hasUpdate => available != null && available!.versionCode > installedCode;
  bool get downloading => downloadProgress != null;

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('info');
      if (info == null) return;
      installedCode = (info['versionCode'] as num).toInt();
      installedName = info['versionName'] as String? ?? '';
      _cacheDir = info['cacheDir'] as String?;
      supported = true;
    } catch (err) {
      debugPrint('Updates unavailable: $err');
    }
  }

  /// Reads version.json from the latest release. Quiet: failures are only
  /// shown where the user asked for a check ([force]).
  Future<void> check({bool force = false}) async {
    if (!supported || checking || downloading) return;
    if (!force && lastCheck != null && DateTime.now().difference(lastCheck!) < _minInterval) return;
    checking = true;
    error = null;
    notifyListeners();
    try {
      final bytes = await _get('${_base}version.json?t=${DateTime.now().millisecondsSinceEpoch}');
      final info = UpdateInfo.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
      if (info.versionCode != available?.versionCode) dismissed = false;
      available = info;
      lastCheck = DateTime.now();
    } catch (err) {
      error = force ? _describe(err) : null;
    } finally {
      checking = false;
      notifyListeners();
    }
  }

  /// Downloads the new APK and hands it to Android's installer.
  Future<void> downloadAndInstall() async {
    final update = available;
    if (!supported || update == null || downloading || _cacheDir == null) return;
    error = null;
    downloadProgress = 0;
    notifyListeners();
    try {
      final dir = Directory('$_cacheDir/updates');
      if (dir.existsSync()) dir.deleteSync(recursive: true); // old downloads
      dir.createSync(recursive: true);
      final apk = File('${dir.path}/PantryChef-${update.versionCode}.apk');
      await _download('${_base}PantryChef.apk?t=${DateTime.now().millisecondsSinceEpoch}', apk);
      // The native side checks the file really is this app at that version
      // before opening the installer.
      await _channel.invokeMethod<void>('install', {'path': apk.path, 'versionCode': update.versionCode});
    } catch (err) {
      error = _describe(err);
    } finally {
      downloadProgress = null;
      notifyListeners();
    }
  }

  void dismiss() {
    dismissed = true;
    notifyListeners();
  }

  HttpClient _client() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..userAgent = 'PantryChef-updater';

  Future<Uint8List> _get(String url) async {
    final client = _client();
    try {
      final response = await (await client.getUrl(Uri.parse(url))).close().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
      final builder = BytesBuilder(copy: false);
      await response.timeout(const Duration(seconds: 30)).forEach(builder.add);
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _download(String url, File to) async {
    final client = _client();
    final sink = to.openWrite();
    try {
      final response = await (await client.getUrl(Uri.parse(url))).close().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
      final total = response.contentLength;
      var received = 0;
      var lastShown = 0.0;
      await for (final chunk in response.timeout(const Duration(seconds: 60))) {
        sink.add(chunk);
        received += chunk.length;
        final p = total > 0 ? received / total : -1.0;
        if (p < 0 || p - lastShown >= 0.02) {
          lastShown = p;
          downloadProgress = p;
          notifyListeners();
        }
      }
      if (total > 0 && received != total) throw const HttpException('the download was cut short');
    } finally {
      await sink.close();
      client.close(force: true);
    }
  }

  String _describe(Object err) {
    if (err is SocketException || err is TimeoutException) return 'No connection to GitHub — try again later.';
    if (err is HttpException && err.message == 'HTTP 404') return 'No published build found yet.';
    if (err is PlatformException) return err.message ?? err.code;
    if (err is HttpException) return 'Download failed: ${err.message}';
    return err.toString();
  }
}
