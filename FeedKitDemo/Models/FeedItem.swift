import Foundation

/// Everything that can appear in the feed.
///
/// The diffable data source does not store `FeedItem` values. It stores
/// only their `ID`s. An ID never changes for the life of an item, so UIKit
/// can tell which rows were inserted, removed, or moved between snapshots.
enum FeedItem {
    case photo(Photo)
    case video(Video, slot: Int)

    enum ID: Hashable {
        case photo(String)
        /// `slot` is the position of the video in the feed. The same sample
        /// clip appears many times, so its URL alone is not a unique ID.
        case video(slot: Int)
    }

    var id: ID {
        switch self {
        case .photo(let photo): .photo(photo.id)
        case .video(_, let slot): .video(slot: slot)
        }
    }
}
