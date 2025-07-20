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
    bool asSingle = true,
  }) async {
    if (asSingle) {
      return [_generateSingleQRFromFile(fileInfo, encrypt: encrypt, password: password)];
    } else {
      return _generateQRsFromFileInChunks(fileInfo, encrypt: encrypt, password: password);
    }
  }

  Future<String> _generateSingleQRFromFile(
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

      Map<String, dynamic> qrData = {
        'metadata': metadata,
        'data': base64Data,
        'chunks': 1,
        'chunk': 0,
      };
      return jsonEncode(qrData);
    } catch (e) {
      throw Exception('Failed to generate single QR code: $e');
    }
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

  Future<int> getQRCodeCount(FileInfoModel fileInfo) async {
    try {
      final file = File(fileInfo.path);
      if (!await file.exists()) {
        return 0;
      }
      Uint8List fileData = await file.readAsBytes();
      String base64Data = base64Encode(fileData);
      Map<String, dynamic> metadata = {
        'name': fileInfo.name,
        'size': fileInfo.size,
        'type': fileInfo.type,
        'encrypted': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      String metadataJson = jsonEncode(metadata);
      int chunkSize = maxQRDataSize - metadataJson.length - 100;
      return (base64Data.length / chunkSize).ceil();
    } catch (e) {
      return 0;
    }
  }

  Future<String> generateQRFromText(String text) async {
    try {
      if (text.length > maxQRDataSize) {
        throw Exception('Text too large for single QR code');
      }
      return text;
    } catch (e) {
      throw Exception('Failed to generate QR from text: $e');
    }
  }

  Future<List<String>> generateQRFromLargeText(String text) async {
    try {
      List<String> qrCodes = [];
      int chunkSize = maxQRDataSize - 50; // Buffer for chunk info

      if (text.length <= chunkSize) {
        qrCodes.add(text);
      } else {
        int totalChunks = (text.length / chunkSize).ceil();
        
        for (int i = 0; i < totalChunks; i++) {
          int start = i * chunkSize;
          int end = (start + chunkSize < text.length) 
              ? start + chunkSize 
              : text.length;
          
          String chunkData = text.substring(start, end);
          String qrData = 'CHUNK:$i:$totalChunks:$chunkData';
          
          qrCodes.add(qrData);
        }
      }

      return qrCodes;
    } catch (e) {
      throw Exception('Failed to generate QR codes from large text: $e');
    }
  }

  int calculateOptimalChunkSize(int fileSize) {
    // Calculate optimal chunk size based on file size
    if (fileSize <= maxQRDataSize) {
      return fileSize;
    }
    
    int chunks = (fileSize / maxQRDataSize).ceil();
    return (fileSize / chunks).ceil();
  }

  Future<bool> validateQRData(String qrData) async {
    try {
      // Try to parse as JSON first
      Map<String, dynamic> data = jsonDecode(qrData);
      
      // Check required fields
      if (!data.containsKey('metadata') || 
          !data.containsKey('data') || 
          !data.containsKey('chunks') || 
          !data.containsKey('chunk')) {
        return false;
      }

      // Validate metadata
      Map<String, dynamic> metadata = data['metadata'];
      if (!metadata.containsKey('name') || 
          !metadata.containsKey('size') || 
          !metadata.containsKey('type')) {
        return false;
      }

      return true;
    } catch (e) {
      // If not JSON, check if it's a simple text or chunked text
      if (qrData.startsWith('CHUNK:')) {
        List<String> parts = qrData.split(':');
        return parts.length >= 4;
      }
      
      // Simple text QR
      return qrData.isNotEmpty;
    }
  }

  Map<String, dynamic>? parseQRData(String qrData) {
    try {
      return jsonDecode(qrData);
    } catch (e) {
      // Handle chunked text format
      if (qrData.startsWith('CHUNK:')) {
        List<String> parts = qrData.split(':');
        if (parts.length >= 4) {
          return {
            'chunk': int.parse(parts[1]),
            'chunks': int.parse(parts[2]),
            'data': parts.sublist(3).join(':'),
            'type': 'text',
          };
        }
      }
      return null;
    }
  }
}

