import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/core/adofai_game.dart';
import 'package:path/path.dart' as p;

void main() {
  test('ignores UMM detection when UMMBridge is installed', () async {
    final tempDir = await Directory.systemTemp.createTemp('umm_detection');
    addTearDown(() => tempDir.delete(recursive: true));

    await Directory(p.join(tempDir.path, 'UnityModManager')).create();
    await File(
      p.join(tempDir.path, 'Plugins', 'ummbridge.dll'),
    ).create(recursive: true);

    expect(AdofaiGame().isUmmDetected(tempDir.path), isFalse);
  });
}
