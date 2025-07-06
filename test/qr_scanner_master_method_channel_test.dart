import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner_master/qr_scanner_master_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelQrScannerMaster platform = MethodChannelQrScannerMaster();
  const MethodChannel channel = MethodChannel('qr_scanner_master');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
