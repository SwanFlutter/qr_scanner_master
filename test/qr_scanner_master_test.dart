import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner_master/qr_scanner_master.dart';
import 'package:qr_scanner_master/qr_scanner_master_platform_interface.dart';
import 'package:qr_scanner_master/qr_scanner_master_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockQrScannerMasterPlatform
    with MockPlatformInterfaceMixin
    implements QrScannerMasterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final QrScannerMasterPlatform initialPlatform = QrScannerMasterPlatform.instance;

  test('$MethodChannelQrScannerMaster is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQrScannerMaster>());
  });

  test('getPlatformVersion', () async {
    QrScannerMaster qrScannerMasterPlugin = QrScannerMaster();
    MockQrScannerMasterPlatform fakePlatform = MockQrScannerMasterPlatform();
    QrScannerMasterPlatform.instance = fakePlatform;

    expect(await qrScannerMasterPlugin.getPlatformVersion(), '42');
  });
}
