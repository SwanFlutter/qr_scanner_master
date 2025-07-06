// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_scanner_master/qr_scanner_master.dart';

/// Simple example demonstrating basic QR Scanner Master usage
class SimpleQrExample extends StatefulWidget {
  const SimpleQrExample({super.key});

  @override
  State<SimpleQrExample> createState() => _SimpleQrExampleState();
}

class _SimpleQrExampleState extends State<SimpleQrExample> {
  final _qrScanner = QrScannerMaster();
  String _scanResult = 'No scan result yet';
  Uint8List? _generatedQr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple QR Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scan Section
            ElevatedButton.icon(
              onPressed: _scanQrCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_scanResult),
            ),

            const SizedBox(height: 32),

            // Generate Section
            ElevatedButton.icon(
              onPressed: _generateQrCode,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
            ),

            const SizedBox(height: 16),

            if (_generatedQr != null)
              Center(
                child: Image.memory(_generatedQr!, width: 200, height: 200),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanQrCode() async {
    try {
      // Simple scan with default options
      final result = await _qrScanner.quickScan();

      setState(() {
        _scanResult = result ?? 'Scan cancelled';
      });
    } catch (e) {
      setState(() {
        _scanResult = 'Error: $e';
      });
    }
  }

  Future<void> _generateQrCode() async {
    try {
      // Simple generation with default options
      final qrBytes = await _qrScanner.quickGenerate(
        'Hello from QR Scanner Master!',
      );

      setState(() {
        _generatedQr = qrBytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Generation error: $e')));
    }
  }
}
