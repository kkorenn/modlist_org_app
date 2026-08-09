import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:modlist_org_app/src/core/adofai_game.dart';

void main() {
  test('replaces game name placeholder with native Linux executable name', () {
    final game = AdofaiGame();
    final expectedGameName = Platform.isLinux
        ? 'ADanceOfFireAndIce'
        : game.getModArchiveGameName(Directory.systemTemp.path);

    expect(
      game.resolveModArchivePath(
        '__gamename___Data/Managed/Mod.dll',
        Directory.systemTemp.path,
      ),
      '${expectedGameName}_Data/Managed/Mod.dll',
    );
  });

  test('uses Windows executable name for Proton game files on Linux', () async {
    final tempDir = await Directory.systemTemp.createTemp('mod_archive_path');
    addTearDown(() => tempDir.delete(recursive: true));
    await File(p.join(tempDir.path, 'A Dance of Fire and Ice.exe')).create();
    final game = AdofaiGame();
    final expectedGameName = Platform.isLinux
        ? 'A Dance of Fire and Ice'
        : game.getModArchiveGameName(tempDir.path);

    expect(
      game.resolveModArchivePath(
        '__gamename___Data/Managed/Mod.dll',
        tempDir.path,
      ),
      '${expectedGameName}_Data/Managed/Mod.dll',
    );
  });
}
