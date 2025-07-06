import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/qr_generation_options.dart';
import 'models/qr_scan_result.dart';
import 'models/scan_options.dart';
import 'qr_scanner_master_method_channel.dart';

abstract class QrScannerMasterPlatform extends PlatformInterface {
  /// Constructs a QrScannerMasterPlatform.
  QrScannerMasterPlatform() : super(token: _token);

  static final Object _token = Object();

  static QrScannerMasterPlatform _instance = MethodChannelQrScannerMaster();

  /// The default instance of [QrScannerMasterPlatform] to use.
  ///
  /// Defaults to [MethodChannelQrScannerMaster].
  static QrScannerMasterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QrScannerMasterPlatform] when
  /// they register themselves.
  static set instance(QrScannerMasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets the platform version
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Starts the camera scanner with the given options
  Future<QrScanResult?> scanWithCamera(ScanOptions options) {
    throw UnimplementedError('scanWithCamera() has not been implemented.');
  }

  /// Scans QR/Barcode from an image file
  Future<List<QrScanResult>> scanFromImage(
    String imagePath,
    ScanOptions options,
  ) {
    throw UnimplementedError('scanFromImage() has not been implemented.');
  }

  /// Scans QR/Barcode from image bytes
  Future<List<QrScanResult>> scanFromBytes(
    Uint8List imageBytes,
    ScanOptions options,
  ) {
    throw UnimplementedError('scanFromBytes() has not been implemented.');
  }

  /// Generates a QR code with the given data and options
  Future<Uint8List> generateQrCode(String data, QrGenerationOptions options) {
    throw UnimplementedError('generateQrCode() has not been implemented.');
  }

  /// Checks if the device has camera permission
  Future<bool> hasCameraPermission() {
    throw UnimplementedError('hasCameraPermission() has not been implemented.');
  }

  /// Requests camera permission
  Future<bool> requestCameraPermission() {
    throw UnimplementedError(
      'requestCameraPermission() has not been implemented.',
    );
  }

  /// Gets available camera devices
  Future<List<String>> getAvailableCameras() {
    throw UnimplementedError('getAvailableCameras() has not been implemented.');
  }

  /// Checks if flash is available on the device
  Future<bool> hasFlash() {
    throw UnimplementedError('hasFlash() has not been implemented.');
  }

  /// Toggles the camera flash
  Future<void> toggleFlash(bool enable) {
    throw UnimplementedError('toggleFlash() has not been implemented.');
  }

  /// Gets supported barcode formats
  Future<List<String>> getSupportedFormats() {
    throw UnimplementedError('getSupportedFormats() has not been implemented.');
  }

  /// Pauses the camera scanner
  Future<void> pauseScanner() {
    throw UnimplementedError('pauseScanner() has not been implemented.');
  }

  /// Resumes the camera scanner
  Future<void> resumeScanner() {
    throw UnimplementedError('resumeScanner() has not been implemented.');
  }

  /// Stops the camera scanner
  Future<void> stopScanner() {
    throw UnimplementedError('stopScanner() has not been implemented.');
  }
}
