import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'qr_scanner_master_platform_interface.dart';

/// An implementation of [QrScannerMasterPlatform] that uses method channels.
class MethodChannelQrScannerMaster extends QrScannerMasterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('qr_scanner_master');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
