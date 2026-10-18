import Foundation

/// One image from the Picsum list endpoint.
/// The property names match the JSON keys, except `downloadURL`.
struct Photo: Codable, Hashable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: URL
    let downloadURL: URL

    enum CodingKeys: String, CodingKey {
        case id, author, width, height, url
        case downloadURL = "download_url"
    }

    /// Picsum can resize on the server. Asking for a smaller file saves
    /// bandwidth; we still downsample on the device to fit the exact view size.
    func resizedURL(width: Int) -> URL {
        let height = Int(Double(width) * aspectRatio)
        return URL(string: "https://picsum.photos/id/\(id)/\(width)/\(height)")!
    }

    /// Height divided by width, used to size cards before the image arrives.
    var aspectRatio: Double {
        guard width > 0 else { return 1 }
        return Double(height) / Double(width)
    }
}
