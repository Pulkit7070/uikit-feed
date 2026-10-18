import Foundation

struct Video: Hashable {
    let title: String
    let url: URL
}

extension Video {
    /// Short, freely available sample clips. Every URL was checked to return
    /// a real MP4 before it was added here.
    static let samples: [Video] = [
        Video(title: "Flower", url: URL(string: "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4")!),
        Video(title: "Jellyfish", url: URL(string: "https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4")!),
        Video(title: "Big Buck Bunny", url: URL(string: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4")!),
        Video(title: "Sintel", url: URL(string: "https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4")!),
        Video(title: "Friday", url: URL(string: "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/friday.mp4")!),
    ]
}
