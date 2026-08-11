import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PermanentPhotoStorage {
  Future<List<String>> persistAll(String clientUuid, List<XFile> photos) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final targetDirectory = Directory(
      p.join(appDirectory.path, 'non_oss_photos', clientUuid),
    );
    await targetDirectory.create(recursive: true);

    final savedPaths = <String>[];
    for (var index = 0; index < photos.length; index++) {
      final source = File(photos[index].path);
      if (!await source.exists()) {
        throw FileSystemException('Foto sumber tidak ditemukan', source.path);
      }

      final extension = p.extension(source.path).toLowerCase();
      final safeExtension = extension.isEmpty ? '.jpg' : extension;
      final target = File(
        p.join(
          targetDirectory.path,
          'photo_${(index + 1).toString().padLeft(2, '0')}$safeExtension',
        ),
      );
      await source.copy(target.path);
      savedPaths.add(target.path);
    }
    return savedPaths;
  }

  Future<void> removeFor(String clientUuid) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(appDirectory.path, 'non_oss_photos', clientUuid),
    );
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
