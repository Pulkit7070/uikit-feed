import UIKit

final class FeedViewController: UIViewController {

    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover"
        view.backgroundColor = .systemBackground

        let layout = FeedLayout.make { index in
            index == 0 ? .carousel : .feed
        }
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
    }
}
