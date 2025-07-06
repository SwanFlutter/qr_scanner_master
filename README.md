# QR Scanner Master

Professional QR Code Scanner and Generator Plugin for Flutter with advanced features including real-time scanning, QR generation, barcode support, and comprehensive customization options.

## Features

<<<<<<< HEAD
This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.7457457457
=======
### 🔍 **Advanced Scanning**
- **Real-time camera scanning** with customizable overlay
- **Image file scanning** from gallery or file system
- **Multiple barcode format support** (QR Code, EAN-8/13, Code 39/93/128, DataMatrix, Aztec, PDF417, and more)
- **Multi-scan mode** for scanning multiple codes in one session
- **Auto-focus and flash control**
- **Scan area restriction** for better performance
- **Audio and haptic feedback**
>>>>>>> 804a076c7404572b1b989a083bb98caaf19ca67b

### 🎨 **Professional QR Generation**
- **High-quality QR code generation** with customizable size
- **Advanced styling options**: colors, gradients, rounded corners
- **Logo embedding** in QR codes
- **Error correction levels** (Low, Medium, Quartile, High)
- **Border and margin customization**
- **Export to file** or get as bytes

### 📱 **Platform Support**
- **Android** (API 21+) with CameraX and ML Kit
- **iOS** (12.0+) with AVFoundation and Vision framework
- **Permission handling** with user-friendly prompts
- **Camera controls** (flash, focus, resolution)

### 🛠️ **Developer Experience**
- **Comprehensive error handling** with custom exceptions
- **Type-safe APIs** with detailed documentation
- **Preset configurations** for common use cases
- **Extensive customization options**
- **Memory efficient** image processing

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  qr_scanner_master: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.FLASHLIGHT" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes and barcodes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to scan QR codes from images</string>
```

## Quick Start

### Basic QR Code Scanning

```dart
import 'package:qr_scanner_master/qr_scanner_master.dart';

// Simple scan
final qrScanner = QrScannerMaster();
final result = await qrScanner.quickScan();
if (result != null) {
  print('Scanned: $result');
}

// Advanced scan with options
final scanResult = await qrScanner.scanWithCamera(
  ScanOptions(
    formats: [BarcodeFormat.qrCode],
    enableFlash: false,
    showOverlay: true,
    beepOnScan: true,
    vibrateOnScan: true,
  ),
);

if (scanResult != null) {
  print('Data: ${scanResult.data}');
  print('Format: ${scanResult.format}');
  print('Timestamp: ${scanResult.timestamp}');
}
```

### QR Code Generation

```dart
import 'package:qr_scanner_master/qr_scanner_master.dart';

final qrScanner = QrScannerMaster();

// Simple generation
final qrBytes = await qrScanner.quickGenerate('https://flutter.dev');

// Advanced generation with styling
final styledQrBytes = await qrScanner.generateQrCode(
  'https://flutter.dev',
  QrGenerationOptions(
    size: 512,
    foregroundColor: Color(0xFF2196F3),
    backgroundColor: Color(0xFFFFFFFF),
    errorCorrectionLevel: ErrorCorrectionLevel.high,
    margin: 20,
    roundedCorners: true,
    cornerRadius: 8.0,
  ),
);

// Display in your app
Image.memory(styledQrBytes)

// Or save to file
await qrScanner.generateQrCodeToFile(
  'https://flutter.dev',
  '/path/to/qr_code.png',
);
```

### Scanning from Images

```dart
// Scan from file path
final results = await qrScanner.scanFromImageFile('/path/to/image.jpg');

// Scan from File object
final file = File('/path/to/image.jpg');
final results = await qrScanner.scanFromFile(file);

// Scan from bytes
final imageBytes = await file.readAsBytes();
final results = await qrScanner.scanFromBytes(imageBytes);

for (final result in results) {
  print('Found: ${result.data}');
}
```

## Advanced Usage

### Custom Scan Options

```dart
final result = await qrScanner.scanWithCamera(
  ScanOptions(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13],
    enableFlash: true,
    autoFocus: true,
    multiScan: true,
    maxScans: 5,
    beepOnScan: true,
    vibrateOnScan: true,
    showOverlay: true,
    overlayColor: 0xFF00FF00,
    restrictScanArea: true,
    scanAreaRatio: 0.8,
    timeoutSeconds: 30,
    cameraResolution: CameraResolution.high,
    cameraFacing: CameraFacing.back,
  ),
);
```

### Advanced QR Generation

```dart
final qrBytes = await qrScanner.generateQrCode(
  'https://flutter.dev',
  QrGenerationOptions(
    size: 1024,
    errorCorrectionLevel: ErrorCorrectionLevel.high,
    foregroundColor: Color(0xFF000000),
    backgroundColor: Color(0xFFFFFFFF),
    margin: 40,

    // Add logo
    logoData: logoImageBytes,
    logoSizeRatio: 0.2,

    // Styling
    roundedCorners: true,
    cornerRadius: 12.0,

    // Gradient colors
    gradientColors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
    gradientDirection: 0.5, // Diagonal

    // Border
    addBorder: true,
    borderWidth: 4,
    borderColor: Color(0xFF333333),
  ),
);
```

### Permission Handling

```dart
// Check permissions
final hasPermission = await qrScanner.hasCameraPermission();

// Request permissions
final granted = await qrScanner.requestCameraPermission();

if (!granted) {
  // Handle permission denied
  print('Camera permission is required for scanning');
}
```

### Camera Controls

```dart
// Get available cameras
final cameras = await qrScanner.getAvailableCameras();

// Check flash availability
final hasFlash = await qrScanner.hasFlash();

// Toggle flash
await qrScanner.toggleFlash(true);

// Scanner controls
await qrScanner.pauseScanner();
await qrScanner.resumeScanner();
await qrScanner.stopScanner();
```

## Preset Configurations

The plugin includes several preset configurations for common use cases:

### Scan Presets

```dart
// QR codes only
await qrScanner.scanWithCamera(ScanPresets.qrOnly);

// All supported formats
await qrScanner.scanWithCamera(ScanPresets.allFormats);

// Fast scanning
await qrScanner.scanWithCamera(ScanPresets.fastScan);

// High quality scanning
await qrScanner.scanWithCamera(ScanPresets.highQuality);

// Multiple codes
await qrScanner.scanWithCamera(ScanPresets.multiScan);

// Silent scanning (no sound/vibration)
await qrScanner.scanWithCamera(ScanPresets.silent);
```

### Generation Presets

```dart
// Standard QR code
await qrScanner.generateQrCode(data, QrGenerationPresets.standard);

// High quality for printing
await qrScanner.generateQrCode(data, QrGenerationPresets.highQuality);

// Colorful with rounded corners
await qrScanner.generateQrCode(data, QrGenerationPresets.colorful);

// Minimal size
await qrScanner.generateQrCode(data, QrGenerationPresets.minimal);

// With border
await qrScanner.generateQrCode(data, QrGenerationPresets.withBorder);
```

## Supported Barcode Formats

- **QR Code**
- **EAN-8, EAN-13**
- **Code 39, Code 93, Code 128**
- **Codabar**
- **ITF (Interleaved 2 of 5)**
- **UPC-A, UPC-E**
- **Data Matrix**
- **Aztec**
- **PDF417**
- **RSS-14, RSS-Expanded**

## Error Handling

The plugin provides comprehensive error handling with custom exceptions:

```dart
try {
  final result = await qrScanner.scanWithCamera();
} on QrScannerException catch (e) {
  switch (e.message) {
    case 'Camera permission denied':
      // Handle permission error
      break;
    case 'Camera error':
      // Handle camera error
      break;
    case 'Scan was cancelled by user':
      // Handle cancellation
      break;
    default:
      // Handle other errors
      break;
  }
} catch (e) {
  // Handle unexpected errors
  print('Unexpected error: $e');
}
```

## Performance Tips

1. **Use appropriate scan options**: Limit formats and scan area for better performance
2. **Handle permissions early**: Check and request permissions before scanning
3. **Optimize image size**: For image scanning, use appropriately sized images
4. **Use presets**: Leverage built-in presets for common scenarios
5. **Clean up resources**: Stop scanner when not needed

## Example App

The plugin includes a comprehensive example app demonstrating all features. To run it:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, feature requests, or questions, please visit our [GitHub repository](https://github.com/example/qr_scanner_master).

