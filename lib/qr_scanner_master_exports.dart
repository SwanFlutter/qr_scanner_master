// Main plugin exports
export 'qr_scanner_master.dart';
export 'qr_scanner_master_platform_interface.dart';
export 'qr_scanner_master_method_channel.dart';

// Model exports
export 'models/qr_scan_result.dart';
export 'models/qr_generation_options.dart';
export 'models/scan_options.dart';

// Re-export commonly used types for convenience
export 'dart:typed_data' show Uint8List;
export 'dart:io' show File;
