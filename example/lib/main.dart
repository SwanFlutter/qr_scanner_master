import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_scanner_master/qr_scanner_master.dart';
import 'package:qr_scanner_master_example/advanced_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner Master Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const QrScannerDemo(),
    );
  }
}

class QrScannerDemo extends StatefulWidget {
  const QrScannerDemo({super.key});

  @override
  State<QrScannerDemo> createState() => _QrScannerDemoState();
}

class _QrScannerDemoState extends State<QrScannerDemo> {
  String _platformVersion = 'Unknown';
  String _scanResult = 'No scan result yet';
  Uint8List? _generatedQrCode;
  bool _hasPermission = false;
  List<String> _supportedFormats = [];

  final _qrScannerMaster = QrScannerMaster();
  final _dataController = TextEditingController(text: 'https://flutter.dev');

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    await _getPlatformVersion();
    await _checkPermissions();
    await _getSupportedFormats();
  }

  Future<void> _getPlatformVersion() async {
    try {
      final version =
          await _qrScannerMaster.getPlatformVersion() ??
          'Unknown platform version';
      setState(() {
        _platformVersion = version;
      });
    } on PlatformException {
      setState(() {
        _platformVersion = 'Failed to get platform version.';
      });
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final hasPermission = await _qrScannerMaster.hasCameraPermission();
      setState(() {
        _hasPermission = hasPermission;
      });
    } catch (e) {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final granted = await _qrScannerMaster.requestCameraPermission();
      setState(() {
        _hasPermission = granted;
      });

      if (!granted) {
        _showSnackBar('Camera permission denied');
      }
    } catch (e) {
      _showSnackBar('Error requesting permission: $e');
    }
  }

  Future<void> _getSupportedFormats() async {
    try {
      final formats = await _qrScannerMaster.getSupportedFormats();
      setState(() {
        _supportedFormats = formats;
      });
    } catch (e) {
      setState(() {
        _supportedFormats = [];
      });
    }
  }

  Future<void> _scanQrCode() async {
    if (!_hasPermission) {
      await _requestPermissions();
      if (!_hasPermission) return;
    }

    try {
      final result = await _qrScannerMaster.scanWithCamera(
        ScanOptions(
          formats: [BarcodeFormat.qrCode],
          enableFlash: false,
          showOverlay: true,
          beepOnScan: true,
          vibrateOnScan: true,
        ),
      );

      if (result != null) {
        setState(() {
          _scanResult =
              'Data: ${result.data}\nFormat: ${result.format}\nTimestamp: ${DateTime.fromMillisecondsSinceEpoch(result.timestamp.millisecondsSinceEpoch)}';
        });
      } else {
        setState(() {
          _scanResult = 'Scan cancelled or failed';
        });
      }
    } on QrScannerException catch (e) {
      _showSnackBar('Scan error: ${e.message}');
    } catch (e) {
      _showSnackBar('Unexpected error: $e');
    }
  }

  Future<void> _generateQrCode() async {
    if (_dataController.text.isEmpty) {
      _showSnackBar('Please enter data to generate QR code');
      return;
    }

    try {
      final qrBytes = await _qrScannerMaster.generateQrCode(
        _dataController.text,
        const QrGenerationOptions(
          size: 512,
          foregroundColor: Color(0xFF000000),
          backgroundColor: Color(0xFFFFFFFF),
          errorCorrectionLevel: ErrorCorrectionLevel.medium,
          margin: 20,
        ),
      );

      setState(() {
        _generatedQrCode = qrBytes;
      });
    } on QrScannerException catch (e) {
      _showSnackBar('Generation error: ${e.message}');
    } catch (e) {
      _showSnackBar('Unexpected error: $e');
    }
  }

  Future<void> _generateColorfulQrCode() async {
    if (_dataController.text.isEmpty) {
      _showSnackBar('Please enter data to generate QR code');
      return;
    }

    try {
      final qrBytes = await _qrScannerMaster.generateColorful(
        _dataController.text,
      );
      setState(() {
        _generatedQrCode = qrBytes;
      });
    } catch (e) {
      _showSnackBar('Generation error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner Master Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Platform Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Running on: $_platformVersion'),
                    Text(
                      'Camera Permission: ${_hasPermission ? "Granted" : "Not Granted"}',
                    ),
                    Text('Supported Formats: ${_supportedFormats.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scanning Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Scanning',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _scanQrCode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR Code'),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _scanResult,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Generation Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Generation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _dataController,
                      decoration: const InputDecoration(
                        labelText: 'Data to encode',
                        border: OutlineInputBorder(),
                        hintText: 'Enter text, URL, or any data',
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generateQrCode,
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Generate QR'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generateColorfulQrCode,
                            icon: const Icon(Icons.palette),
                            label: const Text('Colorful QR'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_generatedQrCode != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            _generatedQrCode!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdvancedQrExample()),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }
}
