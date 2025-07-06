/// Represents the result of a QR/Barcode scan operation
class QrScanResult {
  /// The raw data content of the scanned code
  final String data;

  /// The format/type of the scanned code (QR_CODE, EAN_13, CODE_128, etc.)
  final BarcodeFormat format;

  /// The timestamp when the scan was performed
  final DateTime timestamp;

  /// The corner points of the detected barcode (if available)
  final List<Point>? cornerPoints;

  /// Additional metadata about the scan
  final Map<String, dynamic>? metadata;

  const QrScanResult({
    required this.data,
    required this.format,
    required this.timestamp,
    this.cornerPoints,
    this.metadata,
  });

  /// Creates a QrScanResult from a JSON map
  factory QrScanResult.fromJson(Map<String, dynamic> json) {
    return QrScanResult(
      data: json['data'] as String,
      format: BarcodeFormat.fromString(json['format'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      cornerPoints: json['cornerPoints'] != null
          ? (json['cornerPoints'] as List)
                .map((point) => Point.fromJson(point as Map<String, dynamic>))
                .toList()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts the QrScanResult to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'format': format.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cornerPoints': cornerPoints?.map((point) => point.toJson()).toList(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'QrScanResult(data: $data, format: $format, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QrScanResult &&
        other.data == data &&
        other.format == format &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return data.hashCode ^ format.hashCode ^ timestamp.hashCode;
  }
}

/// Represents a 2D point with x and y coordinates
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(json['x'] as double, json['y'] as double);
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }

  @override
  String toString() => 'Point($x, $y)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Point && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Supported barcode formats
enum BarcodeFormat {
  qrCode('QR_CODE'),
  ean8('EAN_8'),
  ean13('EAN_13'),
  code39('CODE_39'),
  code93('CODE_93'),
  code128('CODE_128'),
  codabar('CODABAR'),
  itf('ITF'),
  rss14('RSS_14'),
  rssExpanded('RSS_EXPANDED'),
  upcA('UPC_A'),
  upcE('UPC_E'),
  upcEanExtension('UPC_EAN_EXTENSION'),
  dataMatrix('DATA_MATRIX'),
  aztec('AZTEC'),
  pdf417('PDF_417'),
  maxiCode('MAXICODE'),
  unknown('UNKNOWN');

  const BarcodeFormat(this.name);

  final String name;

  static BarcodeFormat fromString(String name) {
    return BarcodeFormat.values.firstWhere(
      (format) => format.name == name,
      orElse: () => BarcodeFormat.unknown,
    );
  }

  @override
  String toString() => name;
}
