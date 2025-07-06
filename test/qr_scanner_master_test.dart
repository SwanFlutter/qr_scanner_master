import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qr_scanner_master/qr_scanner_master.dart';

class MockQrScannerMasterPlatform
    with MockPlatformInterfaceMixin
    implements QrScannerMasterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<QrScanResult?> scanWithCamera(ScanOptions options) => Future.value(
    QrScanResult(
      data: 'test_data',
      format: BarcodeFormat.qrCode,
      timestamp: DateTime.now(),
    ),
  );

  @override
  Future<List<QrScanResult>> scanFromImage(
    String imagePath,
    ScanOptions options,
  ) => Future.value([
    QrScanResult(
      data: 'test_data_from_image',
      format: BarcodeFormat.qrCode,
      timestamp: DateTime.now(),
    ),
  ]);

  @override
  Future<List<QrScanResult>> scanFromBytes(
    Uint8List imageBytes,
    ScanOptions options,
  ) => Future.value([
    QrScanResult(
      data: 'test_data_from_bytes',
      format: BarcodeFormat.qrCode,
      timestamp: DateTime.now(),
    ),
  ]);

  @override
  Future<Uint8List> generateQrCode(String data, QrGenerationOptions options) =>
      Future.value(Uint8List.fromList([1, 2, 3, 4]));

  @override
  Future<bool> hasCameraPermission() => Future.value(true);

  @override
  Future<bool> requestCameraPermission() => Future.value(true);

  @override
  Future<List<String>> getAvailableCameras() => Future.value(['back', 'front']);

  @override
  Future<bool> hasFlash() => Future.value(true);

  @override
  Future<void> toggleFlash(bool enable) => Future.value();

  @override
  Future<List<String>> getSupportedFormats() =>
      Future.value(['QR_CODE', 'EAN_13']);

  @override
  Future<void> pauseScanner() => Future.value();

  @override
  Future<void> resumeScanner() => Future.value();

  @override
  Future<void> stopScanner() => Future.value();
}

void main() {
  final QrScannerMasterPlatform initialPlatform =
      QrScannerMasterPlatform.instance;

  test('MethodChannelQrScannerMaster is the default instance', () {
    expect(initialPlatform.runtimeType.toString(), contains('MethodChannel'));
  });

  group('QrScannerMaster', () {
    late QrScannerMaster qrScannerMaster;
    late MockQrScannerMasterPlatform mockPlatform;

    setUp(() {
      qrScannerMaster = QrScannerMaster();
      mockPlatform = MockQrScannerMasterPlatform();
      QrScannerMasterPlatform.instance = mockPlatform;
    });

    tearDown(() {
      QrScannerMasterPlatform.instance = initialPlatform;
    });

    test('getPlatformVersion', () async {
      expect(await qrScannerMaster.getPlatformVersion(), '42');
    });

    test('scanWithCamera returns scan result', () async {
      final result = await qrScannerMaster.scanWithCamera();
      expect(result, isNotNull);
      expect(result!.data, 'test_data');
      expect(result.format, BarcodeFormat.qrCode);
    });

    test('scanFromImageFile returns scan results', () async {
      final results = await qrScannerMaster.scanFromImageFile('/test/path.jpg');
      expect(results, hasLength(1));
      expect(results.first.data, 'test_data_from_image');
    });

    test('scanFromBytes returns scan results', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final results = await qrScannerMaster.scanFromBytes(imageBytes);
      expect(results, hasLength(1));
      expect(results.first.data, 'test_data_from_bytes');
    });

    test('generateQrCode returns image bytes', () async {
      final qrBytes = await qrScannerMaster.generateQrCode('test data');
      expect(qrBytes, isNotNull);
      expect(qrBytes, hasLength(4));
    });

    test('hasCameraPermission returns true', () async {
      final hasPermission = await qrScannerMaster.hasCameraPermission();
      expect(hasPermission, isTrue);
    });

    test('requestCameraPermission returns true', () async {
      final granted = await qrScannerMaster.requestCameraPermission();
      expect(granted, isTrue);
    });

    test('getAvailableCameras returns camera list', () async {
      final cameras = await qrScannerMaster.getAvailableCameras();
      expect(cameras, hasLength(2));
      expect(cameras, contains('back'));
      expect(cameras, contains('front'));
    });

    test('hasFlash returns true', () async {
      final hasFlash = await qrScannerMaster.hasFlash();
      expect(hasFlash, isTrue);
    });

    test('getSupportedFormats returns format list', () async {
      final formats = await qrScannerMaster.getSupportedFormats();
      expect(formats, hasLength(2));
      expect(formats, contains('QR_CODE'));
      expect(formats, contains('EAN_13'));
    });

    test('quickScan returns data string', () async {
      final data = await qrScannerMaster.quickScan();
      expect(data, 'test_data');
    });

    test('quickGenerate returns image bytes', () async {
      final qrBytes = await qrScannerMaster.quickGenerate('test');
      expect(qrBytes, isNotNull);
      expect(qrBytes, hasLength(4));
    });
  });

  group('Models', () {
    test('QrScanResult serialization', () {
      final result = QrScanResult(
        data: 'test',
        format: BarcodeFormat.qrCode,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      final json = result.toJson();
      expect(json['data'], 'test');
      expect(json['format'], 'QR_CODE');
      expect(json['timestamp'], 1000);

      final restored = QrScanResult.fromJson(json);
      expect(restored.data, result.data);
      expect(restored.format, result.format);
      expect(restored.timestamp, result.timestamp);
    });

    test('ScanOptions serialization', () {
      const options = ScanOptions(
        formats: [BarcodeFormat.qrCode],
        enableFlash: true,
        multiScan: true,
        maxScans: 5,
      );

      final json = options.toJson();
      expect(json['formats'], ['QR_CODE']);
      expect(json['enableFlash'], true);
      expect(json['multiScan'], true);
      expect(json['maxScans'], 5);

      final restored = ScanOptions.fromJson(json);
      expect(restored.formats, options.formats);
      expect(restored.enableFlash, options.enableFlash);
      expect(restored.multiScan, options.multiScan);
      expect(restored.maxScans, options.maxScans);
    });

    test('QrGenerationOptions serialization', () {
      const options = QrGenerationOptions(
        size: 256,
        foregroundColor: Color(0xFF000000),
        backgroundColor: Color(0xFFFFFFFF),
        errorCorrectionLevel: ErrorCorrectionLevel.high,
      );

      final json = options.toJson();
      expect(json['size'], 256);
      expect(json['foregroundColor'], 0xFF000000);
      expect(json['backgroundColor'], 0xFFFFFFFF);
      expect(json['errorCorrectionLevel'], 'HIGH');

      final restored = QrGenerationOptions.fromJson(json);
      expect(restored.size, options.size);
      expect(restored.foregroundColor, options.foregroundColor);
      expect(restored.backgroundColor, options.backgroundColor);
      expect(restored.errorCorrectionLevel, options.errorCorrectionLevel);
    });
  });
}
