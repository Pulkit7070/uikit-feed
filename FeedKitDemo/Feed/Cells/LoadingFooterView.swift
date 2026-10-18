import UIKit

/// Shown under the last card: a spinner while a page loads,
/// or a message and a Retry button when loading failed.
final class LoadingFooterView: UICollectionReusableView {

    var onRetry: (() -> Void)?

    private let spinner = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()
    private let retryButton = UIButton(configuration: .bordered())
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        messageLabel.text = "Couldn't load more photos."
        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.textColor = .secondaryLabel

        retryButton.setTitle("Retry", for: .normal)
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.addArrangedSubview(spinner)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(retryButton)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("This app does not use storyboards")
    }

    func show(_ state: FeedViewModel.LoadState) {
        let failed = state == .failed
        messageLabel.isHidden = !failed
        retryButton.isHidden = !failed

        if state == .loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }
}
