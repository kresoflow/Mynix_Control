import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

class AudioHelper {
  /// Plays a pleasant kitchen bell chime when a new order arrives
  static void playNewOrderSound() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['''
          (function() {
            try {
              var AudioCtx = window.AudioContext || window.webkitAudioContext;
              if (!AudioCtx) return;
              var ctx = new AudioCtx();
              var now = ctx.currentTime;

              var osc1 = ctx.createOscillator();
              var gain1 = ctx.createGain();
              osc1.type = 'sine';
              osc1.frequency.setValueAtTime(880, now);
              gain1.gain.setValueAtTime(0.3, now);
              gain1.gain.exponentialRampToValueAtTime(0.001, now + 1.2);
              osc1.connect(gain1);
              gain1.connect(ctx.destination);
              osc1.start(now);
              osc1.stop(now + 1.2);

              var osc2 = ctx.createOscillator();
              var gain2 = ctx.createGain();
              osc2.type = 'sine';
              osc2.frequency.setValueAtTime(1318.5, now + 0.1);
              gain2.gain.setValueAtTime(0.25, now + 0.1);
              gain2.gain.exponentialRampToValueAtTime(0.001, now + 1.5);
              osc2.connect(gain2);
              gain2.connect(ctx.destination);
              osc2.start(now + 0.1);
              osc2.stop(now + 1.5);
            } catch(e) {
              console.log('Audio error:', e);
            }
          })();
        ''']);
      } catch (e) {
        if (kDebugMode) {
          print('Audio play error: $e');
        }
      }
    }
  }
}
