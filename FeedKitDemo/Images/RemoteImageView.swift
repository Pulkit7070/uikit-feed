import UIKit

/// A UIImageView that can load its image from a URL and cancel that load.
final class RemoteImageView: UIImageView {

    private var loadTask: Task<Void, Never>?

    func setImage(from url: URL, pointSize: CGSize) {
        cancelLoad()
        // A zero size would ask ImageIO for a full-size decode, which is what we are avoiding.
        let pointSize = pointSize.width > 0 && pointSize.height > 0 ? pointSize : CGSize(width: 400, height: 400)

        let scale = traitCollection.displayScale
        if let cached = ImageLoader.shared.cachedImage(for: url, pointSize: pointSize, scale: scale) {
            image = cached
            return
        }

        image = nil
        // This Task runs on the main actor, because UIView code always does.
        // The `await` hands the slow work to ImageLoader and comes back here when it is done.
        loadTask = Task { [weak self] in
            let loaded = try? await ImageLoader.shared.image(for: url, pointSize: pointSize, scale: scale)
            // If cancelLoad() ran while we were waiting, this view now belongs to
            // a different item. Showing `loaded` would put the wrong photo on screen.
            guard !Task.isCancelled else { return }
            self?.image = loaded
        }
    }

    func cancelLoad() {
        loadTask?.cancel()
        loadTask = nil
        image = nil
    }
}
