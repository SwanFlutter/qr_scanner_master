import Flutter
import UIKit
import AVFoundation
import Vision
import CoreImage

public class QrScannerMasterPlugin: NSObject, FlutterPlugin {

    private var qrCodeGenerator: QrCodeGenerator?
    private var barcodeScanner: BarcodeScanner?
    private var cameraManager: CameraManager?
    private var permissionManager: PermissionManager?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "qr_scanner_master", binaryMessenger: registrar.messenger())
        let instance = QrScannerMasterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public override init() {
        super.init()
        setupComponents()
    }

    private func setupComponents() {
        qrCodeGenerator = QrCodeGenerator()
        barcodeScanner = BarcodeScanner()
        cameraManager = CameraManager()
        permissionManager = PermissionManager()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "scanWithCamera":
            handleScanWithCamera(call: call, result: result)

        case "scanFromImage":
            handleScanFromImage(call: call, result: result)

        case "scanFromBytes":
            handleScanFromBytes(call: call, result: result)

        case "generateQrCode":
            handleGenerateQrCode(call: call, result: result)

        case "hasCameraPermission":
            result(permissionManager?.hasCameraPermission() ?? false)

        case "requestCameraPermission":
            handleRequestCameraPermission(result: result)

        case "getAvailableCameras":
            handleGetAvailableCameras(result: result)

        case "hasFlash":
            result(hasFlash())

        case "toggleFlash":
            handleToggleFlash(call: call, result: result)

        case "getSupportedFormats":
            result(getSupportedFormats())

        case "pauseScanner":
            handlePauseScanner(result: result)

        case "resumeScanner":
            handleResumeScanner(result: result)

        case "stopScanner":
            handleStopScanner(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleScanWithCamera(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let permissionManager = permissionManager else {
            result(FlutterError(code: "INITIALIZATION_ERROR", message: "Permission manager not initialized", details: nil))
            return
        }

        if !permissionManager.hasCameraPermission() {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission is required", details: nil))
            return
        }

        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments provided", details: nil))
            return
        }

        let options = ScanOptions.fromDictionary(arguments)

        cameraManager?.startScanning(options: options) { [weak self] scanResult in
            DispatchQueue.main.async {
                if let scanResult = scanResult {
                    result(scanResult.toDictionary())
                } else {
                    result(nil)
                }
            }
        }
    }

    private func handleScanFromImage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let imagePath = arguments["imagePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image path is required", details: nil))
            return
        }

        let options = ScanOptions.fromDictionary(arguments)

        barcodeScanner?.scanFromImagePath(imagePath: imagePath, options: options) { scanResults in
            DispatchQueue.main.async {
                let resultDictionaries = scanResults.map { $0.toDictionary() }
                result(resultDictionaries)
            }
        }
    }

    private func handleScanFromBytes(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let imageData = arguments["imageBytes"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image bytes are required", details: nil))
            return
        }

        let options = ScanOptions.fromDictionary(arguments)

        barcodeScanner?.scanFromBytes(imageData: imageData.data, options: options) { scanResults in
            DispatchQueue.main.async {
                let resultDictionaries = scanResults.map { $0.toDictionary() }
                result(resultDictionaries)
            }
        }
    }

    private func handleGenerateQrCode(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let data = arguments["data"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Data is required for QR code generation", details: nil))
            return
        }

        let options = GenerationOptions.fromDictionary(arguments)

        if let qrImageData = qrCodeGenerator?.generateQrCode(data: data, options: options) {
            result(FlutterStandardTypedData(bytes: qrImageData))
        } else {
            result(FlutterError(code: "GENERATION_FAILED", message: "Failed to generate QR code", details: nil))
        }
    }

    private func handleRequestCameraPermission(result: @escaping FlutterResult) {
        permissionManager?.requestCameraPermission { granted in
            DispatchQueue.main.async {
                result(granted)
            }
        }
    }

    private func handleGetAvailableCameras(result: @escaping FlutterResult) {
        let cameras = getAvailableCameras()
        result(cameras)
    }

    private func handleToggleFlash(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let enable = arguments["enable"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Enable parameter is required", details: nil))
            return
        }

        cameraManager?.toggleFlash(enable: enable)
        result(nil)
    }

    private func handlePauseScanner(result: @escaping FlutterResult) {
        cameraManager?.pauseScanning()
        result(nil)
    }

    private func handleResumeScanner(result: @escaping FlutterResult) {
        cameraManager?.resumeScanning()
        result(nil)
    }

    private func handleStopScanner(result: @escaping FlutterResult) {
        cameraManager?.stopScanning()
        result(nil)
    }

    private func hasFlash() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.hasTorch
    }

    private func getAvailableCameras() -> [String] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .unspecified
        )

        return discoverySession.devices.map { device in
            switch device.position {
            case .front:
                return "front"
            case .back:
                return "back"
            default:
                return "unknown"
            }
        }
    }

    private func getSupportedFormats() -> [String] {
        return [
            "QR_CODE", "EAN_8", "EAN_13", "CODE_39", "CODE_93", "CODE_128",
            "CODABAR", "ITF", "UPC_A", "UPC_E", "DATA_MATRIX", "AZTEC", "PDF_417"
        ]
    }
}
