import UIKit

final class FeedViewController: UIViewController {

    private let viewModel: FeedViewModel
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<FeedSection, FeedItem.ID>!

    init(viewModel: FeedViewModel = FeedViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("This app does not use storyboards")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover"
        view.backgroundColor = .systemBackground

        configureCollectionView()
        configureDataSource()

        viewModel.onChange = { [weak self] in
            self?.applySnapshot()
            self?.updateFooter()
        }
        applySnapshot()

        loadNextPage()
    }

    private func loadNextPage() {
        Task {
            await viewModel.loadNextPage()
        }
    }

    private func configureCollectionView() {
        // The layout asks the data source which section lives at each index.
        let layout = FeedLayout.make { [weak self] index in
            self?.dataSource?.sectionIdentifier(for: index)
        }
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        let carouselRegistration = UICollectionView.CellRegistration<CarouselCell, Photo> { cell, _, photo in
            cell.configure(with: photo)
        }
        let photoRegistration = UICollectionView.CellRegistration<PhotoCardCell, Photo> { cell, _, photo in
            cell.configure(with: photo)
        }

        // Capture the view model, not `self`, so the data source does not keep the view controller alive.
        let viewModel = viewModel
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, id in
            guard let item = viewModel.item(for: id) else {
                fatalError("The snapshot contains an ID the view model does not know about")
            }
            // Section 0 is always the carousel, because applySnapshot() appends it first.
            let isCarousel = indexPath.section == 0

            switch item {
            case .photo(let photo) where isCarousel:
                return collectionView.dequeueConfiguredReusableCell(using: carouselRegistration, for: indexPath, item: photo)
            case .photo(let photo):
                return collectionView.dequeueConfiguredReusableCell(using: photoRegistration, for: indexPath, item: photo)
            case .video:
                preconditionFailure("The view model does not create video items yet")
            }
        }

        let footerRegistration = UICollectionView.SupplementaryRegistration<LoadingFooterView>(
            elementKind: FeedLayout.footerKind
        ) { footer, _, _ in
            footer.show(viewModel.loadState)
            footer.onRetry = {
                Task { await viewModel.retry() }
            }
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
        }
    }

    /// The footer is not part of the snapshot, so a new snapshot does not
    /// redraw it. Instead we find it on screen, if it is there, and update it.
    private func updateFooter() {
        let feedSection = dataSource.snapshot().indexOfSection(.feed) ?? 1
        let footer = collectionView.supplementaryView(
            forElementKind: FeedLayout.footerKind,
            at: IndexPath(item: 0, section: feedSection)
        ) as? LoadingFooterView
        footer?.show(viewModel.loadState)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<FeedSection, FeedItem.ID>()
        snapshot.appendSections([.carousel, .feed])
        snapshot.appendItems(viewModel.carouselIDs, toSection: .carousel)
        snapshot.appendItems(viewModel.feedIDs, toSection: .feed)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension FeedViewController: UICollectionViewDelegate {

    /// Start loading the next page a few cards before the user reaches the end,
    /// so new cards are usually ready before they are needed.
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let isFeed = dataSource.sectionIdentifier(for: indexPath.section) == .feed
        let isNearEnd = indexPath.item >= viewModel.feedIDs.count - 5
        if isFeed && isNearEnd {
            loadNextPage()
        }
    }
}
