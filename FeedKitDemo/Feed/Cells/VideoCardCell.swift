import AVFoundation
import UIKit

/// A card that plays a short muted video in a loop.
/// The feed decides when it plays; the cell only knows how to play and pause.
final class VideoCardCell: UICollectionViewCell {

    private let playerView = PlayerView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()

    private var player: AVQueuePlayer?
    /// Keeps the video repeating. It stops looping as soon as it is released.
    private var looper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        contentView.backgroundColor = .secondarySystemBackground

        playerView.backgroundColor = .black
        playerView.playerLayer.videoGravity = .resizeAspectFill

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = "Video · muted"

        for subview in [playerView, titleLabel, detailLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }

        let videoHeight = playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9.0 / 16.0)
        videoHeight.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoHeight,

            titleLabel.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("This app does not use storyboards")
    }

    func configure(with video: Video) {
        titleLabel.text = video.title

        let player = AVQueuePlayer()
        player.isMuted = true
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: video.url))
        playerView.player = player
        self.player = player
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pause()
        looper = nil
        player = nil
        playerView.player = nil
    }
}

/// A view whose own layer is an AVPlayerLayer, so the video always
/// matches the view's size without any manual frame updates.
final class PlayerView: UIView {

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
}
