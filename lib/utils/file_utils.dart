import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileUtils {
  static Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
      return true; // iOS doesn't need explicit storage permission for app documents
    } catch (e) {
      return false;
    }
  }

  static Future<Directory> getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Try to get external storage directory
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return Directory('${externalDir.path}/QRBridge');
        }
      }
      
      // Fallback to app documents directory
      Directory appDir = await getApplicationDocumentsDirectory();
      return Directory('${appDir.path}/QRBridge');
    } catch (e) {
      // Final fallback
      Directory appDir = await getApplicationDocumentsDirectory();
      return Directory('${appDir.path}/QRBridge');
    }
  }

  static Future<String> saveFileToDownloads(
    Uint8List data, 
    String fileName
  ) async {
    try {
      Directory downloadsDir = await getDownloadsDirectory();
      
      // Create directory if it doesn't exist
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      // Generate unique filename if file already exists
      String finalFileName = fileName;
      String baseName = fileName.contains('.') 
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      String extension = fileName.contains('.') 
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '';
      
      int counter = 1;
      while (await File('${downloadsDir.path}/$finalFileName').exists()) {
        finalFileName = '${baseName}_$counter$extension';
        counter++;
      }
      
      // Save file
      File file = File('${downloadsDir.path}/$finalFileName');
      await file.writeAsBytes(data);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  static Future<String> saveTextToFile(String text, String fileName) async {
    try {
      final data = Uint8List.fromList(text.codeUnits);
      return await saveFileToDownloads(data, fileName);
    } catch (e) {
      throw Exception('Failed to save text file: $e');
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String getFileExtension(String fileName) {
    if (!fileName.contains('.')) return '';
    return fileName.split('.').last.toLowerCase();
  }

  static String getFileNameWithoutExtension(String fileName) {
    if (!fileName.contains('.')) return fileName;
    return fileName.substring(0, fileName.lastIndexOf('.'));
  }

  static bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  static bool isVideoFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'].contains(extension);
  }

  static bool isAudioFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'].contains(extension);
  }

  static bool isDocumentFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'].contains(extension);
  }

  static bool isArchiveFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(extension);
  }

  static String getMimeType(String fileName) {
    final extension = getFileExtension(fileName);
    
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      
      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'webm':
        return 'video/webm';
      
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      
      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      
      default:
        return 'application/octet-stream';
    }
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  static Future<int> getFileSize(String filePath) async {
    try {
      File file = File(filePath);
      if (await file.exists()) {
        FileStat stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<DateTime?> getFileModifiedDate(String filePath) async {
    try {
      File file = File(filePath);
      if (await file.exists()) {
        FileStat stat = await file.stat();
        return stat.modified;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<String>> listFilesInDirectory(String directoryPath) async {
    try {
      Directory directory = Directory(directoryPath);
      if (await directory.exists()) {
        List<FileSystemEntity> entities = await directory.list().toList();
        return entities
            .where((entity) => entity is File)
            .map((entity) => entity.path)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> createDirectoryIfNotExists(String directoryPath) async {
    try {
      Directory directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

