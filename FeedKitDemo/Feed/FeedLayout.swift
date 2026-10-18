import UIKit

enum FeedSection: Hashable {
    /// Horizontally scrolling row of featured photos at the top.
    case carousel
    /// The main vertical list of photo and video cards.
    case feed
}

enum FeedLayout {

    static let footerKind = UICollectionView.elementKindSectionFooter

    /// Builds one layout object that can describe both sections.
    /// `sectionForIndex` tells the layout which kind of section sits at each index.
    static func make(sectionForIndex: @escaping (Int) -> FeedSection?) -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch sectionForIndex(sectionIndex) {
            case .carousel: carouselSection()
            case .feed, nil: feedSection()
            }
        }
        return layout
    }

    private static func carouselSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        )

        // Each group holds one item and is 80% of the screen wide,
        // so the next card peeks in from the right.
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(220)),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        // This one line is what turns a vertical section into a horizontal carousel.
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 0)
        return section
    }

    private static func feedSection() -> NSCollectionLayoutSection {
        // `.estimated` lets each card size itself from its Auto Layout constraints.
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300))
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)

        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64)),
            elementKind: footerKind,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [footer]
        return section
    }
}
