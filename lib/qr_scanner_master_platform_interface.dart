import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
