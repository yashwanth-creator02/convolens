import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentStorage {
  static Future<String> copyToAppStorage(String sourcePath, int callId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final originalFile = File(sourcePath);
    final extension = p.extension(sourcePath);
    final uniqueName =
        '${callId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final destinationPath = p.join(attachmentsDir.path, uniqueName);

    await originalFile.copy(destinationPath);

    return destinationPath;
  }

  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
