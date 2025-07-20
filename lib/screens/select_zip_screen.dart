
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qrbridge_app/widgets/custom_button.dart';

class SelectZipScreen extends StatefulWidget {
  const SelectZipScreen({super.key});

  @override
  _SelectZipScreenState createState() => _SelectZipScreenState();
}

class _SelectZipScreenState extends State<SelectZipScreen> {
  File? _selectedZipFile;
  String _extractionStatus = '';

  Future<void> _pickZipFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null) {
      setState(() {
        _selectedZipFile = File(result.files.single.path!);
        _extractionStatus = '';
      });
    }
  }

  Future<void> _extractAndReconstruct() async {
    if (_selectedZipFile == null) {
      return;
    }

    try {
      final bytes = await _selectedZipFile!.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final downloadsDir = await getDownloadsDirectory();
      final reconstructedFilePath = '${downloadsDir!.path}/reconstructed_file';

      final reconstructedFile = File(reconstructedFilePath);
      if (await reconstructedFile.exists()) {
        await reconstructedFile.delete();
      }

      final output = reconstructedFile.openWrite();
      for (final file in archive) {
        if (file.isFile) {
          output.add(file.content as List<int>);
        }
      }
      await output.close();

      setState(() {
        _extractionStatus = 'File reconstructed successfully at $reconstructedFilePath';
      });
    } catch (e) {
      setState(() {
        _extractionStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select ZIP and Reconstruct'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(
              onPressed: _pickZipFile,
              text: 'Select ZIP File',
            ),
            const SizedBox(height: 20),
            if (_selectedZipFile != null)
              Text('Selected File: ${_selectedZipFile!.path}'),
            const SizedBox(height: 20),
            CustomButton(
              onPressed: _extractAndReconstruct,
              text: 'Extract and Reconstruct',
            ),
            const SizedBox(height: 20),
            Text(_extractionStatus),
          ],
        ),
      ),
    );
  }
}
