import UIKit
import AVFoundation
import Photos

class PermissionManager {
    
    func hasCameraPermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    func hasPhotoLibraryPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            completion(true)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
    
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            completion(true)
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized)
                }
            }
            
        case .denied, .restricted:
            completion(false)
            
        case .limited:
            completion(true) // Limited access is still usable
            
        @unknown default:
            completion(false)
        }
    }
    
    func requestAllPermissions(completion: @escaping (PermissionStatus) -> Void) {
        requestCameraPermission { [weak self] cameraGranted in
            self?.requestPhotoLibraryPermission { photoGranted in
                let status = PermissionStatus(
                    camera: cameraGranted,
                    photoLibrary: photoGranted
                )
                completion(status)
            }
        }
    }
    
    func getPermissionStatus() -> PermissionStatus {
        return PermissionStatus(
            camera: hasCameraPermission(),
            photoLibrary: hasPhotoLibraryPermission()
        )
    }
    
    func shouldShowPermissionAlert(for permission: PermissionType) -> Bool {
        switch permission {
        case .camera:
            return AVCaptureDevice.authorizationStatus(for: .video) == .denied
        case .photoLibrary:
            return PHPhotoLibrary.authorizationStatus() == .denied
        }
    }
    
    func showPermissionAlert(for permission: PermissionType, from viewController: UIViewController) {
        let title: String
        let message: String
        
        switch permission {
        case .camera:
            title = "Camera Permission Required"
            message = "This app needs camera access to scan QR codes and barcodes. Please enable camera permission in Settings."
            
        case .photoLibrary:
            title = "Photo Library Permission Required"
            message = "This app needs photo library access to scan QR codes from images. Please enable photo library permission in Settings."
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        viewController.present(alert, animated: true)
    }
    
    func getPermissionExplanation(for permission: PermissionType) -> String {
        switch permission {
        case .camera:
            return "Camera permission is required to scan QR codes and barcodes using the device camera. This allows the app to access your camera to detect and decode various types of codes in real-time."
            
        case .photoLibrary:
            return "Photo library permission is required to scan QR codes from existing images in your photo library. This allows the app to analyze images you select to find and decode QR codes or barcodes."
        }
    }
    
    func checkAndRequestPermission(for permission: PermissionType, from viewController: UIViewController?, completion: @escaping (Bool) -> Void) {
        switch permission {
        case .camera:
            if hasCameraPermission() {
                completion(true)
            } else if shouldShowPermissionAlert(for: .camera) {
                if let vc = viewController {
                    showPermissionAlert(for: .camera, from: vc)
                }
                completion(false)
            } else {
                requestCameraPermission(completion: completion)
            }
            
        case .photoLibrary:
            if hasPhotoLibraryPermission() {
                completion(true)
            } else if shouldShowPermissionAlert(for: .photoLibrary) {
                if let vc = viewController {
                    showPermissionAlert(for: .photoLibrary, from: vc)
                }
                completion(false)
            } else {
                requestPhotoLibraryPermission(completion: completion)
            }
        }
    }
}

enum PermissionType {
    case camera
    case photoLibrary
}

struct PermissionStatus {
    let camera: Bool
    let photoLibrary: Bool
    
    var allGranted: Bool {
        return camera && photoLibrary
    }
    
    var hasRequiredPermissions: Bool {
        return camera // Camera is the minimum required permission
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "camera": camera,
            "photoLibrary": photoLibrary,
            "allGranted": allGranted,
            "hasRequiredPermissions": hasRequiredPermissions
        ]
    }
}
