import ExpoModulesCore
import UIKit

public class PixelSamplerModule: Module {
  public func definition() -> ModuleDefinition {
    Name("PixelSampler")

    // Sync function for instant pixel sampling - returns hex color string
    Function("getPixelColor") { (imageUri: String, x: Double, y: Double, displayWidth: Double, displayHeight: Double) -> String in
      return getPixelColorSync(imageUri: imageUri, x: x, y: y, displayWidth: displayWidth, displayHeight: displayHeight)
    }
    
    // Async version for compatibility
    AsyncFunction("getPixelColorAsync") { (imageUri: String, x: Double, y: Double, displayWidth: Double, displayHeight: Double, promise: Promise) in
      let color = getPixelColorSync(imageUri: imageUri, x: x, y: y, displayWidth: displayWidth, displayHeight: displayHeight)
      promise.resolve(color)
    }
  }
}

// Cache for normalized images to avoid reprocessing on every sample
private var imageCache: [String: UIImage] = [:]
private let cacheQueue = DispatchQueue(label: "pixel-sampler-cache")

private func getPixelColorSync(imageUri: String, x: Double, y: Double, displayWidth: Double, displayHeight: Double) -> String {
  // Try to get cached normalized image first
  var image: UIImage?
  
  cacheQueue.sync {
    image = imageCache[imageUri]
  }
  
  // Load and normalize image if not cached
  if image == nil {
    if let loadedImage = loadImage(from: imageUri) {
      // Normalize orientation - this is crucial!
      image = normalizeImageOrientation(loadedImage)
      if let img = image {
        cacheQueue.sync {
          // Limit cache size
          if imageCache.count > 5 {
            imageCache.removeAll()
          }
          imageCache[imageUri] = img
        }
      }
    }
  }
  
  guard let uiImage = image else {
    return "#808080" // Gray fallback
  }
  
  // Convert display coordinates to image coordinates
  let imageWidth = Double(uiImage.size.width)
  let imageHeight = Double(uiImage.size.height)
  
  let scaleX = imageWidth / displayWidth
  let scaleY = imageHeight / displayHeight
  
  let imageX = Int(x * scaleX)
  let imageY = Int(y * scaleY)
  
  // Sample the pixel color
  if let color = uiImage.pixelColor(at: CGPoint(x: imageX, y: imageY)) {
    return color.hexString
  }
  
  return "#808080"
}

/// Normalize UIImage orientation by drawing it to a new context
/// This ensures CGImage pixel data matches visual orientation
private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
  // If already upright, no need to process
  if image.imageOrientation == .up {
    return image
  }
  
  // Draw into a new context with correct orientation
  UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
  image.draw(in: CGRect(origin: .zero, size: image.size))
  let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  
  return normalizedImage ?? image
}

private func loadImage(from uri: String) -> UIImage? {
  // Handle file:// URIs
  if uri.hasPrefix("file://") {
    let path = String(uri.dropFirst(7))
    return UIImage(contentsOfFile: path)
  }
  
  // Handle ph:// (Photos library) URIs
  if uri.hasPrefix("ph://") {
    // For photos library, we'd need PHAsset - return nil for now
    return nil
  }
  
  // Try as direct file path
  if FileManager.default.fileExists(atPath: uri) {
    return UIImage(contentsOfFile: uri)
  }
  
  // Try as URL
  if let url = URL(string: uri), let data = try? Data(contentsOf: url) {
    return UIImage(data: data)
  }
  
  return nil
}

// MARK: - UIImage Extension for Pixel Color

extension UIImage {
  func pixelColor(at point: CGPoint) -> UIColor? {
    guard let cgImage = self.cgImage else { return nil }
    
    let width = cgImage.width
    let height = cgImage.height
    
    // Clamp coordinates (input is in top-left origin coordinate system)
    let x = max(0, min(Int(point.x), width - 1))
    let y = max(0, min(Int(point.y), height - 1))
    
    // Create a 1x1 bitmap context to sample the pixel
    // This is more reliable than direct data access across different pixel formats
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var pixelData: [UInt8] = [0, 0, 0, 0]
    
    guard let context = CGContext(
      data: &pixelData,
      width: 1,
      height: 1,
      bitsPerComponent: 8,
      bytesPerRow: 4,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return nil
    }
    
    // CGContext has origin at bottom-left, but our y is from top-left
    // So we need to flip: draw position accounts for this
    // To get pixel at (x, y) from top, we draw the image offset so that pixel lands at (0,0)
    // Since CGContext y=0 is bottom, we need: -(height - 1 - y) = y - height + 1
    let flippedY = y - height + 1
    context.draw(cgImage, in: CGRect(x: -x, y: flippedY, width: width, height: height))
    
    // Extract RGBA values
    let r = CGFloat(pixelData[0]) / 255.0
    let g = CGFloat(pixelData[1]) / 255.0
    let b = CGFloat(pixelData[2]) / 255.0
    let a = CGFloat(pixelData[3]) / 255.0
    
    // Handle premultiplied alpha
    if a > 0 {
      return UIColor(red: r/a, green: g/a, blue: b/a, alpha: a)
    }
    
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }
}

// MARK: - UIColor Extension for Hex

extension UIColor {
  var hexString: String {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    
    getRed(&r, green: &g, blue: &b, alpha: &a)
    
    let ri = Int(max(0, min(255, r * 255)))
    let gi = Int(max(0, min(255, g * 255)))
    let bi = Int(max(0, min(255, b * 255)))
    
    return String(format: "#%02X%02X%02X", ri, gi, bi)
  }
}
