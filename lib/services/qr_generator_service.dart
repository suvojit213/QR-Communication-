
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../models/file_info_model.dart';
import 'file_encryption_service.dart';

class QRGeneratorService {
  static const int maxQRDataSize = 2000; // Maximum bytes per QR code
  final FileEncryptionService _encryptionService = FileEncryptionService();

  Future<List<String>> generateQRFromFile(
    FileInfoModel fileInfo, {
    bool encrypt = false,
    String? password,
    bool asSingle = false,
  }) async {
    return _generateQRsFromFileInChunks(fileInfo, encrypt: encrypt, password: password);
  }

  Future<List<String>> _generateQRsFromFileInChunks(
    FileInfoModel fileInfo, {
    bool encrypt = false,
    String? password,
  }) async {
    try {
      // Read file data
      final file = File(fileInfo.path);
      if (!await file.exists()) {
        throw Exception('File not found: ${fileInfo.path}');
      }

      Uint8List fileData = await file.readAsBytes();

      // Encrypt if required
      if (encrypt && password != null && password.isNotEmpty) {
        fileData = await _encryptionService.encryptData(fileData, password);
      }

      // Convert to base64
      String base64Data = base64Encode(fileData);

      // Create file metadata
      Map<String, dynamic> metadata = {
        'name': fileInfo.name,
        'size': fileInfo.size,
        'type': fileInfo.type,
        'encrypted': encrypt,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      String metadataJson = jsonEncode(metadata);

      // Calculate chunk size (reserve space for metadata and chunk info)
      int chunkSize = maxQRDataSize - metadataJson.length - 100; // Buffer for chunk info

      List<String> qrCodes = [];
      int totalChunks = (base64Data.length / chunkSize).ceil();

      for (int i = 0; i < totalChunks; i++) {
        int start = i * chunkSize;
        int end = (start + chunkSize < base64Data.length)
            ? start + chunkSize
            : base64Data.length;

        String chunkData = base64Data.substring(start, end);

        Map<String, dynamic> qrData = {
          'metadata': metadata,
          'data': chunkData,
          'chunks': totalChunks,
          'chunk': i,
        };

        qrCodes.add(jsonEncode(qrData));
      }

      return qrCodes;
    } catch (e) {
      throw Exception('Failed to generate QR codes in chunks: $e');
    }
  }
}


