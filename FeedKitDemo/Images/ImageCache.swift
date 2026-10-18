import UIKit

/// A small memory cache for decoded images.
///
/// NSCache works like a dictionary, but it throws entries away by itself
/// when it goes over its limits or when the system runs low on memory.
// NSCache is safe to use from any thread, which is why the compiler can be
// told this class is Sendable even though it cannot check that itself.
final class ImageCache: @unchecked Sendable {

    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    init(countLimit: Int = 300, totalCostLimit: Int = 100 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.memoryCost)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}

private extension UIImage {
    /// Roughly how many bytes the decoded pixels take up: width × height × 4 (RGBA).
    var memoryCost: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
