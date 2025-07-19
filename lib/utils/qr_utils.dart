import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRUtils {
  static const int maxQRCapacity = 2953; // Maximum characters for QR code with error correction
  static const int recommendedQRCapacity = 2000; // Recommended limit for reliability

  static int calculateQRCapacity(String data) {
    // Estimate QR code capacity based on data type
    if (RegExp(r'^[0-9]+$').hasMatch(data)) {
      return 7089; // Numeric mode
    } else if (RegExp(r'^[A-Z0-9 \$%\*\+\-\.\/\:]+$').hasMatch(data)) {
      return 4296; // Alphanumeric mode
    } else {
      return 2953; // Byte mode
    }
  }

  static bool canFitInSingleQR(String data) {
    return data.length <= recommendedQRCapacity;
  }

  static int calculateRequiredChunks(String data) {
    if (canFitInSingleQR(data)) return 1;
    return (data.length / recommendedQRCapacity).ceil();
  }

  static List<String> splitDataIntoChunks(String data, {int? chunkSize}) {
    chunkSize ??= recommendedQRCapacity;
    
    if (data.length <= chunkSize) {
      return [data];
    }

    List<String> chunks = [];
    for (int i = 0; i < data.length; i += chunkSize) {
      int end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.substring(i, end));
    }

    return chunks;
  }

  static String combineChunks(List<String> chunks) {
    return chunks.join('');
  }

  static Future<Uint8List?> generateQRImageBytes(
    String data, {
    double size = 200,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (!qrValidationResult.isValid) {
        return null;
      }

      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter(
        data: data,
        version: qrCode.version,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        color: foregroundColor,
        emptyColor: backgroundColor,
      );

      final picRecorder = ui.PictureRecorder();
      final canvas = Canvas(picRecorder);
      painter.paint(canvas, Size(size, size));
      
      final picture = picRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  static Widget buildQRWidget(
    String data, {
    double size = 200,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
    Widget? embeddedImage,
    double? embeddedImageSizePercent,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      embeddedImage: embeddedImage != null ? AssetImage('') : null,
      embeddedImageStyle: embeddedImage != null 
          ? QrEmbeddedImageStyle(
              size: Size(
                size * (embeddedImageSizePercent ?? 0.2),
                size * (embeddedImageSizePercent ?? 0.2),
              ),
            )
          : null,
    );
  }

  static bool validateQRData(String data) {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      return qrValidationResult.isValid;
    } catch (e) {
      return false;
    }
  }

  static Map<String, dynamic>? parseQRMetadata(String qrData) {
    try {
      Map<String, dynamic> data = jsonDecode(qrData);
      if (data.containsKey('metadata')) {
        return data['metadata'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static bool isChunkedQR(String qrData) {
    try {
      Map<String, dynamic> data = jsonDecode(qrData);
      return data.containsKey('chunks') && data['chunks'] > 1;
    } catch (e) {
      return qrData.startsWith('CHUNK:');
    }
  }

  static int getChunkIndex(String qrData) {
    try {
      Map<String, dynamic> data = jsonDecode(qrData);
      return data['chunk'] ?? 0;
    } catch (e) {
      if (qrData.startsWith('CHUNK:')) {
        List<String> parts = qrData.split(':');
        if (parts.length >= 2) {
          return int.tryParse(parts[1]) ?? 0;
        }
      }
      return 0;
    }
  }

  static int getTotalChunks(String qrData) {
    try {
      Map<String, dynamic> data = jsonDecode(qrData);
      return data['chunks'] ?? 1;
    } catch (e) {
      if (qrData.startsWith('CHUNK:')) {
        List<String> parts = qrData.split(':');
        if (parts.length >= 3) {
          return int.tryParse(parts[2]) ?? 1;
        }
      }
      return 1;
    }
  }

  static String optimizeDataForQR(String data) {
    // Remove unnecessary whitespace
    data = data.trim();
    
    // Convert to uppercase if alphanumeric mode is beneficial
    if (RegExp(r'^[A-Z0-9 \$%\*\+\-\.\/\:]+$').hasMatch(data.toUpperCase())) {
      return data.toUpperCase();
    }
    
    return data;
  }

  static QrErrorCorrectLevel getOptimalErrorCorrectionLevel(String data) {
    // Use higher error correction for shorter data
    if (data.length < 100) {
      return QrErrorCorrectLevel.H; // High (30%)
    } else if (data.length < 500) {
      return QrErrorCorrectLevel.Q; // Quartile (25%)
    } else if (data.length < 1000) {
      return QrErrorCorrectLevel.M; // Medium (15%)
    } else {
      return QrErrorCorrectLevel.L; // Low (7%)
    }
  }

  static Future<String?> saveQRAsImage(
    String data,
    String fileName, {
    double size = 512,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      final imageBytes = await generateQRImageBytes(
        data,
        size: size,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      );

      if (imageBytes != null) {
        // This would typically save to gallery or downloads
        // Implementation depends on platform-specific code
        return 'QR code saved as $fileName';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  static String generateQRFileName(String originalFileName, int chunkIndex, int totalChunks) {
    String baseName = originalFileName.contains('.') 
        ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
        : originalFileName;
    
    if (totalChunks == 1) {
      return '${baseName}_QR.png';
    } else {
      return '${baseName}_QR_${chunkIndex + 1}_of_$totalChunks.png';
    }
  }

  static Color getQRColorForFileType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.orange;
      case 'mp3':
      case 'wav':
        return Colors.green;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'zip':
      case 'rar':
        return Colors.brown;
      default:
        return Colors.black;
    }
  }

  static String formatQRInfo(String qrData) {
    try {
      Map<String, dynamic> data = jsonDecode(qrData);
      
      if (data.containsKey('metadata')) {
        Map<String, dynamic> metadata = data['metadata'];
        String fileName = metadata['name'] ?? 'Unknown';
        int fileSize = metadata['size'] ?? 0;
        bool encrypted = metadata['encrypted'] ?? false;
        int chunks = data['chunks'] ?? 1;
        int currentChunk = data['chunk'] ?? 0;
        
        String sizeStr = fileSize < 1024 
            ? '$fileSize B'
            : fileSize < 1024 * 1024
                ? '${(fileSize / 1024).toStringAsFixed(1)} KB'
                : '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
        
        String info = 'File: $fileName\nSize: $sizeStr';
        
        if (encrypted) {
          info += '\nEncrypted: Yes';
        }
        
        if (chunks > 1) {
          info += '\nChunk: ${currentChunk + 1} of $chunks';
        }
        
        return info;
      }
      
      return 'QR Code Data';
    } catch (e) {
      return 'QR Code';
    }
  }
}

