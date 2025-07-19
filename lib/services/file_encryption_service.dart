import 'dart:typed_data';
import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class FileEncryptionService {
  static const String _keyPrefix = 'QRBridge_';

  Future<Uint8List> encryptData(Uint8List data, String password) async {
    try {
      // Create key from password
      final key = _generateKeyFromPassword(password);
      final encrypter = Encrypter(AES(key));
      
      // Generate random IV
      final iv = IV.fromSecureRandom(16);
      
      // Encrypt data
      final encrypted = encrypter.encryptBytes(data, iv: iv);
      
      // Combine IV and encrypted data
      final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
      result.setRange(0, iv.bytes.length, iv.bytes);
      result.setRange(iv.bytes.length, result.length, encrypted.bytes);
      
      return result;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  Future<Uint8List> decryptData(Uint8List encryptedData, String password) async {
    try {
      if (encryptedData.length < 16) {
        throw Exception('Invalid encrypted data: too short');
      }
      
      // Extract IV and encrypted data
      final iv = IV(encryptedData.sublist(0, 16));
      final encrypted = Encrypted(encryptedData.sublist(16));
      
      // Create key from password
      final key = _generateKeyFromPassword(password);
      final encrypter = Encrypter(AES(key));
      
      // Decrypt data
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  Key _generateKeyFromPassword(String password) {
    // Create a consistent key from password
    final passwordWithPrefix = _keyPrefix + password;
    final bytes = utf8.encode(passwordWithPrefix);
    
    // Pad or truncate to 32 bytes for AES-256
    final keyBytes = Uint8List(32);
    if (bytes.length >= 32) {
      keyBytes.setRange(0, 32, bytes);
    } else {
      keyBytes.setRange(0, bytes.length, bytes);
      // Fill remaining with repeated pattern
      for (int i = bytes.length; i < 32; i++) {
        keyBytes[i] = bytes[i % bytes.length];
      }
    }
    
    return Key(keyBytes);
  }

  Future<String> encryptText(String text, String password) async {
    try {
      final data = utf8.encode(text);
      final encryptedData = await encryptData(Uint8List.fromList(data), password);
      return base64Encode(encryptedData);
    } catch (e) {
      throw Exception('Text encryption failed: $e');
    }
  }

  Future<String> decryptText(String encryptedText, String password) async {
    try {
      final encryptedData = base64Decode(encryptedText);
      final decryptedData = await decryptData(encryptedData, password);
      return utf8.decode(decryptedData);
    } catch (e) {
      throw Exception('Text decryption failed: $e');
    }
  }

  bool validatePassword(String password) {
    // Basic password validation
    if (password.isEmpty) return false;
    if (password.length < 4) return false;
    return true;
  }

  String generateRandomPassword({int length = 12}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = IV.fromSecureRandom(length);
    return String.fromCharCodes(
      random.bytes.map((byte) => chars.codeUnitAt(byte % chars.length))
    );
  }

  Future<Map<String, dynamic>> encryptFileMetadata(
    Map<String, dynamic> metadata, 
    String password
  ) async {
    try {
      final jsonString = jsonEncode(metadata);
      final encryptedString = await encryptText(jsonString, password);
      
      return {
        'encrypted': true,
        'data': encryptedString,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      throw Exception('Metadata encryption failed: $e');
    }
  }

  Future<Map<String, dynamic>> decryptFileMetadata(
    Map<String, dynamic> encryptedMetadata, 
    String password
  ) async {
    try {
      if (!encryptedMetadata.containsKey('encrypted') || 
          !encryptedMetadata['encrypted']) {
        return encryptedMetadata; // Not encrypted
      }
      
      final encryptedString = encryptedMetadata['data'];
      final decryptedString = await decryptText(encryptedString, password);
      
      return jsonDecode(decryptedString);
    } catch (e) {
      throw Exception('Metadata decryption failed: $e');
    }
  }
}

