import 'dart:typed_data';
import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

class FileDownloader {
  static void downloadBytes({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'text/csv',
  }) {
    downloadFileBytes(bytes, fileName, mimeType: mimeType);
  }
}
