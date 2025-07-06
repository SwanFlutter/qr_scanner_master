import UIKit
import AVFoundation
import Vision
import AudioToolbox

class CameraManager: NSObject {
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice: AVCaptureDevice?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var isScanning = false
    private var isPaused = false
    private var currentOptions: ScanOptions?
    private var scanCallback: ((ScanResult?) -> Unit)?
    private var scannedCodes = Set<String>()
    private var scanCount = 0
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    func startScanning(options: ScanOptions, completion: @escaping (ScanResult?) -> Void) {
        currentOptions = options
        scanCallback = completion
        isScanning = true
        isPaused = false
        scannedCodes.removeAll()
        scanCount = 0
        
        sessionQueue.async { [weak self] in
            self?.setupCameraSession(options: options)
        }
    }
    
    func pauseScanning() {
        isPaused = true
    }
    
    func resumeScanning() {
        isPaused = false
    }
    
    func stopScanning() {
        isScanning = false
        isPaused = false
        scanCallback = nil
        currentOptions = nil
        scannedCodes.removeAll()
        scanCount = 0
        
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.captureSession = nil
            self?.videoPreviewLayer = nil
            self?.captureDevice = nil
            self?.videoOutput = nil
        }
    }
    
    func toggleFlash(enable: Bool) {
        guard let device = captureDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = enable ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // Handle error silently
        }
    }
    
    private func setupCameraSession(options: ScanOptions) {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        // Configure session preset based on resolution
        switch options.cameraResolution {
        case "LOW":
            captureSession.sessionPreset = .vga640x480
        case "MEDIUM":
            captureSession.sessionPreset = .hd1280x720
        case "HIGH":
            captureSession.sessionPreset = .hd1920x1080
        case "VERY_HIGH":
            captureSession.sessionPreset = .hd4K3840x2160
        default:
            captureSession.sessionPreset = .hd1280x720
        }
        
        // Setup camera input
        let devicePosition: AVCaptureDevice.Position = options.cameraFacing == "FRONT" ? .front : .back
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) else {
            DispatchQueue.main.async { [weak self] in
                self?.scanCallback?(nil)
            }
            return
        }
        
        captureDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.scanCallback?(nil)
            }
            return
        }
        
        // Setup video output
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Configure camera settings
        configureCameraSettings(device: device, options: options)
        
        // Start session
        captureSession.startRunning()
    }
    
    private func configureCameraSettings(device: AVCaptureDevice, options: ScanOptions) {
        do {
            try device.lockForConfiguration()
            
            // Auto focus
            if options.autoFocus && device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // Flash/Torch
            if options.enableFlash && device.hasTorch {
                device.torchMode = .on
            }
            
            // Exposure
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
        } catch {
            // Handle configuration error silently
        }
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer, options: ScanOptions) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self, error == nil else { return }
            
            let results = request.results as? [VNBarcodeObservation] ?? []
            self.processBarcodeResults(results, options: options)
        }
        
        // Configure supported symbologies
        if !options.formats.isEmpty {
            request.symbologies = options.formats.compactMap { formatName in
                self.getVisionSymbology(from: formatName)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            // Handle error silently
        }
    }
    
    private func processBarcodeResults(_ results: [VNBarcodeObservation], options: ScanOptions) {
        guard isScanning && !isPaused else { return }
        
        for observation in results {
            guard let payloadString = observation.payloadStringValue else { continue }
            
            let formatName = getFormatName(from: observation.symbology)
            
            // Check if format is allowed
            if !options.formats.isEmpty && !options.formats.contains(formatName) {
                continue
            }
            
            // Check for duplicates in multi-scan mode
            if options.multiScan && scannedCodes.contains(payloadString) {
                continue
            }
            
            // Convert to scan result
            let scanResult = convertToScanResult(observation: observation)
            
            // Handle scan feedback
            if options.beepOnScan {
                playBeepSound()
            }
            
            if options.vibrateOnScan {
                vibrate()
            }
            
            if options.multiScan {
                scannedCodes.insert(payloadString)
                scanCount += 1
                
                // Check if we've reached max scans
                if options.maxScans > 0 && scanCount >= options.maxScans {
                    isScanning = false
                    DispatchQueue.main.async { [weak self] in
                        self?.scanCallback?(scanResult)
                    }
                    return
                }
            } else {
                // Single scan mode - stop after first result
                isScanning = false
                DispatchQueue.main.async { [weak self] in
                    self?.scanCallback?(scanResult)
                }
                return
            }
        }
    }
    
    private func convertToScanResult(observation: VNBarcodeObservation) -> ScanResult {
        let cornerPoints = [
            observation.topLeft,
            observation.topRight,
            observation.bottomRight,
            observation.bottomLeft
        ].map { point in
            ScanPoint(x: Double(point.x), y: Double(point.y))
        }
        
        return ScanResult(
            data: observation.payloadStringValue ?? "",
            format: getFormatName(from: observation.symbology),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            cornerPoints: cornerPoints,
            metadata: [:]
        )
    }
    
    private func getVisionSymbology(from formatName: String) -> VNBarcodeSymbology? {
        switch formatName {
        case "QR_CODE": return .qr
        case "EAN_8": return .ean8
        case "EAN_13": return .ean13
        case "CODE_39": return .code39
        case "CODE_93": return .code93
        case "CODE_128": return .code128
        case "CODABAR": return .codabar
        case "ITF": return .itf14
        case "UPC_A": return .upce
        case "UPC_E": return .upce
        case "DATA_MATRIX": return .dataMatrix
        case "AZTEC": return .aztec
        case "PDF_417": return .pdf417
        default: return nil
        }
    }
    
    private func getFormatName(from symbology: VNBarcodeSymbology) -> String {
        switch symbology {
        case .qr: return "QR_CODE"
        case .ean8: return "EAN_8"
        case .ean13: return "EAN_13"
        case .code39: return "CODE_39"
        case .code93: return "CODE_93"
        case .code128: return "CODE_128"
        case .codabar: return "CODABAR"
        case .itf14: return "ITF"
        case .upce: return "UPC_E"
        case .dataMatrix: return "DATA_MATRIX"
        case .aztec: return "AZTEC"
        case .pdf417: return "PDF_417"
        default: return "UNKNOWN"
        }
    }
    
    private func playBeepSound() {
        AudioServicesPlaySystemSound(SystemSoundID(1016)) // Camera shutter sound
    }
    
    private func vibrate() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let options = currentOptions else { return }
        processVideoFrame(sampleBuffer, options: options)
    }
}
