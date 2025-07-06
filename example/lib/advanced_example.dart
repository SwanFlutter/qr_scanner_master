// ignore_for_file: unused_import

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_scanner_master/qr_scanner_master.dart';
import 'package:qr_scanner_master_example/simple_example.dart';

/// Advanced example demonstrating comprehensive QR Scanner Master features
class AdvancedQrExample extends StatefulWidget {
  const AdvancedQrExample({super.key});

  @override
  State<AdvancedQrExample> createState() => _AdvancedQrExampleState();
}

class _AdvancedQrExampleState extends State<AdvancedQrExample> {
  final _qrScanner = QrScannerMaster();
  final _dataController = TextEditingController(text: 'https://flutter.dev');

  final List<QrScanResult> _scanResults = [];
  Uint8List? _generatedQr;
  bool _isScanning = false;
  bool _hasPermission = false;
  List<String> _supportedFormats = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _getSupportedFormats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced QR Example'),
        actions: [
          IconButton(icon: const Icon(Icons.info), onPressed: _showInfo),
          IconButton(
            icon: const Icon(Icons.toggle_off_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SimpleQrExample()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPermissionSection(),
            const SizedBox(height: 16),
            _buildScanningSection(),
            const SizedBox(height: 16),
            _buildGenerationSection(),
            const SizedBox(height: 16),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permissions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _hasPermission ? Icons.check_circle : Icons.error,
                  color: _hasPermission ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text('Camera: ${_hasPermission ? "Granted" : "Not Granted"}'),
                const Spacer(),
                if (!_hasPermission)
                  ElevatedButton(
                    onPressed: _requestPermissions,
                    child: const Text('Request'),
                  ),
              ],
            ),
            Text('Supported Formats: ${_supportedFormats.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Scanning',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _hasPermission ? _scanQrOnly : null,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('QR Only'),
                ),
                ElevatedButton.icon(
                  onPressed: _hasPermission ? _scanAllFormats : null,
                  icon: const Icon(Icons.scanner),
                  label: const Text('All Formats'),
                ),
                ElevatedButton.icon(
                  onPressed: _hasPermission ? _multiScan : null,
                  icon: const Icon(Icons.view_list),
                  label: const Text('Multi Scan'),
                ),
                ElevatedButton.icon(
                  onPressed: _hasPermission ? _scanFromImage : null,
                  icon: const Icon(Icons.image),
                  label: const Text('From Image'),
                ),
              ],
            ),

            if (_isScanning)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Generation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _dataController,
              decoration: const InputDecoration(
                labelText: 'Data to encode',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _generateStandard,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Standard'),
                ),
                ElevatedButton.icon(
                  onPressed: _generateColorful,
                  icon: const Icon(Icons.palette),
                  label: const Text('Colorful'),
                ),
                ElevatedButton.icon(
                  onPressed: _generateHighQuality,
                  icon: const Icon(Icons.high_quality),
                  label: const Text('High Quality'),
                ),
                ElevatedButton.icon(
                  onPressed: _generateWithLogo,
                  icon: const Icon(Icons.image),
                  label: const Text('With Logo'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_generatedQr != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.memory(
                    _generatedQr!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Scan Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (_scanResults.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _scanResults.clear()),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_scanResults.isEmpty)
              const Text('No scan results yet')
            else
              ...(_scanResults.map(
                (result) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(result.data),
                    subtitle: Text(
                      '${result.format} • ${DateTime.fromMillisecondsSinceEpoch(result.timestamp.millisecondsSinceEpoch)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(result.data),
                    ),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _qrScanner.hasCameraPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await _qrScanner.requestCameraPermission();
    setState(() {
      _hasPermission = granted;
    });
  }

  Future<void> _getSupportedFormats() async {
    final formats = await _qrScanner.getSupportedFormats();
    setState(() {
      _supportedFormats = formats;
    });
  }

  Future<void> _scanQrOnly() async {
    setState(() => _isScanning = true);
    try {
      final result = await _qrScanner.scanWithCamera(ScanPresets.qrOnly);
      if (result != null) {
        setState(() {
          _scanResults.insert(0, result);
        });
      }
    } catch (e) {
      _showError('Scan error: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _scanAllFormats() async {
    setState(() => _isScanning = true);
    try {
      final result = await _qrScanner.scanWithCamera(ScanPresets.allFormats);
      if (result != null) {
        setState(() {
          _scanResults.insert(0, result);
        });
      }
    } catch (e) {
      _showError('Scan error: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _multiScan() async {
    setState(() => _isScanning = true);
    try {
      final results = await _qrScanner.multiScan(maxScans: 5);
      setState(() {
        _scanResults.insertAll(0, results);
      });
    } catch (e) {
      _showError('Multi-scan error: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _scanFromImage() async {
    // This would typically use image_picker to select an image
    _showError('Image scanning requires image_picker package');
  }

  Future<void> _generateStandard() async {
    if (_dataController.text.isEmpty) return;

    try {
      final qrBytes = await _qrScanner.generateQrCode(
        _dataController.text,
        QrGenerationPresets.standard,
      );
      setState(() {
        _generatedQr = qrBytes;
      });
    } catch (e) {
      _showError('Generation error: $e');
    }
  }

  Future<void> _generateColorful() async {
    if (_dataController.text.isEmpty) return;

    try {
      final qrBytes = await _qrScanner.generateColorful(_dataController.text);
      setState(() {
        _generatedQr = qrBytes;
      });
    } catch (e) {
      _showError('Generation error: $e');
    }
  }

  Future<void> _generateHighQuality() async {
    if (_dataController.text.isEmpty) return;

    try {
      final qrBytes = await _qrScanner.generatePrintQuality(
        _dataController.text,
      );
      setState(() {
        _generatedQr = qrBytes;
      });
    } catch (e) {
      _showError('Generation error: $e');
    }
  }

  Future<void> _generateWithLogo() async {
    if (_dataController.text.isEmpty) return;

    try {
      // This would typically load a logo image
      final qrBytes = await _qrScanner.generateQrCode(
        _dataController.text,
        const QrGenerationOptions(
          size: 512,
          errorCorrectionLevel: ErrorCorrectionLevel.high,
          // logoData would be provided here
        ),
      );
      setState(() {
        _generatedQr = qrBytes;
      });
    } catch (e) {
      _showError('Generation error: $e');
    }
  }

  void _copyToClipboard(String text) {
    // Would use Clipboard.setData in a real app
    _showError('Copy functionality requires clipboard access');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Scanner Master'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supported Formats: ${_supportedFormats.length}'),
            const SizedBox(height: 8),
            Text('Formats: ${_supportedFormats.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }
}
