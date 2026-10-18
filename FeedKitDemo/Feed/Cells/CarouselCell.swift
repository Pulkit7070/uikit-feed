import UIKit

/// A large photo with the author's name on top, used in the top carousel.
final class CarouselCell: UICollectionViewCell {

    private let imageView = UIImageView()
    private let authorLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        contentView.backgroundColor = .secondarySystemBackground

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        let labelBackground = UIView()
        labelBackground.backgroundColor = UIColor.black.withAlphaComponent(0.45)

        authorLabel.font = .preferredFont(forTextStyle: .headline)
        authorLabel.textColor = .white

        for subview in [imageView, labelBackground, authorLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            labelBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            labelBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            labelBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            labelBackground.topAnchor.constraint(equalTo: authorLabel.topAnchor, constant: -10),

            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            authorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("This app does not use storyboards")
    }

    func configure(with photo: Photo) {
        authorLabel.text = photo.author
    }
}
