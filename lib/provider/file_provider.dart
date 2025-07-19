import 'package:flutter/foundation.dart';
import '../models/file_info_model.dart';

class FileProvider extends ChangeNotifier {
  List<FileInfoModel> _fileHistory = [];
  bool _isDarkMode = false;
  bool _isEncryptionEnabled = false;
  String _encryptionPassword = '';

  List<FileInfoModel> get fileHistory => _fileHistory;
  bool get isDarkMode => _isDarkMode;
  bool get isEncryptionEnabled => _isEncryptionEnabled;
  String get encryptionPassword => _encryptionPassword;

  void addFileToHistory(FileInfoModel file) {
    _fileHistory.insert(0, file);
    if (_fileHistory.length > 50) {
      _fileHistory = _fileHistory.take(50).toList();
    }
    notifyListeners();
  }

  void removeFileFromHistory(FileInfoModel file) {
    _fileHistory.remove(file);
    notifyListeners();
  }

  void clearHistory() {
    _fileHistory.clear();
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleEncryption() {
    _isEncryptionEnabled = !_isEncryptionEnabled;
    notifyListeners();
  }

  void setEncryptionPassword(String password) {
    _encryptionPassword = password;
    notifyListeners();
  }

  List<FileInfoModel> getRecentFiles({int limit = 10}) {
    return _fileHistory.take(limit).toList();
  }

  List<FileInfoModel> getFilesByType(String type) {
    return _fileHistory.where((file) => file.type == type).toList();
  }
}

