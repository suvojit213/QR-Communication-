import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image/image.dart' as img;
import '../provider/file_provider.dart';
import '../services/qr_generator_service.dart';
import '../models/file_info_model.dart';

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  FileInfoModel? _selectedFile;
  bool _isGenerating = false;
  String _generationStatus = '';
  final QRGeneratorService _qrService = QRGeneratorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generate QR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedFile == null) ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.upload_file,
                            size: 80,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Select a file to generate QR code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Choose any file from your device',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Pick File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _buildFileInfo(),
                  const SizedBox(height: 20),
                  if (!_isGenerating)
                    _buildGenerateButton()
                  else
                    _buildLoadingWidget(),
                  const SizedBox(height: 20),
                  Text(_generationStatus),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(_selectedFile!.type),
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_selectedFile!.formattedSize} • ${_selectedFile!.fileExtension}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                    _generationStatus = '';
                  });
                },
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Consumer<FileProvider>(
            builder: (context, fileProvider, child) {
              return Column(
                children: [
                  if (fileProvider.isEncryptionEnabled) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'File will be encrypted before generating QR code',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton.icon(
                    onPressed: _generateAndZipQRCodes,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Generate QR ZIP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 40),
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Generating and zipping QR codes...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        PlatformFile file = result.files.first;
        
        setState(() {
          _selectedFile = FileInfoModel(
            name: file.name,
            path: file.path ?? '',
            size: file.size,
            type: file.extension ?? 'unknown',
            dateCreated: DateTime.now(),
          );
          _generationStatus = '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _generateAndZipQRCodes() async {
    if (_selectedFile == null) return;

    setState(() {
      _isGenerating = true;
      _generationStatus = '';
    });

    try {
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      
      List<String> qrData = await _qrService.generateQRFromFile(
        _selectedFile!,
        encrypt: fileProvider.isEncryptionEnabled,
        password: fileProvider.encryptionPassword,
        asSingle: false, // Always generate multiple QR codes
      );

      final downloadsDir = await getDownloadsDirectory();
      final zipFilePath = '${downloadsDir!.path}/${_selectedFile!.name}.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);

      for (int i = 0; i < qrData.length; i++) {
        final qrImage = await QrPainter(
          data: qrData[i],
          version: QrVersions.auto,
          gapless: false,
        ).toImageData(200);

        final imageBytes = qrImage!.buffer.asUint8List();
        final image = img.decodeImage(imageBytes);
        encoder.addFile(ArchiveFile('qr_code_$i.png', image!.lengthInBytes, img.encodePng(image)));
      }

      encoder.close();

      setState(() {
        _isGenerating = false;
        _generationStatus = 'QR codes zipped and saved to: $zipFilePath';
      });

      // Add to history
      final updatedFile = FileInfoModel(
        name: _selectedFile!.name,
        path: _selectedFile!.path,
        size: _selectedFile!.size,
        type: _selectedFile!.type,
        dateCreated: _selectedFile!.dateCreated,
        isEncrypted: fileProvider.isEncryptionEnabled,
      );
      
      fileProvider.addFileToHistory(updatedFile);

    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generationStatus = 'Error: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating QR codes: $e')),
      );
    }
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }
}

