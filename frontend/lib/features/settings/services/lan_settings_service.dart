import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mynix_frontend/features/pos/services/lan/local_pos_client.dart';
import 'package:mynix_frontend/features/pos/services/lan/local_pos_server.dart';

class LanSettingsData {
  final bool isLanEnabled;
  final bool isOfflineStorageEnabled;
  final String role; // 'standalone', 'master', 'client'
  final String masterIp;
  final int port;
  final bool isServerEnabled;

  const LanSettingsData({
    this.isLanEnabled = true,
    this.isOfflineStorageEnabled = true,
    required this.role,
    required this.masterIp,
    required this.port,
    required this.isServerEnabled,
  });

  bool get isMaster => isLanEnabled && role == 'master';
  bool get isClient => isLanEnabled && role == 'client';
  bool get isStandalone => !isLanEnabled || role == 'standalone';
}

class LanSettingsService {
  static const String boxName = 'lan_settings';
  static Box? _box;

  static final ValueNotifier<LanSettingsData> settingsNotifier =
      ValueNotifier<LanSettingsData>(
    const LanSettingsData(
      isLanEnabled: true,
      isOfflineStorageEnabled: true,
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

    final isLanEnabled = _box!.get('is_lan_enabled', defaultValue: true) as bool;
    final isOfflineStorageEnabled = _box!.get('is_offline_storage_enabled', defaultValue: true) as bool;
    final role = _box!.get('role', defaultValue: defaultRole) as String;
    final masterIp = _box!.get('master_ip', defaultValue: '192.168.1.10') as String;
    final port = (_box!.get('port', defaultValue: 8080) as num).toInt();
    final isServerEnabled = _box!.get('is_server_enabled', defaultValue: true) as bool;

    settingsNotifier.value = LanSettingsData(
      isLanEnabled: isLanEnabled,
      isOfflineStorageEnabled: isOfflineStorageEnabled,
      role: role,
      masterIp: masterIp,
      port: port,
      isServerEnabled: isServerEnabled,
    );

    // If configured as master and LAN is enabled, start local server automatically
    if (isLanEnabled && role == 'master' && isServerEnabled) {
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

  static Future<void> setLanEnabled(bool enabled) async {
    await _box?.put('is_lan_enabled', enabled);
    settingsNotifier.value = LanSettingsData(
      isLanEnabled: enabled,
      isOfflineStorageEnabled: current.isOfflineStorageEnabled,
      role: current.role,
      masterIp: current.masterIp,
      port: current.port,
      isServerEnabled: current.isServerEnabled,
    );

    if (enabled && current.role == 'master' && current.isServerEnabled) {
      await LocalPosServer.start(serverPort: current.port);
    } else {
      await LocalPosServer.stop();
    }
  }

  static Future<void> setOfflineStorageEnabled(bool enabled) async {
    await _box?.put('is_offline_storage_enabled', enabled);
    settingsNotifier.value = LanSettingsData(
      isLanEnabled: current.isLanEnabled,
      isOfflineStorageEnabled: enabled,
      role: current.role,
      masterIp: current.masterIp,
      port: current.port,
      isServerEnabled: current.isServerEnabled,
    );
  }

  static Future<void> setRole(String role) async {
    await _box?.put('role', role);
    settingsNotifier.value = LanSettingsData(
      isLanEnabled: current.isLanEnabled,
      isOfflineStorageEnabled: current.isOfflineStorageEnabled,
      role: role,
      masterIp: current.masterIp,
      port: current.port,
      isServerEnabled: current.isServerEnabled,
    );

    if (current.isLanEnabled && role == 'master' && current.isServerEnabled) {
      await LocalPosServer.start(serverPort: current.port);
    } else {
      await LocalPosServer.stop();
    }
  }

  static Future<void> setMasterIp(String ip) async {
    await _box?.put('master_ip', ip.trim());
    settingsNotifier.value = LanSettingsData(
      isLanEnabled: current.isLanEnabled,
      isOfflineStorageEnabled: current.isOfflineStorageEnabled,
      role: current.role,
      masterIp: ip.trim(),
      port: current.port,
      isServerEnabled: current.isServerEnabled,
    );
  }

  static Future<void> setPort(int port) async {
    await _box?.put('port', port);
    settingsNotifier.value = LanSettingsData(
      isLanEnabled: current.isLanEnabled,
      isOfflineStorageEnabled: current.isOfflineStorageEnabled,
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
      isLanEnabled: current.isLanEnabled,
      isOfflineStorageEnabled: current.isOfflineStorageEnabled,
      role: current.role,
      masterIp: current.masterIp,
      port: current.port,
      isServerEnabled: enabled,
    );

    if (current.isLanEnabled && enabled && current.isMaster) {
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
