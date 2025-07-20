import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../provider/file_provider.dart';
import '../services/qr_scanner_service.dart';
import '../models/file_info_model.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final QRScannerService _scannerService = QRScannerService();
  
  bool _isScanning = true;
  bool _isProcessing = false;
  List<String> _scannedCodes = [];
  int _expectedChunks = 0;
  String? _reconstructedFilePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _pickAndScanImage,
            icon: const Icon(Icons.image),
          ),
          IconButton(
            onPressed: () {
              cameraController.toggleTorch();
            },
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () {
              cameraController.switchCamera();
            },
            icon: const Icon(Icons.flip_camera_ios),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                if (_isScanning)
                  MobileScanner(
                    controller: cameraController,
                    onDetect: _onQRCodeDetected,
                  )
                else
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        'Camera stopped',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                
                // Scanning overlay
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Corner decorations
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  if (_scannedCodes.isEmpty) ...[
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Point camera at QR code or select an image',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _expectedChunks > 0 
                                ? _scannedCodes.length / _expectedChunks 
                                : 0,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          '${_scannedCodes.length}${_expectedChunks > 0 ? '/$_expectedChunks' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    if (_isProcessing) ...[
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text(
                              'Reconstructing file...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_reconstructedFilePath != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'File successfully reconstructed!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _viewFile,
                              icon: const Icon(Icons.visibility),
                              label: const Text('View File'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _resetScanner,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Scan Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Scanned QR Codes:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _scannedCodes.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.qr_code, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Chunk ${index + 1}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const Icon(Icons.check, color: Colors.green),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndScanImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final String imagePath = result.files.single.path!;
        final BarcodeCapture? capture = await cameraController.analyzeImage(imagePath);
        if (capture != null) {
          _onQRCodeDetected(capture);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning image: $e')),
      );
    }
  }

  void _onQRCodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && !_scannedCodes.contains(code)) {
        setState(() {
          _scannedCodes.add(code);
        });

        // Check if this is a chunked QR code
        if (code.contains('CHUNK:')) {
          final parts = code.split(':');
          if (parts.length >= 3) {
            final totalChunks = int.tryParse(parts[2]) ?? 0;
            if (totalChunks > _expectedChunks) {
              setState(() {
                _expectedChunks = totalChunks;
              });
            }
          }
        }

        // Try to reconstruct file if we have all chunks
        if (_expectedChunks > 0 && _scannedCodes.length >= _expectedChunks) {
          await _reconstructFile();
        } else if (_expectedChunks == 0 && _scannedCodes.length == 1) {
          // Single QR code
          await _reconstructFile();
        }
      }
    }
  }

  Future<void> _reconstructFile() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      
      final filePath = await _scannerService.reconstructFileFromQR(
        _scannedCodes,
        decrypt: fileProvider.isEncryptionEnabled,
        password: fileProvider.encryptionPassword,
      );

      if (filePath != null) {
        setState(() {
          _reconstructedFilePath = filePath;
          _isProcessing = false;
        });

        // Add to history
        final fileInfo = await _scannerService.getFileInfo(filePath);
        if (fileInfo != null) {
          fileProvider.addFileToHistory(fileInfo);
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reconstructing file: $e')),
      );
    }
  }

  void _viewFile() {
    if (_reconstructedFilePath != null) {
      // Navigate to file preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreviewScreen(filePath: _reconstructedFilePath!),
        ),
      );
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedCodes.clear();
      _expectedChunks = 0;
      _reconstructedFilePath = null;
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class FilePreviewScreen extends StatelessWidget {
  final String filePath;

  const FilePreviewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Preview'),
      ),
      body: const Center(
        child: Text('File preview functionality would be implemented here'),
      ),
    );
  }
}

