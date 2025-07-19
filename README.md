# QRBridge - Android App for File Sharing via QR Codes

QRBridge is a Flutter-based Android application that allows users to securely share any file (image, PDF, video, document, etc.) via QR codes, which can be scanned and decoded only using the same app.

## Features

### 🔄 Core Functionality
- **File to QR Generator**: Convert any file into QR code(s)
- **QR Scanner & File Reconstruction**: Scan QR codes to rebuild files
- **Multi-chunk Support**: Handle large files by splitting into multiple QR codes
- **File Encryption**: Optional encryption for secure file sharing
- **File History**: Track recently sent/received files

### 🎨 UI/UX Design
- **Modern Design**: Glassmorphism + minimalistic interface
- **iOS-style UI**: Apple Music inspired design
- **Dark/Light Theme**: Toggle between themes
- **Bottom Navigation**: Easy access to all features
- **Smooth Animations**: Lottie animations for better UX

### 🔒 Security Features
- **File Encryption**: AES encryption with password protection
- **Secure Storage**: Flutter secure storage for sensitive data
- **Permission Management**: Proper Android permissions handling

## Architecture

### Folder Structure
```
lib/
├── main.dart
├── screens/
│   ├── home_screen.dart
│   ├── generate_qr_screen.dart
│   ├── scan_qr_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── qr_carousel.dart
│   ├── file_tile.dart
│   └── custom_button.dart
├── services/
│   ├── qr_generator_service.dart
│   ├── qr_scanner_service.dart
│   └── file_encryption_service.dart
├── utils/
│   ├── file_utils.dart
│   └── qr_utils.dart
├── models/
│   └── file_info_model.dart
└── provider/
    └── file_provider.dart
```

## Technologies Used

- **Flutter (Dart)**: Cross-platform mobile development
- **Provider**: State management
- **file_picker**: File selection from device
- **qr_flutter**: QR code generation
- **mobile_scanner**: Real-time QR scanning
- **encrypt**: File encryption/decryption
- **flutter_secure_storage**: Secure data storage
- **path_provider**: File system access
- **permission_handler**: Android permissions
- **lottie**: Smooth animations

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code
- Android device or emulator (API level 21+)

### Installation
1. Clone or extract the project
2. Navigate to project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Building APK
```bash
flutter build apk --release
```

## Usage

### Generating QR Codes
1. Open QRBridge app
2. Navigate to "Generate" tab
3. Select a file using "Pick File" button
4. Optionally enable encryption in Settings
5. Tap "Generate QR Code"
6. View, save, or share the generated QR code(s)

### Scanning QR Codes
1. Navigate to "Scanner" tab
2. Point camera at QR code
3. For multi-chunk files, scan all QR codes in sequence
4. Wait for file reconstruction
5. View or save the reconstructed file

### Settings
- **Dark Mode**: Toggle between light and dark themes
- **File Encryption**: Enable/disable file encryption
- **Password Management**: Set encryption password
- **Clear History**: Remove all file history
- **Export Logs**: Export app usage logs

## Key Features Explained

### File Chunking
Large files are automatically split into multiple QR codes to ensure reliable scanning and reconstruction.

### Encryption
Files can be encrypted using AES encryption before generating QR codes, ensuring secure file sharing.

### File History
The app maintains a history of recently processed files for easy re-sharing or reference.

### Cross-Platform Compatibility
Built with Flutter for potential iOS support in the future.

## Permissions Required

- **Camera**: For QR code scanning
- **Storage**: For file access and saving
- **Internet**: For potential future cloud features

## Future Enhancements

- Cloud backup integration (Google Drive)
- Web companion tool
- NFC file sharing
- Chat + QR file transfer
- In-app file preview
- Batch file processing

## Developer

**Developed by Suvojeet**

## Version

Current Version: 1.0.0

## License

This project is developed for educational and personal use.

## Support

For issues or questions, please refer to the documentation or contact the developer.

---

*QRBridge - Bridging files through QR codes*

