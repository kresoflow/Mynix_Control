import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mynix_frontend/features/pos/services/lan/local_pos_client.dart';
import 'package:mynix_frontend/features/pos/services/lan/local_pos_server.dart';

class LanSettingsData {
  final String role; // 'standalone', 'master', 'client'
  final String masterIp;
  final int port;
  final bool isServerEnabled;

  const LanSettingsData({
    required this.role,
    required this.masterIp,
    required this.port,
    required this.isServerEnabled,
  });

  bool get isMaster => role == 'master';
  bool get isClient => role == 'client';
  bool get isStandalone => role == 'standalone';
}

class LanSettingsService {
  static const String boxName = 'lan_settings';
  static Box? _box;

  static final ValueNotifier<LanSettingsData> settingsNotifier =
      ValueNotifier<LanSettingsData>(
    const LanSettingsData(
      role: 'standalone',
      masterIp: '192.168.1.10',
      port: 8080,
      isServerEnabled: true,
    ),
  );

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }

    final role = _box!.get('role', defaultValue: defaultRole) as String;
    final masterIp = _box!.get('master_ip', defaultValue: '192.168.1.10') as String;
    final port = (_box!.get('port', defaultValue: 8080) as num).toInt();
    final isServerEnabled = _box!.get('is_server_enabled', defaultValue: true) as bool;

    settingsNotifier.value = LanSettingsData(
      role: role,
      masterIp: masterIp,
      port: port,
      isServerEnabled: isServerEnabled,
    );

    // If configured as master, start local server automatically
    if (role == 'master' && isServerEnabled) {
      await LocalPosServer.start(serverPort: port);
    }
  }

  static String get defaultRole {
    if (kIsWeb) return 'client';
    // On desktop, default to master
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'master';
    }
    return 'client';
  }

  static LanSettingsData get current => settingsNotifier.value;

  static Future<void> setRole(String role) async {
    await _box?.put('role', role);
    settingsNotifier.value = LanSettingsData(
      role: role,
      masterIp: current.masterIp,
      port: current.port,
      isServerEnabled: current.isServerEnabled,
    );

    if (role == 'master' && current.isServerEnabled) {
      await LocalPosServer.start(serverPort: current.port);
    } else {
      await LocalPosServer.stop();
    }
  }

  static Future<void> setMasterIp(String ip) async {
    await _box?.put('master_ip', ip.trim());
    settingsNotifier.value = LanSettingsData(
      role: current.role,
      masterIp: ip.trim(),
      port: current.port,
      isServerEnabled: current.isServerEnabled,
    );
  }

  static Future<void> setPort(int port) async {
    await _box?.put('port', port);
    settingsNotifier.value = LanSettingsData(
      role: current.role,
      masterIp: current.masterIp,
      port: port,
      isServerEnabled: current.isServerEnabled,
    );

    if (current.isMaster && current.isServerEnabled) {
      await LocalPosServer.stop();
      await LocalPosServer.start(serverPort: port);
    }
  }

  static Future<void> setServerEnabled(bool enabled) async {
    await _box?.put('is_server_enabled', enabled);
    settingsNotifier.value = LanSettingsData(
      role: current.role,
      masterIp: current.masterIp,
      port: current.port,
      isServerEnabled: enabled,
    );

    if (enabled && current.isMaster) {
      await LocalPosServer.start(serverPort: current.port);
    } else {
      await LocalPosServer.stop();
    }
  }

  /// Pings master server over Wi-Fi
  static Future<bool> testMasterConnection(String ip, int port) {
    return LocalPosClient.ping(ip, port: port);
  }
}
