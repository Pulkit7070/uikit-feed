import ImageIO
import UIKit

enum ImageDownsampler {

    /// Decodes `data` straight into a small image that fits `pointSize`.
    ///
    /// A 5000 × 3333 photo takes about 66 MB once decoded, even if it is shown
    /// in a 350-point card. Creating a thumbnail with ImageIO decodes only the
    /// pixels we need, so the full-size bitmap never exists in memory.
    static func downsample(_ data: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        // Do not decode yet; we only want to read the file's header here.
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let maxPixelSize = max(pointSize.width, pointSize.height) * scale
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
