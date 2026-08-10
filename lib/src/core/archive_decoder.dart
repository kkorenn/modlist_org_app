import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:zstandard/zstandard.dart';

class DecodedArchive {
  final Archive? archive;
  final List<int> bytes;
  final bool wasCompressed;

  const DecodedArchive({
    required this.archive,
    required this.bytes,
    this.wasCompressed = false,
  });

  bool get hasDllSignature =>
      bytes.length >= 2 && bytes[0] == 0x4d && bytes[1] == 0x5a;
}

class ModArchiveDecoder {
  static Future<DecodedArchive> decode(List<int> input) async {
    return _decode(input, 0);
  }

  static Future<DecodedArchive> _decode(List<int> input, int depth) async {
    final archive = _tryDecodeArchive(input);
    if (archive != null && archive.isNotEmpty) {
      return DecodedArchive(archive: archive, bytes: input);
    }

    if (depth >= 3) {
      return DecodedArchive(archive: null, bytes: input);
    }

    if (_isXz(input)) {
      try {
        final decoded = await _decode(
          XZDecoder().decodeBytes(input),
          depth + 1,
        );
        return DecodedArchive(
          archive: decoded.archive,
          bytes: decoded.bytes,
          wasCompressed: true,
        );
      } catch (_) {
        return DecodedArchive(archive: null, bytes: input);
      }
    }

    if (_isZstd(input)) {
      try {
        final decompressed = await Zstandard().decompress(
          Uint8List.fromList(input),
        );
        if (decompressed != null && decompressed.isNotEmpty) {
          final decoded = await _decode(decompressed, depth + 1);
          return DecodedArchive(
            archive: decoded.archive,
            bytes: decoded.bytes,
            wasCompressed: true,
          );
        }
      } catch (_) {}
    }

    return DecodedArchive(archive: null, bytes: input);
  }

  static Archive? _tryDecodeArchive(List<int> input) {
    try {
      final archive = ZipDecoder().decodeBytes(input);
      if (archive.isNotEmpty) return archive;
    } catch (_) {}

    if (_isTar(input)) {
      try {
        return TarDecoder().decodeBytes(input);
      } catch (_) {}
    }

    return null;
  }

  static bool _isTar(List<int> bytes) {
    if (bytes.length < 262) return false;
    return bytes[257] == 0x75 &&
        bytes[258] == 0x73 &&
        bytes[259] == 0x74 &&
        bytes[260] == 0x61 &&
        bytes[261] == 0x72;
  }

  static bool _isXz(List<int> bytes) {
    const signature = [0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00];
    return bytes.length >= signature.length && _startsWith(bytes, signature);
  }

  static bool _isZstd(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x28 &&
        bytes[1] == 0xb5 &&
        bytes[2] == 0x2f &&
        bytes[3] == 0xfd;
  }

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
}
