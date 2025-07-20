import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../provider/file_provider.dart';
import '../services/qr_generator_service.dart';
import '../widgets/qr_carousel.dart';
import '../models/file_info_model.dart';

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  FileInfoModel? _selectedFile;
  List<String> _generatedQRCodes = [];
  bool _isGenerating = false;
  bool _generateSingleQR = true;
  int _qrCodeCount = 1;
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
                  _buildQRGenerationOptions(),
                  const SizedBox(height: 20),
                  if (_generatedQRCodes.isEmpty && !_isGenerating)
                    _buildGenerateButton()
                  else if (_isGenerating)
                    _buildLoadingWidget()
                  else
                    Expanded(child: QRCarousel(qrCodes: _generatedQRCodes)),
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
                    _generatedQRCodes.clear();
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

  Widget _buildQRGenerationOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'QR Code Generation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Generate Single QR Code'),
              Switch(
                value: _generateSingleQR,
                onChanged: (value) {
                  setState(() {
                    _generateSingleQR = value;
                    _updateQRCodeCount();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _generateSingleQR
                ? 'A single QR code will be generated for the entire file.'
                : 'Multiple QR codes will be generated. Total: $_qrCodeCount',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
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
                    onPressed: _generateQRCode,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Generate QR Code'),
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
            'Generating QR codes...',
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
          _updateQRCodeCount();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _updateQRCodeCount() async {
    if (_selectedFile != null) {
      if (_generateSingleQR) {
        setState(() {
          _qrCodeCount = 1;
        });
      } else {
        int count = await _qrService.getQRCodeCount(_selectedFile!);
        setState(() {
          _qrCodeCount = count;
        });
      }
    }
  }

  Future<void> _generateQRCode() async {
    if (_selectedFile == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      
      List<String> qrCodes = await _qrService.generateQRFromFile(
        _selectedFile!,
        encrypt: fileProvider.isEncryptionEnabled,
        password: fileProvider.encryptionPassword,
        asSingle: _generateSingleQR,
      );

      setState(() {
        _generatedQRCodes = qrCodes;
        _isGenerating = false;
      });

      // Add to history
      final updatedFile = FileInfoModel(
        name: _selectedFile!.name,
        path: _selectedFile!.path,
        size: _selectedFile!.size,
        type: _selectedFile!.type,
        dateCreated: _selectedFile!.dateCreated,
        isEncrypted: fileProvider.isEncryptionEnabled,
        qrCodes: qrCodes,
      );
      
      fileProvider.addFileToHistory(updatedFile);

    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating QR code: $e')),
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

