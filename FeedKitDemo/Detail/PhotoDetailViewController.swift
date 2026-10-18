import UIKit

/// The screen pushed when a photo is tapped: the full-width photo and its details.
final class PhotoDetailViewController: UIViewController {

    private let photo: Photo
    private let imageView = RemoteImageView()
    private var didStartLoadingImage = false

    init(photo: Photo) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("This app does not use storyboards")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = photo.author
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true

        let authorLabel = UILabel()
        authorLabel.text = photo.author
        authorLabel.font = .preferredFont(forTextStyle: .title2)
        authorLabel.numberOfLines = 0

        let sizeLabel = UILabel()
        sizeLabel.text = "Original size: \(photo.width) × \(photo.height) pixels"
        sizeLabel.font = .preferredFont(forTextStyle: .body)
        sizeLabel.textColor = .secondaryLabel
        sizeLabel.numberOfLines = 0

        let sourceButton = UIButton(configuration: .filled())
        sourceButton.setTitle("View on Unsplash", for: .normal)
        sourceButton.addAction(UIAction { [weak self] _ in self?.openSource() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [imageView, authorLabel, sizeLabel, sourceButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(20, after: imageView)
        stack.setCustomSpacing(24, after: sizeLabel)

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: frame.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: frame.trailingAnchor, constant: -16),

            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: photo.aspectRatio),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Wait until Auto Layout has given the image view its real size,
        // then load the photo at exactly that size, once.
        guard !didStartLoadingImage, imageView.bounds.width > 0 else { return }
        didStartLoadingImage = true
        imageView.setImage(from: photo.resizedURL(width: 1200), pointSize: imageView.bounds.size)
    }

    private func openSource() {
        UIApplication.shared.open(photo.url)
    }
}
