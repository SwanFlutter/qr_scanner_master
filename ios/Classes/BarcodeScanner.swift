import UIKit
import Vision
import AVFoundation

class BarcodeScanner {
    
    func scanFromImagePath(imagePath: String, options: ScanOptions, completion: @escaping ([ScanResult]) -> Void) {
        guard let image = UIImage(contentsOfFile: imagePath) else {
            completion([])
            return
        }
        
        scanFromImage(image: image, options: options, completion: completion)
    }
    
    func scanFromBytes(imageData: Data, options: ScanOptions, completion: @escaping ([ScanResult]) -> Void) {
        guard let image = UIImage(data: imageData) else {
            completion([])
            return
        }
        
        scanFromImage(image: image, options: options, completion: completion)
    }
    
    private func scanFromImage(image: UIImage, options: ScanOptions, completion: @escaping ([ScanResult]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        let request = VNDetectBarcodesRequest { request, error in
            guard error == nil else {
                completion([])
                return
            }
            
            let results = request.results as? [VNBarcodeObservation] ?? []
            let scanResults = results.compactMap { observation -> ScanResult? in
                return self.convertToScanResult(observation: observation, options: options)
            }
            
            completion(scanResults)
        }
        
        // Configure supported symbologies based on options
        if !options.formats.isEmpty {
            request.symbologies = options.formats.compactMap { formatName in
                self.getVisionSymbology(from: formatName)
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            completion([])
        }
    }
    
    private func convertToScanResult(observation: VNBarcodeObservation, options: ScanOptions) -> ScanResult? {
        guard let payloadString = observation.payloadStringValue else { return nil }
        
        let formatName = getFormatName(from: observation.symbology)
        
        // Check if format should be included
        if !options.formats.isEmpty && !options.formats.contains(formatName) {
            return nil
        }
        
        // Convert corner points
        let cornerPoints = [
            observation.topLeft,
            observation.topRight,
            observation.bottomRight,
            observation.bottomLeft
        ].map { point in
            ScanPoint(x: Double(point.x), y: Double(point.y))
        }
        
        // Create metadata
        let metadata = createMetadata(from: observation)
        
        return ScanResult(
            data: payloadString,
            format: formatName,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            cornerPoints: cornerPoints,
            metadata: metadata
        )
    }
    
    private func getVisionSymbology(from formatName: String) -> VNBarcodeSymbology? {
        switch formatName {
        case "QR_CODE":
            return .qr
        case "EAN_8":
            return .ean8
        case "EAN_13":
            return .ean13
        case "CODE_39":
            return .code39
        case "CODE_93":
            return .code93
        case "CODE_128":
            return .code128
        case "CODABAR":
            return .codabar
        case "ITF":
            return .itf14
        case "UPC_A":
            return .upce
        case "UPC_E":
            return .upce
        case "DATA_MATRIX":
            return .dataMatrix
        case "AZTEC":
            return .aztec
        case "PDF_417":
            return .pdf417
        default:
            return nil
        }
    }
    
    private func getFormatName(from symbology: VNBarcodeSymbology) -> String {
        switch symbology {
        case .qr:
            return "QR_CODE"
        case .ean8:
            return "EAN_8"
        case .ean13:
            return "EAN_13"
        case .code39:
            return "CODE_39"
        case .code93:
            return "CODE_93"
        case .code128:
            return "CODE_128"
        case .codabar:
            return "CODABAR"
        case .itf14:
            return "ITF"
        case .upce:
            return "UPC_E"
        case .dataMatrix:
            return "DATA_MATRIX"
        case .aztec:
            return "AZTEC"
        case .pdf417:
            return "PDF_417"
        default:
            return "UNKNOWN"
        }
    }
    
    private func createMetadata(from observation: VNBarcodeObservation) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        // Add bounding box
        let boundingBox = observation.boundingBox
        metadata["boundingBox"] = [
            "x": boundingBox.origin.x,
            "y": boundingBox.origin.y,
            "width": boundingBox.size.width,
            "height": boundingBox.size.height
        ]
        
        // Add confidence
        metadata["confidence"] = observation.confidence
        
        // Add format-specific data based on descriptor
        if let descriptor = observation.barcodeDescriptor {
            switch descriptor {
            case let qrDescriptor as CIQRCodeDescriptor:
                metadata["qrCode"] = [
                    "errorCorrectionLevel": qrDescriptor.errorCorrectionLevel.rawValue,
                    "symbolVersion": qrDescriptor.symbolVersion,
                    "maskPattern": qrDescriptor.maskPattern
                ]
                
            case let aztecDescriptor as CIAztecCodeDescriptor:
                metadata["aztecCode"] = [
                    "isCompact": aztecDescriptor.isCompact,
                    "layerCount": aztecDescriptor.layerCount,
                    "dataCodewordCount": aztecDescriptor.dataCodewordCount
                ]
                
            case let pdf417Descriptor as CIPDF417CodeDescriptor:
                metadata["pdf417"] = [
                    "isCompact": pdf417Descriptor.isCompact,
                    "rowCount": pdf417Descriptor.rowCount,
                    "columnCount": pdf417Descriptor.columnCount
                ]
                
            case let dataMatrixDescriptor as CIDataMatrixCodeDescriptor:
                metadata["dataMatrix"] = [
                    "rowCount": dataMatrixDescriptor.rowCount,
                    "columnCount": dataMatrixDescriptor.columnCount,
                    "eccVersion": dataMatrixDescriptor.eccVersion.rawValue
                ]
                
            default:
                break
            }
        }
        
        return metadata
    }
}

struct ScanOptions {
    let formats: [String]
    let enableFlash: Bool
    let autoFocus: Bool
    let multiScan: Bool
    let maxScans: Int
    let beepOnScan: Bool
    let vibrateOnScan: Bool
    let showOverlay: Bool
    let overlayColor: Int
    let restrictScanArea: Bool
    let scanAreaRatio: CGFloat
    let timeoutSeconds: Int
    let returnImage: Bool
    let imageQuality: CGFloat
    let detectInverted: Bool
    let cameraResolution: String
    let cameraFacing: String
    
    static func fromDictionary(_ dict: [String: Any]) -> ScanOptions {
        return ScanOptions(
            formats: dict["formats"] as? [String] ?? [],
            enableFlash: dict["enableFlash"] as? Bool ?? false,
            autoFocus: dict["autoFocus"] as? Bool ?? true,
            multiScan: dict["multiScan"] as? Bool ?? false,
            maxScans: dict["maxScans"] as? Int ?? 1,
            beepOnScan: dict["beepOnScan"] as? Bool ?? true,
            vibrateOnScan: dict["vibrateOnScan"] as? Bool ?? true,
            showOverlay: dict["showOverlay"] as? Bool ?? true,
            overlayColor: dict["overlayColor"] as? Int ?? 0xFF00FF00,
            restrictScanArea: dict["restrictScanArea"] as? Bool ?? false,
            scanAreaRatio: CGFloat(dict["scanAreaRatio"] as? Double ?? 0.7),
            timeoutSeconds: dict["timeoutSeconds"] as? Int ?? 0,
            returnImage: dict["returnImage"] as? Bool ?? false,
            imageQuality: CGFloat(dict["imageQuality"] as? Double ?? 0.8),
            detectInverted: dict["detectInverted"] as? Bool ?? false,
            cameraResolution: dict["cameraResolution"] as? String ?? "MEDIUM",
            cameraFacing: dict["cameraFacing"] as? String ?? "BACK"
        )
    }
}

struct ScanResult {
    let data: String
    let format: String
    let timestamp: Int64
    let cornerPoints: [ScanPoint]
    let metadata: [String: Any]
    
    func toDictionary() -> [String: Any] {
        return [
            "data": data,
            "format": format,
            "timestamp": timestamp,
            "cornerPoints": cornerPoints.map { $0.toDictionary() },
            "metadata": metadata
        ]
    }
}

struct ScanPoint {
    let x: Double
    let y: Double
    
    func toDictionary() -> [String: Any] {
        return [
            "x": x,
            "y": y
        ]
    }
}
