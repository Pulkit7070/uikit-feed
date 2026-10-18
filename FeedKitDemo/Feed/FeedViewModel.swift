import Foundation

/// Holds the feed's state and talks to the network.
/// It knows nothing about UIKit; the view controller reads its properties
/// and redraws whenever `onChange` is called.
@MainActor
final class FeedViewModel {

    enum LoadState: Equatable {
        /// Nothing is loading and more pages may exist.
        case idle
        case loading
        /// The last request failed. Nothing loads again until `retry()`.
        case failed
        /// The server sent back a short page, so there is nothing more to load.
        case reachedEnd
    }

    static let carouselCount = 8

    private(set) var carouselIDs: [FeedItem.ID] = []
    private(set) var feedIDs: [FeedItem.ID] = []
    private(set) var loadState: LoadState = .idle

    var onChange: (() -> Void)?

    private let api: PhotoFetching
    private let pageSize: Int
    private var itemsByID: [FeedItem.ID: FeedItem] = [:]
    private var nextPage = 1

    init(api: PhotoFetching = APIClient(), pageSize: Int = 30) {
        self.api = api
        self.pageSize = pageSize
    }

    func item(for id: FeedItem.ID) -> FeedItem? {
        itemsByID[id]
    }

    /// Safe to call as often as you like: it does nothing unless the state is `.idle`.
    func loadNextPage() async {
        guard loadState == .idle else { return }
        await load(page: nextPage)
    }

    func retry() async {
        guard loadState == .failed else { return }
        loadState = .idle
        await loadNextPage()
    }

    private func load(page: Int) async {
        loadState = .loading
        onChange?()

        do {
            let photos = try await api.fetchPhotos(page: page, limit: pageSize)
            append(photos)
            nextPage = page + 1
            loadState = photos.count < pageSize ? .reachedEnd : .idle
        } catch {
            loadState = .failed
        }
        onChange?()
    }

    private func append(_ photos: [Photo]) {
        for photo in photos {
            let item = FeedItem.photo(photo)
            // The diffable data source crashes on duplicate IDs, so never add one twice.
            guard itemsByID[item.id] == nil else { continue }
            itemsByID[item.id] = item

            if carouselIDs.count < Self.carouselCount {
                carouselIDs.append(item.id)
            } else {
                feedIDs.append(item.id)
            }
        }
    }
}
