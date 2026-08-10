import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/core/archive_decoder.dart';

void main() {
  test('decodes tar.xz archives', () async {
    final source = Archive()
      ..addFile(ArchiveFile('Mods/example.dll', 3, [1, 2, 3]));
    final tarBytes = TarEncoder().encode(source);
    final compressed = XZEncoder().encode(tarBytes);

    final decoded = await ModArchiveDecoder.decode(compressed);

    expect(decoded.archive, isNotNull);
    expect(decoded.archive!.files.single.name, 'Mods/example.dll');
    expect(decoded.archive!.files.single.content, [1, 2, 3]);
  });

  test('keeps non-archive bytes unchanged', () async {
    final bytes = [0, 1, 2, 3];

    final decoded = await ModArchiveDecoder.decode(bytes);

    expect(decoded.archive, isNull);
    expect(decoded.bytes, bytes);
  });

  test('decompresses xz-wrapped payload bytes', () async {
    final payload = [0x4d, 0x5a, 1, 2, 3];
    final compressed = XZEncoder().encode(payload);

    final decoded = await ModArchiveDecoder.decode(compressed);

    expect(decoded.archive, isNull);
    expect(decoded.bytes, payload);
    expect(decoded.wasCompressed, isTrue);
    expect(decoded.hasDllSignature, isTrue);
  });
}
