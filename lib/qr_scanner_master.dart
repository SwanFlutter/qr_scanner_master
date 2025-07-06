
import 'qr_scanner_master_platform_interface.dart';

class QrScannerMaster {
  Future<String?> getPlatformVersion() {
    return QrScannerMasterPlatform.instance.getPlatformVersion();
  }
}
