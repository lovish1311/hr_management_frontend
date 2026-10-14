import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<String?> downloadFileBytes(Uint8List bytes, String fileName, {String mimeType = 'text/csv'}) async {
  // 1. On Android / iOS, try native FilePicker save dialog (uses Storage Access Framework / MediaStore)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report to Device',
        fileName: fileName,
        bytes: bytes,
        type: FileType.any,
      );
      if (savedPath != null) {
        return savedPath;
      }
    } catch (_) {
      // Fall through to candidate direct paths if file_picker save throws or is cancelled
    }
  }

  // 2. Direct File System write (Desktop or fallback)
  try {
    final candidateDirs = <Directory>[];

    if (Platform.isAndroid) {
      candidateDirs.addAll([
        Directory('/storage/emulated/0/Download'),
        Directory('/sdcard/Download'),
        Directory('/storage/emulated/0/Documents'),
      ]);
    } else {
      final homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (homeDir != null) {
        candidateDirs.add(Directory('$homeDir${Platform.pathSeparator}Downloads'));
        candidateDirs.add(Directory('$homeDir${Platform.pathSeparator}Documents'));
      }
    }

    for (final dir in candidateDirs) {
      try {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final targetPath = '${dir.path}${Platform.pathSeparator}$fileName';
        final file = File(targetPath);
        file.writeAsBytesSync(bytes, flush: true);
        return targetPath;
      } catch (_) {
        continue;
      }
    }

    // Last resort fallback
    final fallbackFile = File(fileName);
    fallbackFile.writeAsBytesSync(bytes, flush: true);
    return fallbackFile.absolute.path;
  } catch (e) {
    return null;
  }
}
