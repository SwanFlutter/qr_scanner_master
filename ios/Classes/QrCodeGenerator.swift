import UIKit
import CoreImage

class QrCodeGenerator {
    
    func generateQrCode(data: String, options: GenerationOptions) -> Data? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        
        let data = data.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // Set error correction level
        let correctionLevel: String
        switch options.errorCorrectionLevel {
        case "LOW":
            correctionLevel = "L"
        case "MEDIUM":
            correctionLevel = "M"
        case "QUARTILE":
            correctionLevel = "Q"
        case "HIGH":
            correctionLevel = "H"
        default:
            correctionLevel = "M"
        }
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Scale the image to desired size
        let scaleX = CGFloat(options.size) / outputImage.extent.width
        let scaleY = CGFloat(options.size) / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Create bitmap context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: options.size,
            height: options.size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        // Fill background
        context.setFillColor(UIColor(rgb: options.backgroundColor).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: options.size, height: options.size))
        
        // Create CI context and render
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        // Apply foreground color
        context.setBlendMode(.multiply)
        context.setFillColor(UIColor(rgb: options.foregroundColor).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: options.size, height: options.size))
        
        context.setBlendMode(.destinationIn)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: options.size, height: options.size))
        
        guard var finalImage = context.makeImage() else { return nil }
        
        // Apply styling
        var styledImage = UIImage(cgImage: finalImage)
        
        if !options.gradientColors.isEmpty {
            styledImage = applyGradient(to: styledImage, options: options) ?? styledImage
        }
        
        if options.roundedCorners {
            styledImage = applyRoundedCorners(to: styledImage, radius: options.cornerRadius) ?? styledImage
        }
        
        if let logoData = options.logoData {
            styledImage = embedLogo(in: styledImage, logoData: logoData, sizeRatio: options.logoSizeRatio) ?? styledImage
        }
        
        if options.addBorder {
            styledImage = addBorder(to: styledImage, width: options.borderWidth, color: UIColor(rgb: options.borderColor)) ?? styledImage
        }
        
        return styledImage.pngData()
    }
    
    private func applyGradient(to image: UIImage, options: GenerationOptions) -> UIImage? {
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Create gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = options.gradientColors.map { UIColor(rgb: $0).cgColor }
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil) else { return nil }
        
        // Determine gradient direction
        let startPoint: CGPoint
        let endPoint: CGPoint
        
        if options.gradientDirection <= 0.25 {
            // Horizontal
            startPoint = CGPoint(x: 0, y: size.height / 2)
            endPoint = CGPoint(x: size.width, y: size.height / 2)
        } else if options.gradientDirection <= 0.75 {
            // Diagonal
            startPoint = CGPoint(x: 0, y: 0)
            endPoint = CGPoint(x: size.width, y: size.height)
        } else {
            // Vertical
            startPoint = CGPoint(x: size.width / 2, y: 0)
            endPoint = CGPoint(x: size.width / 2, y: size.height)
        }
        
        // Draw original image as mask
        image.draw(at: .zero)
        
        // Apply gradient with mask
        context.setBlendMode(.sourceIn)
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func applyRoundedCorners(to image: UIImage, radius: CGFloat) -> UIImage? {
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        path.addClip()
        
        image.draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func embedLogo(in image: UIImage, logoData: Data, sizeRatio: CGFloat) -> UIImage? {
        guard let logoImage = UIImage(data: logoData) else { return image }
        
        let size = image.size
        let logoSize = CGSize(width: size.width * sizeRatio, height: size.height * sizeRatio)
        
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw original QR code
        image.draw(at: .zero)
        
        // Draw white background for logo
        let logoRect = CGRect(
            x: (size.width - logoSize.width) / 2,
            y: (size.height - logoSize.height) / 2,
            width: logoSize.width,
            height: logoSize.height
        )
        
        let backgroundRect = logoRect.insetBy(dx: -10, dy: -10)
        let backgroundPath = UIBezierPath(ovalIn: backgroundRect)
        UIColor.white.setFill()
        backgroundPath.fill()
        
        // Draw logo
        logoImage.draw(in: logoRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func addBorder(to image: UIImage, width: Int, color: UIColor) -> UIImage? {
        let borderWidth = CGFloat(width)
        let newSize = CGSize(
            width: image.size.width + (borderWidth * 2),
            height: image.size.height + (borderWidth * 2)
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Fill with border color
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: newSize))
        
        // Draw original image in center
        let imageRect = CGRect(
            x: borderWidth,
            y: borderWidth,
            width: image.size.width,
            height: image.size.height
        )
        image.draw(in: imageRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

struct GenerationOptions {
    let size: Int
    let errorCorrectionLevel: String
    let foregroundColor: Int
    let backgroundColor: Int
    let margin: Int
    let logoData: Data?
    let logoSizeRatio: CGFloat
    let roundedCorners: Bool
    let cornerRadius: CGFloat
    let gradientColors: [Int]
    let gradientDirection: CGFloat
    let addBorder: Bool
    let borderWidth: Int
    let borderColor: Int
    
    static func fromDictionary(_ dict: [String: Any]) -> GenerationOptions {
        return GenerationOptions(
            size: dict["size"] as? Int ?? 512,
            errorCorrectionLevel: dict["errorCorrectionLevel"] as? String ?? "MEDIUM",
            foregroundColor: dict["foregroundColor"] as? Int ?? 0xFF000000,
            backgroundColor: dict["backgroundColor"] as? Int ?? 0xFFFFFFFF,
            margin: dict["margin"] as? Int ?? 20,
            logoData: (dict["logoData"] as? FlutterStandardTypedData)?.data,
            logoSizeRatio: CGFloat(dict["logoSizeRatio"] as? Double ?? 0.2),
            roundedCorners: dict["roundedCorners"] as? Bool ?? false,
            cornerRadius: CGFloat(dict["cornerRadius"] as? Double ?? 4.0),
            gradientColors: dict["gradientColors"] as? [Int] ?? [],
            gradientDirection: CGFloat(dict["gradientDirection"] as? Double ?? 0.0),
            addBorder: dict["addBorder"] as? Bool ?? false,
            borderWidth: dict["borderWidth"] as? Int ?? 2,
            borderColor: dict["borderColor"] as? Int ?? 0xFF000000
        )
    }
}

extension UIColor {
    convenience init(rgb: Int) {
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        let alpha = CGFloat((rgb >> 24) & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
