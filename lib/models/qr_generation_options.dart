import 'dart:typed_data';
import 'dart:ui';

/// Options for generating QR codes
class QrGenerationOptions {
  /// The size of the QR code in pixels (width and height)
  final int size;
  
  /// The error correction level
  final ErrorCorrectionLevel errorCorrectionLevel;
  
  /// The foreground color of the QR code
  final Color foregroundColor;
  
  /// The background color of the QR code
  final Color backgroundColor;
  
  /// The margin around the QR code in pixels
  final int margin;
  
  /// Optional logo to embed in the center of the QR code
  final Uint8List? logoData;
  
  /// Size of the logo as a percentage of the QR code size (0.0 to 0.3)
  final double logoSizeRatio;
  
  /// Whether to use rounded corners for the QR code modules
  final bool roundedCorners;
  
  /// The radius for rounded corners (if enabled)
  final double cornerRadius;
  
  /// Custom gradient colors (if null, uses solid colors)
  final List<Color>? gradientColors;
  
  /// Gradient direction (0.0 = horizontal, 0.5 = diagonal, 1.0 = vertical)
  final double gradientDirection;
  
  /// Whether to add a border around the QR code
  final bool addBorder;
  
  /// Border width in pixels
  final int borderWidth;
  
  /// Border color
  final Color borderColor;

  const QrGenerationOptions({
    this.size = 512,
    this.errorCorrectionLevel = ErrorCorrectionLevel.medium,
    this.foregroundColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.margin = 20,
    this.logoData,
    this.logoSizeRatio = 0.2,
    this.roundedCorners = false,
    this.cornerRadius = 4.0,
    this.gradientColors,
    this.gradientDirection = 0.0,
    this.addBorder = false,
    this.borderWidth = 2,
    this.borderColor = const Color(0xFF000000),
  }) : assert(size > 0 && size <= 2048, 'Size must be between 1 and 2048'),
       assert(margin >= 0, 'Margin must be non-negative'),
       assert(logoSizeRatio >= 0.0 && logoSizeRatio <= 0.3, 'Logo size ratio must be between 0.0 and 0.3'),
       assert(cornerRadius >= 0.0, 'Corner radius must be non-negative'),
       assert(gradientDirection >= 0.0 && gradientDirection <= 1.0, 'Gradient direction must be between 0.0 and 1.0'),
       assert(borderWidth >= 0, 'Border width must be non-negative');

  /// Creates a copy of this options with the given fields replaced
  QrGenerationOptions copyWith({
    int? size,
    ErrorCorrectionLevel? errorCorrectionLevel,
    Color? foregroundColor,
    Color? backgroundColor,
    int? margin,
    Uint8List? logoData,
    double? logoSizeRatio,
    bool? roundedCorners,
    double? cornerRadius,
    List<Color>? gradientColors,
    double? gradientDirection,
    bool? addBorder,
    int? borderWidth,
    Color? borderColor,
  }) {
    return QrGenerationOptions(
      size: size ?? this.size,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      margin: margin ?? this.margin,
      logoData: logoData ?? this.logoData,
      logoSizeRatio: logoSizeRatio ?? this.logoSizeRatio,
      roundedCorners: roundedCorners ?? this.roundedCorners,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      gradientColors: gradientColors ?? this.gradientColors,
      gradientDirection: gradientDirection ?? this.gradientDirection,
      addBorder: addBorder ?? this.addBorder,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  /// Converts the options to a JSON map for platform communication
  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'errorCorrectionLevel': errorCorrectionLevel.name,
      'foregroundColor': foregroundColor.value,
      'backgroundColor': backgroundColor.value,
      'margin': margin,
      'logoData': logoData,
      'logoSizeRatio': logoSizeRatio,
      'roundedCorners': roundedCorners,
      'cornerRadius': cornerRadius,
      'gradientColors': gradientColors?.map((color) => color.value).toList(),
      'gradientDirection': gradientDirection,
      'addBorder': addBorder,
      'borderWidth': borderWidth,
      'borderColor': borderColor.value,
    };
  }

  /// Creates options from a JSON map
  factory QrGenerationOptions.fromJson(Map<String, dynamic> json) {
    return QrGenerationOptions(
      size: json['size'] as int? ?? 512,
      errorCorrectionLevel: ErrorCorrectionLevel.fromString(
        json['errorCorrectionLevel'] as String? ?? 'MEDIUM',
      ),
      foregroundColor: Color(json['foregroundColor'] as int? ?? 0xFF000000),
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFFFFFFFF),
      margin: json['margin'] as int? ?? 20,
      logoData: json['logoData'] as Uint8List?,
      logoSizeRatio: json['logoSizeRatio'] as double? ?? 0.2,
      roundedCorners: json['roundedCorners'] as bool? ?? false,
      cornerRadius: json['cornerRadius'] as double? ?? 4.0,
      gradientColors: (json['gradientColors'] as List?)
          ?.map((colorValue) => Color(colorValue as int))
          .toList(),
      gradientDirection: json['gradientDirection'] as double? ?? 0.0,
      addBorder: json['addBorder'] as bool? ?? false,
      borderWidth: json['borderWidth'] as int? ?? 2,
      borderColor: Color(json['borderColor'] as int? ?? 0xFF000000),
    );
  }

  @override
  String toString() {
    return 'QrGenerationOptions(size: $size, errorCorrectionLevel: $errorCorrectionLevel, '
           'foregroundColor: $foregroundColor, backgroundColor: $backgroundColor)';
  }
}

/// Error correction levels for QR codes
enum ErrorCorrectionLevel {
  low('LOW'),
  medium('MEDIUM'),
  quartile('QUARTILE'),
  high('HIGH');

  const ErrorCorrectionLevel(this.name);
  
  final String name;

  static ErrorCorrectionLevel fromString(String name) {
    return ErrorCorrectionLevel.values.firstWhere(
      (level) => level.name == name,
      orElse: () => ErrorCorrectionLevel.medium,
    );
  }

  @override
  String toString() => name;
}

/// Predefined QR generation presets
class QrGenerationPresets {
  static const QrGenerationOptions standard = QrGenerationOptions();
  
  static const QrGenerationOptions highQuality = QrGenerationOptions(
    size: 1024,
    errorCorrectionLevel: ErrorCorrectionLevel.high,
    margin: 40,
  );
  
  static const QrGenerationOptions colorful = QrGenerationOptions(
    foregroundColor: Color(0xFF2196F3),
    backgroundColor: Color(0xFFF5F5F5),
    roundedCorners: true,
    cornerRadius: 6.0,
  );
  
  static const QrGenerationOptions minimal = QrGenerationOptions(
    size: 256,
    margin: 10,
    errorCorrectionLevel: ErrorCorrectionLevel.low,
  );
  
  static const QrGenerationOptions withBorder = QrGenerationOptions(
    addBorder: true,
    borderWidth: 4,
    borderColor: Color(0xFF333333),
    margin: 30,
  );
}
