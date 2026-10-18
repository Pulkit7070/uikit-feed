import XCTest
@testable import FeedKitDemo

final class ImageCacheTests: XCTestCase {

    private func makeImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    func testReturnsTheSameImageThatWasInserted() {
        let cache = ImageCache()
        let image = makeImage(width: 10, height: 10)

        cache.insert(image, forKey: "a")

        XCTAssertIdentical(cache.image(forKey: "a"), image)
    }

    func testReturnsNilForAnUnknownKey() {
        let cache = ImageCache()
        cache.insert(makeImage(width: 10, height: 10), forKey: "a")

        XCTAssertNil(cache.image(forKey: "b"))
    }

    func testRemoveAllEmptiesTheCache() {
        let cache = ImageCache()
        cache.insert(makeImage(width: 10, height: 10), forKey: "a")

        cache.removeAll()

        XCTAssertNil(cache.image(forKey: "a"))
    }

    func testDownsamplingShrinksTheImageToTheRequestedSize() throws {
        let data = try XCTUnwrap(makeImage(width: 2000, height: 1000).pngData())

        let image = try XCTUnwrap(ImageDownsampler.downsample(data, to: CGSize(width: 100, height: 50), scale: 2))

        // 100 × 50 points at 2x is 200 × 100 pixels, down from 2000 × 1000.
        XCTAssertEqual(image.cgImage?.width, 200)
        XCTAssertEqual(image.cgImage?.height, 100)
        XCTAssertEqual(image.size, CGSize(width: 100, height: 50))
    }
}
