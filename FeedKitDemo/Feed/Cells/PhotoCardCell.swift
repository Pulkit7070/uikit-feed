import UIKit

/// A card in the vertical list: the photo, then the author and size below it.
final class PhotoCardCell: UICollectionViewCell {

    private let imageView = RemoteImageView()
    private let authorLabel = UILabel()
    private let detailLabel = UILabel()
    private var aspectRatioConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        contentView.backgroundColor = .secondarySystemBackground

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .tertiarySystemFill

        authorLabel.font = .preferredFont(forTextStyle: .headline)
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textColor = .secondaryLabel

        for subview in [imageView, authorLabel, detailLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            authorLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),

            detailLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 2),
            detailLabel.leadingAnchor.constraint(equalTo: authorLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: authorLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("This app does not use storyboards")
    }

    func configure(with photo: Photo) {
        authorLabel.text = photo.author
        detailLabel.text = "Photo · \(photo.width) × \(photo.height)"

        // Give the image view the photo's shape so the card has the right
        // height before the image has even downloaded.
        aspectRatioConstraint?.isActive = false
        aspectRatioConstraint = imageView.heightAnchor.constraint(
            equalTo: imageView.widthAnchor,
            multiplier: photo.aspectRatio
        )
        // 999 instead of 1000 avoids a harmless conflict while the
        // collection view is still estimating the card's height.
        aspectRatioConstraint?.priority = UILayoutPriority(999)
        aspectRatioConstraint?.isActive = true

        let width = bounds.width
        let pointSize = CGSize(width: width, height: width * photo.aspectRatio)
        imageView.setImage(from: photo.resizedURL(width: 800), pointSize: pointSize)
    }

    // A cell that scrolls off screen is reused for a different item.
    // Stop the old download so it cannot finish later and show the old photo.
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelLoad()
    }
}
