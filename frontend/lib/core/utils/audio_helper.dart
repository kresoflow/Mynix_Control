import 'package:flutter/foundation.dart';
import 'audio_helper_stub.dart'
    if (dart.library.js) 'audio_helper_web.dart';

class AudioHelper {
  /// Plays a pleasant kitchen bell chime when a new order arrives
  static void playNewOrderSound() {
    if (kIsWeb) {
      try {
        playWebAudio();
      } catch (e) {
        if (kDebugMode) {
          print('Audio play error: $e');
        }
      }
    }
  }
}
