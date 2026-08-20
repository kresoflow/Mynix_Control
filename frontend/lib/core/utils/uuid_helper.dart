import 'dart:math';

class UuidHelper {
  static final Random _random = Random.secure();

  /// Generates an RFC 4122 compliant version 4 UUID (e.g. 7a2c9b4e-8f1d-4d2a-9e1b-4f8e7a6b5c4d)
  static String generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version to 4 (bits 12-15 of time_hi_and_version to 0100)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122 (bits 6-7 of clock_seq_hi_and_reserved to 10)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');

    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10, 16).map(hex).join()}';
  }
}
