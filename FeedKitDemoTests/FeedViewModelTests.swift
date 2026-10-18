import XCTest
@testable import FeedKitDemo

/// A stand-in for APIClient. It returns prepared responses in order
/// and records which pages were asked for.
actor FakePhotoFetcher: PhotoFetching {
    private var responses: [Result<[Photo], Error>]
    private(set) var requestedPages: [Int] = []

    init(responses: [Result<[Photo], Error>]) {
        self.responses = responses
    }

    func fetchPhotos(page: Int, limit: Int) async throws -> [Photo] {
        requestedPages.append(page)
        return try responses.removeFirst().get()
    }
}

struct FakeError: Error {}

func makePhotos(_ ids: Range<Int>) -> [Photo] {
    ids.map { id in
        Photo(
            id: String(id),
            author: "Author \(id)",
            width: 300,
            height: 200,
            url: URL(string: "https://example.com/\(id)")!,
            downloadURL: URL(string: "https://example.com/\(id).jpg")!
        )
    }
}

@MainActor
final class FeedViewModelTests: XCTestCase {

    func testFirstPageFillsCarouselThenFeedWithVideos() async {
        let fetcher = FakePhotoFetcher(responses: [.success(makePhotos(0..<30))])
        let viewModel = FeedViewModel(api: fetcher, pageSize: 30)

        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.carouselIDs, (0..<8).map { .photo(String($0)) })
        // 22 photos in the feed, plus a video after every 6th photo: 22 + 3 = 25.
        XCTAssertEqual(viewModel.feedIDs.count, 25)
        XCTAssertEqual(viewModel.feedIDs[5], .photo("13"))
        XCTAssertEqual(viewModel.feedIDs[6], .video(slot: 0))
        XCTAssertEqual(viewModel.loadState, .idle)
        let pages = await fetcher.requestedPages
        XCTAssertEqual(pages, [1])
    }

    func testSecondPageIsAppendedAfterTheFirst() async {
        let fetcher = FakePhotoFetcher(responses: [.success(makePhotos(0..<30)), .success(makePhotos(30..<60))])
        let viewModel = FeedViewModel(api: fetcher, pageSize: 30)

        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.carouselIDs.count, 8)
        XCTAssertEqual(viewModel.feedIDs.first, .photo("8"))
        XCTAssertEqual(viewModel.feedIDs.last, .photo("59"))
        let pages = await fetcher.requestedPages
        XCTAssertEqual(pages, [1, 2])
    }

    func testShortPageMeansThereIsNothingMoreToLoad() async {
        let fetcher = FakePhotoFetcher(responses: [.success(makePhotos(0..<10))])
        let viewModel = FeedViewModel(api: fetcher, pageSize: 30)

        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.loadState, .reachedEnd)
        let pages = await fetcher.requestedPages
        XCTAssertEqual(pages, [1])
    }

    func testFailureWaitsForRetryThenLoadsTheSamePage() async {
        let fetcher = FakePhotoFetcher(responses: [.failure(FakeError()), .success(makePhotos(0..<30))])
        let viewModel = FeedViewModel(api: fetcher, pageSize: 30)

        await viewModel.loadNextPage()
        XCTAssertEqual(viewModel.loadState, .failed)
        XCTAssertTrue(viewModel.feedIDs.isEmpty)

        // Scrolling again must not retry by itself.
        await viewModel.loadNextPage()
        var pages = await fetcher.requestedPages
        XCTAssertEqual(pages, [1])

        await viewModel.retry()
        XCTAssertEqual(viewModel.loadState, .idle)
        XCTAssertEqual(viewModel.carouselIDs.count, 8)
        pages = await fetcher.requestedPages
        XCTAssertEqual(pages, [1, 1])
    }

    func testRefreshReplacesEverythingWithPageOne() async {
        let fetcher = FakePhotoFetcher(responses: [
            .success(makePhotos(0..<30)),
            .success(makePhotos(30..<60)),
            .success(makePhotos(100..<130)),
        ])
        let viewModel = FeedViewModel(api: fetcher, pageSize: 30)

        await viewModel.loadNextPage()
        await viewModel.loadNextPage()
        await viewModel.refresh()

        XCTAssertEqual(viewModel.carouselIDs.first, .photo("100"))
        XCTAssertEqual(viewModel.feedIDs.count, 25)
        XCTAssertNil(viewModel.item(for: .photo("0")))
        let pages = await fetcher.requestedPages
        XCTAssertEqual(pages, [1, 2, 1])
    }
}
