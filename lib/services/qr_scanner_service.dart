import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/file_info_model.dart';
import 'file_encryption_service.dart';

class QRScannerService {
  final FileEncryptionService _encryptionService = FileEncryptionService();

  Future<String?> reconstructFileFromQR(
    List<String> qrCodes, {
    bool decrypt = false,
    String? password,
  }) async {
    try {
      if (qrCodes.isEmpty) {
        throw Exception('No QR codes provided');
      }

      // Parse first QR code to get metadata
      Map<String, dynamic>? firstQRData = _parseQRData(qrCodes[0]);
      if (firstQRData == null) {
        throw Exception('Invalid QR code format');
      }

      // Check if it's a file or text QR
      if (firstQRData.containsKey('metadata')) {
        return await _reconstructFileFromFileQR(qrCodes, decrypt: decrypt, password: password);
      } else {
        return await _reconstructTextFromQR(qrCodes);
      }
    } catch (e) {
      throw Exception('Failed to reconstruct file: $e');
    }
  }

  Future<String?> _reconstructFileFromFileQR(
    List<String> qrCodes, {
    bool decrypt = false,
    String? password,
  }) async {
    try {
      // Parse and sort QR codes by chunk index
      List<Map<String, dynamic>> chunks = [];
      Map<String, dynamic>? metadata;

      for (String qrCode in qrCodes) {
        Map<String, dynamic>? qrData = _parseQRData(qrCode);
        if (qrData != null) {
          chunks.add(qrData);
          metadata ??= qrData['metadata'];
        }
      }

      if (chunks.isEmpty || metadata == null) {
        throw Exception('No valid chunks found');
      }

      // Sort chunks by index
      chunks.sort((a, b) => a['chunk'].compareTo(b['chunk']));

      // Verify we have all chunks
      int expectedChunks = chunks[0]['chunks'];
      if (chunks.length != expectedChunks) {
        throw Exception('Missing chunks: expected $expectedChunks, got ${chunks.length}');
      }

      // Reconstruct base64 data
      StringBuffer base64Buffer = StringBuffer();
      for (var chunk in chunks) {
        base64Buffer.write(chunk['data']);
      }

      // Decode base64 to bytes
      Uint8List fileData = base64Decode(base64Buffer.toString());

      // Decrypt if required
      if (decrypt && password != null && password.isNotEmpty) {
        fileData = await _encryptionService.decryptData(fileData, password);
      }

      // Save file to downloads directory
      Directory downloadsDir = await getApplicationDocumentsDirectory();
      String fileName = metadata['name'];
      String filePath = '${downloadsDir.path}/QRBridge_Downloads/$fileName';

      // Create directory if it doesn't exist
      Directory(filePath).parent.createSync(recursive: true);

      // Write file
      File outputFile = File(filePath);
      await outputFile.writeAsBytes(fileData);

      return filePath;
    } catch (e) {
      throw Exception('Failed to reconstruct file from QR: $e');
    }
  }

  Future<String?> _reconstructTextFromQR(List<String> qrCodes) async {
    try {
      if (qrCodes.length == 1) {
        // Single QR code with text
        String qrData = qrCodes[0];
        if (qrData.startsWith('CHUNK:')) {
          // Single chunk text
          List<String> parts = qrData.split(':');
          return parts.sublist(3).join(':');
        } else {
          // Simple text
          return qrData;
        }
      } else {
        // Multiple chunks
        List<Map<String, dynamic>> chunks = [];
        
        for (String qrCode in qrCodes) {
          if (qrCode.startsWith('CHUNK:')) {
            List<String> parts = qrCode.split(':');
            if (parts.length >= 4) {
              chunks.add({
                'chunk': int.parse(parts[1]),
                'chunks': int.parse(parts[2]),
                'data': parts.sublist(3).join(':'),
              });
            }
          }
        }

        // Sort chunks by index
        chunks.sort((a, b) => a['chunk'].compareTo(b['chunk']));

        // Reconstruct text
        StringBuffer textBuffer = StringBuffer();
        for (var chunk in chunks) {
          textBuffer.write(chunk['data']);
        }

        // Save as text file
        Directory downloadsDir = await getApplicationDocumentsDirectory();
        String fileName = 'QRBridge_Text_${DateTime.now().millisecondsSinceEpoch}.txt';
        String filePath = '${downloadsDir.path}/QRBridge_Downloads/$fileName';

        // Create directory if it doesn't exist
        Directory(filePath).parent.createSync(recursive: true);

        // Write file
        File outputFile = File(filePath);
        await outputFile.writeAsString(textBuffer.toString());

        return filePath;
      }
    } catch (e) {
      throw Exception('Failed to reconstruct text from QR: $e');
    }
  }

  Map<String, dynamic>? _parseQRData(String qrData) {
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

  Future<FileInfoModel?> getFileInfo(String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      FileStat stat = await file.stat();
      String fileName = file.path.split('/').last;
      String fileExtension = fileName.contains('.') 
          ? fileName.split('.').last 
          : 'unknown';

      return FileInfoModel(
        name: fileName,
        path: filePath,
        size: stat.size,
        type: fileExtension,
        dateCreated: stat.modified,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> validateQRSequence(List<String> qrCodes) async {
    try {
      if (qrCodes.isEmpty) return false;

      // Check if all QR codes are valid
      for (String qrCode in qrCodes) {
        Map<String, dynamic>? qrData = _parseQRData(qrCode);
        if (qrData == null) return false;
      }

      // If file QR codes, check chunk sequence
      Map<String, dynamic>? firstQR = _parseQRData(qrCodes[0]);
      if (firstQR != null && firstQR.containsKey('chunks')) {
        int expectedChunks = firstQR['chunks'];
        if (qrCodes.length != expectedChunks) return false;

        // Check all chunk indices are present
        Set<int> chunkIndices = {};
        for (String qrCode in qrCodes) {
          Map<String, dynamic>? qrData = _parseQRData(qrCode);
          if (qrData != null && qrData.containsKey('chunk')) {
            chunkIndices.add(qrData['chunk']);
          }
        }

        // Should have indices 0 to expectedChunks-1
        for (int i = 0; i < expectedChunks; i++) {
          if (!chunkIndices.contains(i)) return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getQRMetadata(String qrCode) async {
    try {
      Map<String, dynamic>? qrData = _parseQRData(qrCode);
      if (qrData != null && qrData.containsKey('metadata')) {
        return qrData['metadata'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> getExpectedChunkCount(String qrCode) async {
    try {
      Map<String, dynamic>? qrData = _parseQRData(qrCode);
      if (qrData != null && qrData.containsKey('chunks')) {
        return qrData['chunks'];
      }
      return 1; // Single QR code
    } catch (e) {
      return 1;
    }
  }
}

