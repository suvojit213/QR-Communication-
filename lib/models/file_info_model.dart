class FileInfoModel {
  final String name;
  final String path;
  final int size;
  final String type;
  final DateTime dateCreated;
  final bool isEncrypted;
  final List<String>? qrCodes;

  FileInfoModel({
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    required this.dateCreated,
    this.isEncrypted = false,
    this.qrCodes,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get fileExtension {
    return name.split('.').last.toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'type': type,
      'dateCreated': dateCreated.toIso8601String(),
      'isEncrypted': isEncrypted,
      'qrCodes': qrCodes,
    };
  }

  factory FileInfoModel.fromJson(Map<String, dynamic> json) {
    return FileInfoModel(
      name: json['name'],
      path: json['path'],
      size: json['size'],
      type: json['type'],
      dateCreated: DateTime.parse(json['dateCreated']),
      isEncrypted: json['isEncrypted'] ?? false,
      qrCodes: json['qrCodes']?.cast<String>(),
    );
  }
}

