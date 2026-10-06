import 'dart:io';
import 'dart:typed_data';

void downloadFileBytes(Uint8List bytes, String fileName, {String mimeType = 'text/csv'}) {
  try {
    String? homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    String targetPath;
    if (homeDir != null) {
      final downloadsDir = Directory('$homeDir${Platform.pathSeparator}Downloads');
      if (downloadsDir.existsSync()) {
        targetPath = '${downloadsDir.path}${Platform.pathSeparator}$fileName';
      } else {
        targetPath = fileName;
      }
    } else {
      targetPath = fileName;
    }

    final file = File(targetPath);
    file.writeAsBytesSync(bytes, flush: true);
  } catch (_) {
    // Fallback if desktop file writing encounters sandbox/permission limits
  }
}
