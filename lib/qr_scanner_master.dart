library;

import 'dart:io';
import 'dart:typed_data';

import 'models/qr_generation_options.dart';
import 'models/qr_scan_result.dart';
import 'models/scan_options.dart';
import 'qr_scanner_master_method_channel.dart';
import 'qr_scanner_master_platform_interface.dart';

// Export all public APIs
export 'models/qr_generation_options.dart';
export 'models/qr_scan_result.dart';
export 'models/scan_options.dart';
export 'qr_scanner_master_method_channel.dart' show QrScannerException;
export 'qr_scanner_master_platform_interface.dart';

/// Professional QR Code Scanner and Generator Plugin
///
/// This plugin provides comprehensive QR code and barcode functionality including:
/// - Real-time camera scanning
/// - Image file scanning
/// - QR code generation with advanced customization
/// - Multiple barcode format support
/// - Camera controls (flash, focus, etc.)
/// - Permission handling
class QrScannerMaster {
  static final QrScannerMaster _instance = QrScannerMaster._internal();

  factory QrScannerMaster() => _instance;

  QrScannerMaster._internal();

  /// Gets the platform version
  Future<String?> getPlatformVersion() {
    return QrScannerMasterPlatform.instance.getPlatformVersion();
  }

  /// Starts the camera scanner with customizable options
  ///
  /// Returns a [QrScanResult] if a code is successfully scanned,
  /// or null if the scan is cancelled or fails.
  ///
  /// Throws [QrScannerException] if there's an error during scanning.
  ///
  /// Example:
  /// ```dart
  /// final result = await QrScannerMaster().scanWithCamera(
  ///   ScanOptions(
  ///     formats: [BarcodeFormat.qrCode],
  ///     enableFlash: false,
  ///     showOverlay: true,
  ///   ),
  /// );
  ///
  /// if (result != null) {
  ///   print('Scanned: ${result.data}');
  /// }
  /// ```
  Future<QrScanResult?> scanWithCamera([ScanOptions? options]) {
    return QrScannerMasterPlatform.instance.scanWithCamera(
      options ?? const ScanOptions(),
    );
  }

  /// Scans QR/Barcode from an image file
  ///
  /// [imagePath] - Path to the image file
  /// [options] - Scanning options (optional)
  ///
  /// Returns a list of [QrScanResult] found in the image.
  ///
  /// Example:
  /// ```dart
  /// final results = await QrScannerMaster().scanFromImageFile(
  ///   '/path/to/image.jpg',
  ///   ScanOptions(formats: [BarcodeFormat.qrCode]),
  /// );
  ///
  /// for (final result in results) {
  ///   print('Found: ${result.data}');
  /// }
  /// ```
  Future<List<QrScanResult>> scanFromImageFile(
    String imagePath, [
    ScanOptions? options,
  ]) {
    return QrScannerMasterPlatform.instance.scanFromImage(
      imagePath,
      options ?? const ScanOptions(),
    );
  }

  /// Scans QR/Barcode from a File object
  Future<List<QrScanResult>> scanFromFile(
    File imageFile, [
    ScanOptions? options,
  ]) {
    return scanFromImageFile(imageFile.path, options);
  }

  /// Scans QR/Barcode from image bytes
  ///
  /// [imageBytes] - Raw image data as Uint8List
  /// [options] - Scanning options (optional)
  ///
  /// Returns a list of [QrScanResult] found in the image.
  Future<List<QrScanResult>> scanFromBytes(
    Uint8List imageBytes, [
    ScanOptions? options,
  ]) {
    return QrScannerMasterPlatform.instance.scanFromBytes(
      imageBytes,
      options ?? const ScanOptions(),
    );
  }

  /// Generates a QR code with advanced customization options
  ///
  /// [data] - The data to encode in the QR code
  /// [options] - Generation options for customization (optional)
  ///
  /// Returns the QR code as PNG image bytes.
  ///
  /// Example:
  /// ```dart
  /// final qrBytes = await QrScannerMaster().generateQrCode(
  ///   'https://example.com',
  ///   QrGenerationOptions(
  ///     size: 512,
  ///     foregroundColor: Colors.blue,
  ///     backgroundColor: Colors.white,
  ///     errorCorrectionLevel: ErrorCorrectionLevel.high,
  ///   ),
  /// );
  ///
  /// // Save to file or display in Image.memory(qrBytes)
  /// ```
  Future<Uint8List> generateQrCode(
    String data, [
    QrGenerationOptions? options,
  ]) {
    return QrScannerMasterPlatform.instance.generateQrCode(
      data,
      options ?? const QrGenerationOptions(),
    );
  }

  /// Generates a QR code and saves it to a file
  ///
  /// [data] - The data to encode
  /// [filePath] - Path where to save the QR code image
  /// [options] - Generation options (optional)
  ///
  /// Returns true if the file was saved successfully.
  Future<bool> generateQrCodeToFile(
    String data,
    String filePath, [
    QrGenerationOptions? options,
  ]) async {
    try {
      final qrBytes = await generateQrCode(data, options);
      final file = File(filePath);
      await file.writeAsBytes(qrBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the app has camera permission
  Future<bool> hasCameraPermission() {
    return QrScannerMasterPlatform.instance.hasCameraPermission();
  }

  /// Requests camera permission from the user
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestCameraPermission() {
    return QrScannerMasterPlatform.instance.requestCameraPermission();
  }

  /// Gets a list of available camera devices
  ///
  /// Returns a list of camera identifiers.
  Future<List<String>> getAvailableCameras() {
    return QrScannerMasterPlatform.instance.getAvailableCameras();
  }

  /// Checks if the device has a flash/torch
  Future<bool> hasFlash() {
    return QrScannerMasterPlatform.instance.hasFlash();
  }

  /// Toggles the camera flash/torch
  ///
  /// [enable] - true to turn on flash, false to turn off
  Future<void> toggleFlash(bool enable) {
    return QrScannerMasterPlatform.instance.toggleFlash(enable);
  }

  /// Gets a list of supported barcode formats
  ///
  /// Returns a list of format names that can be scanned.
  Future<List<String>> getSupportedFormats() {
    return QrScannerMasterPlatform.instance.getSupportedFormats();
  }

  /// Pauses the camera scanner (if currently active)
  Future<void> pauseScanner() {
    return QrScannerMasterPlatform.instance.pauseScanner();
  }

  /// Resumes the camera scanner (if paused)
  Future<void> resumeScanner() {
    return QrScannerMasterPlatform.instance.resumeScanner();
  }

  /// Stops the camera scanner completely
  Future<void> stopScanner() {
    return QrScannerMasterPlatform.instance.stopScanner();
  }

  // Convenience methods for common use cases

  /// Quick QR code scan with default settings
  Future<String?> quickScan() async {
    final result = await scanWithCamera(ScanPresets.qrOnly);
    return result?.data;
  }

  /// Quick QR code generation with default settings
  Future<Uint8List> quickGenerate(String data) {
    return generateQrCode(data, QrGenerationPresets.standard);
  }

  /// Scan multiple codes at once
  Future<List<QrScanResult>> multiScan({int maxScans = 10}) async {
    final result = await scanWithCamera(
      ScanOptions(
        multiScan: true,
        maxScans: maxScans,
        beepOnScan: true,
        vibrateOnScan: true,
      ),
    );

    return result != null ? [result] : [];
  }

  /// Generate a high-quality QR code suitable for printing
  Future<Uint8List> generatePrintQuality(String data) {
    return generateQrCode(data, QrGenerationPresets.highQuality);
  }

  /// Generate a colorful QR code with rounded corners
  Future<Uint8List> generateColorful(String data) {
    return generateQrCode(data, QrGenerationPresets.colorful);
  }
}
