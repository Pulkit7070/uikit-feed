import Foundation

/// Holds the feed's state and talks to the network.
/// It knows nothing about UIKit; the view controller reads its properties
/// and redraws whenever `onChange` is called.
@MainActor
final class FeedViewModel {

    static let carouselCount = 8

    private(set) var carouselIDs: [FeedItem.ID] = []
    private(set) var feedIDs: [FeedItem.ID] = []

    var onChange: (() -> Void)?

    private let api: PhotoFetching
    private let pageSize: Int
    private var itemsByID: [FeedItem.ID: FeedItem] = [:]

    init(api: PhotoFetching = APIClient(), pageSize: Int = 30) {
        self.api = api
        self.pageSize = pageSize
    }

    func item(for id: FeedItem.ID) -> FeedItem? {
        itemsByID[id]
    }

    func loadFirstPage() async {
        do {
            let photos = try await api.fetchPhotos(page: 1, limit: pageSize)
            append(photos)
        } catch {
            print("Failed to load the feed: \(error)")
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
                continue
            }

            feedIDs.append(item.id)
        }
    }
}
