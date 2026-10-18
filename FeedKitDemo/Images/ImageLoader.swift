import UIKit

enum ImageLoaderError: Error {
    case invalidImageData
}

/// Downloads, downsamples, and caches images.
///
/// It is an `actor`, so its methods run away from the main thread and the
/// slow decoding work never makes scrolling stutter.
actor ImageLoader {

    static let shared = ImageLoader()

    private let cache: ImageCache
    private let session: URLSession

    init(cache: ImageCache = .shared, session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    /// Returns a cached image right away without waiting, or nil.
    /// `nonisolated` means callers do not have to `await` it.
    nonisolated func cachedImage(for url: URL, pointSize: CGSize, scale: CGFloat) -> UIImage? {
        cache.image(forKey: Self.cacheKey(url: url, pointSize: pointSize, scale: scale))
    }

    func image(for url: URL, pointSize: CGSize, scale: CGFloat) async throws -> UIImage {
        let key = Self.cacheKey(url: url, pointSize: pointSize, scale: scale)
        if let cached = cache.image(forKey: key) {
            return cached
        }

        let (data, _) = try await session.data(from: url)
        // The cell may have been reused while we waited. If so, skip the decode.
        try Task.checkCancellation()

        guard let image = ImageDownsampler.downsample(data, to: pointSize, scale: scale) else {
            throw ImageLoaderError.invalidImageData
        }
        cache.insert(image, forKey: key)
        return image
    }

    /// The same URL shown at two sizes is two different images, so the size is part of the key.
    private static func cacheKey(url: URL, pointSize: CGSize, scale: CGFloat) -> String {
        let width = Int(pointSize.width * scale)
        let height = Int(pointSize.height * scale)
        return "\(url.absoluteString)#\(width)x\(height)"
    }
}
