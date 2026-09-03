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

    /// Mengganti seluruh foto milik [clientUuid] dengan [photos] yang baru.
  ///
  /// Dipakai saat mode edit — BERBEDA dari persistAll biasa karena foto
  /// lama yang tidak diubah user pun path-nya berada di folder yang sama
  /// yang akan dihapus. Kalau langsung pakai persistAll (hapus dulu, baru
  /// salin), foto lama bisa lenyap sebelum sempat disalin ulang. Di sini,
  /// foto disalin ke folder staging DULU, baru folder lama dihapus dan
  /// staging di-rename menjadi folder final.
  Future<List<String>> replaceAll(
    String clientUuid,
    List<XFile> photos,
  ) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final baseDirectory = Directory(
      p.join(appDirectory.path, 'non_oss_photos'),
    );
    final finalDirectory = Directory(p.join(baseDirectory.path, clientUuid));
    final stagingDirectory = Directory(
      p.join(baseDirectory.path, '${clientUuid}_staging'),
    );

    if (await stagingDirectory.exists()) {
      await stagingDirectory.delete(recursive: true);
    }
    await stagingDirectory.create(recursive: true);

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
          stagingDirectory.path,
          'photo_${(index + 1).toString().padLeft(2, '0')}$safeExtension',
        ),
      );
      await source.copy(target.path);
      savedPaths.add(target.path);
    }

    if (await finalDirectory.exists()) {
      await finalDirectory.delete(recursive: true);
    }
    await stagingDirectory.rename(finalDirectory.path);

    // Path yang tercatat tadi masih menunjuk ke folder staging;
    // sesuaikan supaya menunjuk ke folder final setelah di-rename.
    return savedPaths
        .map(
          (path) => path.replaceFirst(stagingDirectory.path, finalDirectory.path),
        )
        .toList(growable: false);
  }
}
