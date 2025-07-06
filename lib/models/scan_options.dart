import 'qr_scan_result.dart';

/// Options for configuring the QR/Barcode scanning behavior
class ScanOptions {
  /// List of barcode formats to scan for (if empty, scans all supported formats)
  final List<BarcodeFormat> formats;

  /// Whether to enable the camera flash/torch
  final bool enableFlash;

  /// Whether to enable auto-focus
  final bool autoFocus;

  /// Whether to scan multiple codes in a single session
  final bool multiScan;

  /// Maximum number of codes to scan in multi-scan mode (0 = unlimited)
  final int maxScans;

  /// Whether to play a beep sound when a code is detected
  final bool beepOnScan;

  /// Whether to vibrate when a code is detected
  final bool vibrateOnScan;

  /// Whether to show a scanning overlay with guidelines
  final bool showOverlay;

  /// Color of the scanning overlay
  final int overlayColor;

  /// Whether to restrict scanning to a specific area
  final bool restrictScanArea;

  /// Scan area as a percentage of the screen (0.0 to 1.0)
  final double scanAreaRatio;

  /// Timeout for scanning in seconds (0 = no timeout)
  final int timeoutSeconds;

  /// Whether to return the raw image data along with scan results
  final bool returnImage;

  /// Image quality for returned images (0.0 to 1.0)
  final double imageQuality;

  /// Whether to detect inverted (white on black) codes
  final bool detectInverted;

  /// Camera resolution preference
  final CameraResolution cameraResolution;

  /// Camera facing preference
  final CameraFacing cameraFacing;

  const ScanOptions({
    this.formats = const [],
    this.enableFlash = false,
    this.autoFocus = true,
    this.multiScan = false,
    this.maxScans = 1,
    this.beepOnScan = true,
    this.vibrateOnScan = true,
    this.showOverlay = true,
    this.overlayColor = 0xFF00FF00,
    this.restrictScanArea = false,
    this.scanAreaRatio = 0.7,
    this.timeoutSeconds = 0,
    this.returnImage = false,
    this.imageQuality = 0.8,
    this.detectInverted = false,
    this.cameraResolution = CameraResolution.medium,
    this.cameraFacing = CameraFacing.back,
  }) : assert(maxScans >= 0, 'Max scans must be non-negative'),
       assert(
         scanAreaRatio > 0.0 && scanAreaRatio <= 1.0,
         'Scan area ratio must be between 0.0 and 1.0',
       ),
       assert(timeoutSeconds >= 0, 'Timeout must be non-negative'),
       assert(
         imageQuality >= 0.0 && imageQuality <= 1.0,
         'Image quality must be between 0.0 and 1.0',
       );

  /// Creates a copy of this options with the given fields replaced
  ScanOptions copyWith({
    List<BarcodeFormat>? formats,
    bool? enableFlash,
    bool? autoFocus,
    bool? multiScan,
    int? maxScans,
    bool? beepOnScan,
    bool? vibrateOnScan,
    bool? showOverlay,
    int? overlayColor,
    bool? restrictScanArea,
    double? scanAreaRatio,
    int? timeoutSeconds,
    bool? returnImage,
    double? imageQuality,
    bool? detectInverted,
    CameraResolution? cameraResolution,
    CameraFacing? cameraFacing,
  }) {
    return ScanOptions(
      formats: formats ?? this.formats,
      enableFlash: enableFlash ?? this.enableFlash,
      autoFocus: autoFocus ?? this.autoFocus,
      multiScan: multiScan ?? this.multiScan,
      maxScans: maxScans ?? this.maxScans,
      beepOnScan: beepOnScan ?? this.beepOnScan,
      vibrateOnScan: vibrateOnScan ?? this.vibrateOnScan,
      showOverlay: showOverlay ?? this.showOverlay,
      overlayColor: overlayColor ?? this.overlayColor,
      restrictScanArea: restrictScanArea ?? this.restrictScanArea,
      scanAreaRatio: scanAreaRatio ?? this.scanAreaRatio,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      returnImage: returnImage ?? this.returnImage,
      imageQuality: imageQuality ?? this.imageQuality,
      detectInverted: detectInverted ?? this.detectInverted,
      cameraResolution: cameraResolution ?? this.cameraResolution,
      cameraFacing: cameraFacing ?? this.cameraFacing,
    );
  }

  /// Converts the options to a JSON map for platform communication
  Map<String, dynamic> toJson() {
    return {
      'formats': formats.map((format) => format.name).toList(),
      'enableFlash': enableFlash,
      'autoFocus': autoFocus,
      'multiScan': multiScan,
      'maxScans': maxScans,
      'beepOnScan': beepOnScan,
      'vibrateOnScan': vibrateOnScan,
      'showOverlay': showOverlay,
      'overlayColor': overlayColor,
      'restrictScanArea': restrictScanArea,
      'scanAreaRatio': scanAreaRatio,
      'timeoutSeconds': timeoutSeconds,
      'returnImage': returnImage,
      'imageQuality': imageQuality,
      'detectInverted': detectInverted,
      'cameraResolution': cameraResolution.name,
      'cameraFacing': cameraFacing.name,
    };
  }

  /// Creates options from a JSON map
  factory ScanOptions.fromJson(Map<String, dynamic> json) {
    return ScanOptions(
      formats:
          (json['formats'] as List?)
              ?.map((format) => BarcodeFormat.fromString(format as String))
              .toList() ??
          const [],
      enableFlash: json['enableFlash'] as bool? ?? false,
      autoFocus: json['autoFocus'] as bool? ?? true,
      multiScan: json['multiScan'] as bool? ?? false,
      maxScans: json['maxScans'] as int? ?? 1,
      beepOnScan: json['beepOnScan'] as bool? ?? true,
      vibrateOnScan: json['vibrateOnScan'] as bool? ?? true,
      showOverlay: json['showOverlay'] as bool? ?? true,
      overlayColor: json['overlayColor'] as int? ?? 0xFF00FF00,
      restrictScanArea: json['restrictScanArea'] as bool? ?? false,
      scanAreaRatio: json['scanAreaRatio'] as double? ?? 0.7,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 0,
      returnImage: json['returnImage'] as bool? ?? false,
      imageQuality: json['imageQuality'] as double? ?? 0.8,
      detectInverted: json['detectInverted'] as bool? ?? false,
      cameraResolution: CameraResolution.fromString(
        json['cameraResolution'] as String? ?? 'MEDIUM',
      ),
      cameraFacing: CameraFacing.fromString(
        json['cameraFacing'] as String? ?? 'BACK',
      ),
    );
  }

  @override
  String toString() {
    return 'ScanOptions(formats: $formats, enableFlash: $enableFlash, '
        'multiScan: $multiScan, maxScans: $maxScans)';
  }
}

/// Camera resolution options
enum CameraResolution {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH'),
  veryHigh('VERY_HIGH');

  const CameraResolution(this.name);

  final String name;

  static CameraResolution fromString(String name) {
    return CameraResolution.values.firstWhere(
      (resolution) => resolution.name == name,
      orElse: () => CameraResolution.medium,
    );
  }

  @override
  String toString() => name;
}

/// Camera facing options
enum CameraFacing {
  front('FRONT'),
  back('BACK');

  const CameraFacing(this.name);

  final String name;

  static CameraFacing fromString(String name) {
    return CameraFacing.values.firstWhere(
      (facing) => facing.name == name,
      orElse: () => CameraFacing.back,
    );
  }

  @override
  String toString() => name;
}

// Import BarcodeFormat from qr_scan_result.dart

/// Predefined scan option presets
class ScanPresets {
  static const ScanOptions qrOnly = ScanOptions(
    formats: [BarcodeFormat.qrCode],
  );

  static const ScanOptions allFormats = ScanOptions(formats: []);

  static const ScanOptions fastScan = ScanOptions(
    autoFocus: true,
    cameraResolution: CameraResolution.medium,
    timeoutSeconds: 10,
  );

  static const ScanOptions highQuality = ScanOptions(
    cameraResolution: CameraResolution.veryHigh,
    returnImage: true,
    imageQuality: 1.0,
  );

  static const ScanOptions multiScan = ScanOptions(
    multiScan: true,
    maxScans: 10,
    beepOnScan: true,
    vibrateOnScan: true,
  );

  static const ScanOptions silent = ScanOptions(
    beepOnScan: false,
    vibrateOnScan: false,
  );
}
