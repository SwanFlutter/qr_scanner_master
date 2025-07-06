import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/qr_generation_options.dart';
import 'models/qr_scan_result.dart';
import 'models/scan_options.dart';
import 'qr_scanner_master_platform_interface.dart';

/// An implementation of [QrScannerMasterPlatform] that uses method channels.
class MethodChannelQrScannerMaster extends QrScannerMasterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('qr_scanner_master');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<QrScanResult?> scanWithCamera(ScanOptions options) async {
    try {
      final result = await methodChannel.invokeMethod<Map<String, dynamic>>(
        'scanWithCamera',
        options.toJson(),
      );

      if (result == null) return null;

      return QrScanResult.fromJson(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<List<QrScanResult>> scanFromImage(
    String imagePath,
    ScanOptions options,
  ) async {
    try {
      final results = await methodChannel.invokeMethod<List<dynamic>>(
        'scanFromImage',
        {'imagePath': imagePath, ...options.toJson()},
      );

      if (results == null) return [];

      return results
          .map(
            (result) =>
                QrScanResult.fromJson(Map<String, dynamic>.from(result)),
          )
          .toList();
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<List<QrScanResult>> scanFromBytes(
    Uint8List imageBytes,
    ScanOptions options,
  ) async {
    try {
      final results = await methodChannel.invokeMethod<List<dynamic>>(
        'scanFromBytes',
        {'imageBytes': imageBytes, ...options.toJson()},
      );

      if (results == null) return [];

      return results
          .map(
            (result) =>
                QrScanResult.fromJson(Map<String, dynamic>.from(result)),
          )
          .toList();
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<Uint8List> generateQrCode(
    String data,
    QrGenerationOptions options,
  ) async {
    try {
      final result = await methodChannel.invokeMethod<Uint8List>(
        'generateQrCode',
        {'data': data, ...options.toJson()},
      );

      if (result == null) {
        throw const QrScannerException('Failed to generate QR code');
      }

      return result;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<bool> hasCameraPermission() async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'hasCameraPermission',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'requestCameraPermission',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<List<String>> getAvailableCameras() async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>(
        'getAvailableCameras',
      );
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<bool> hasFlash() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('hasFlash');
      return result ?? false;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<void> toggleFlash(bool enable) async {
    try {
      await methodChannel.invokeMethod<void>('toggleFlash', {'enable': enable});
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<List<String>> getSupportedFormats() async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>(
        'getSupportedFormats',
      );
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<void> pauseScanner() async {
    try {
      await methodChannel.invokeMethod<void>('pauseScanner');
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<void> resumeScanner() async {
    try {
      await methodChannel.invokeMethod<void>('resumeScanner');
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<void> stopScanner() async {
    try {
      await methodChannel.invokeMethod<void>('stopScanner');
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  /// Handles platform exceptions and converts them to appropriate exceptions
  Exception _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'PERMISSION_DENIED':
        return QrScannerException('Camera permission denied: ${e.message}');
      case 'CAMERA_ERROR':
        return QrScannerException('Camera error: ${e.message}');
      case 'SCAN_CANCELLED':
        return QrScannerException('Scan was cancelled by user');
      case 'INVALID_IMAGE':
        return QrScannerException('Invalid image format: ${e.message}');
      case 'NO_BARCODE_FOUND':
        return QrScannerException('No barcode found in image');
      case 'GENERATION_FAILED':
        return QrScannerException('QR code generation failed: ${e.message}');
      default:
        return QrScannerException('Platform error: ${e.message}');
    }
  }
}

/// Custom exception for QR scanner operations
class QrScannerException implements Exception {
  final String message;

  const QrScannerException(this.message);

  @override
  String toString() => 'QrScannerException: $message';
}
